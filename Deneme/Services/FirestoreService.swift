import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    // Published property to be observed by ViewModels if needed directly, 
    // though we might prefer returning publishers.
    @Published var wallets: [Wallet] = []
    
    private var walletsListener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Wallet Operations
    
    /// Create a new wallet
    func createWallet(name: String, type: WalletType, context: WalletContext, performAsUser uid: String) async throws -> Wallet {
        let newWalletRef = db.collection("wallets").document()
        
        let wallet = Wallet(
            id: newWalletRef.documentID,
            name: name,
            ownerId: uid,
            type: type,
            context: context,
            members: [uid],
            permissions: [uid: "owner"]
        )
        
        try newWalletRef.setData(from: wallet)
        
        // Optimistic Update
        DispatchQueue.main.async {
            self.wallets.append(wallet)
        }
        
        return wallet
    }
    
    /// Listen for wallets where the user is a member
    func  startListeningWallets(forUser uid: String) {
        // Remove existing listener if any
        stopListeningWallets()
        
        // Query: wallets where 'members' array contains uid
        // Note: 'array-contains' requires an index potentially.
        walletsListener = db.collection("wallets")
            .whereField("members", arrayContains: uid)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for wallets: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.wallets = []
                    return
                }
                
                self.wallets = documents.compactMap { document in
                    try? document.data(as: Wallet.self)
                }
                self.wallets = documents.compactMap { document in
                    try? document.data(as: Wallet.self)
                }
            }
    }
    
    func getWallet(id: String) async throws -> Wallet {
        let doc = try await db.collection("wallets").document(id).getDocument()
        return try doc.data(as: Wallet.self)
    }
    
    func stopListeningWallets() {
        walletsListener?.remove()
        walletsListener = nil
        wallets = []
    }
    
    func deleteWallet(walletId: String) async throws {
        // Optimistic Update: Remove locally first
        DispatchQueue.main.async {
            self.wallets.removeAll { $0.id == walletId }
        }
        
        // 1. Delete transactions (In a real app, use Cloud Functions or batch delete)
        // For MVP, we might leave them orphaned or try to delete a batch.
        // Let's just delete the wallet document for now.
        try await db.collection("wallets").document(walletId).delete()
    }
    
    func leaveWallet(walletId: String, userId: String) async throws {
        // Optimistic Update: Remove locally first
        DispatchQueue.main.async {
            self.wallets.removeAll { $0.id == walletId }
        }
        
        // Remove user from members array and permissions map
        try await removeMember(walletId: walletId, userId: userId)
    }
    
    // MARK: - Transaction Operations
    
    func addTransaction(walletId: String, transaction: Transaction) async throws {
        let walletRef = db.collection("wallets").document(walletId)
        let transactionsRef = walletRef.collection("transactions")
        
        try transactionsRef.addDocument(from: transaction)
    }
    
    // Real-time Transaction Listener
    func listenToTransactions(walletId: String, limit: Int = 50, completion: @escaping ([Transaction]) -> Void) -> ListenerRegistration {
        let walletRef = db.collection("wallets").document(walletId)
        
        // Listen to the last 50 transactions regardless of type
        // This allows client-side filtering without missing data
        let query = walletRef.collection("transactions")
            .order(by: "date", descending: true)
            .limit(to: limit)
            
        return query.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error listening to transactions: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let transactions = documents.compactMap { try? $0.data(as: Transaction.self) }
            completion(transactions)
        }
    }
    
    func deleteTransaction(walletId: String, transactionId: String) async throws {
        let walletRef = db.collection("wallets").document(walletId)
        let transactionRef = walletRef.collection("transactions").document(transactionId)
        try await transactionRef.delete()
    }
    
    func updateTransaction(walletId: String, transaction: Transaction) async throws {
        guard let transactionId = transaction.id else { return }
        let walletRef = db.collection("wallets").document(walletId)
        let transactionRef = walletRef.collection("transactions").document(transactionId)
        try transactionRef.setData(from: transaction, merge: true)
    }
    
    // Legacy fetch (kept for reference or specific use cases)
    func fetchTransactions(walletId: String, limit: Int = 20, lastDoc: DocumentSnapshot? = nil, type: TransactionType? = nil) async throws -> (transactions: [Transaction], lastDoc: DocumentSnapshot?) {
        let walletRef = db.collection("wallets").document(walletId)
        var query: Query = walletRef.collection("transactions")
        
        // 1. Filter first (optimization suggestion)
        if let type = type {
            query = query.whereField("type", isEqualTo: type.rawValue)
        }
        
        // 2. Then Sort & Limit
        query = query.order(by: "date", descending: true)
            .limit(to: limit)

        
        if let lastDoc = lastDoc {
            query = query.start(afterDocument: lastDoc)
        }
        
        let snapshot = try await query.getDocuments()
        let transactions = snapshot.documents.compactMap { try? $0.data(as: Transaction.self) }
        return (transactions, snapshot.documents.last)
    }
    
    // Simple statistics fetch (Client-side calculation for now as aggregation queries might be complex/costly without specific design)
    // For a real production app with massive data, use Firestore Aggregation Queries or Cloud Functions.
    func fetchTransactionStats(walletId: String, from date: Date) async throws -> (income: Double, expense: Double) {
        let walletRef = db.collection("wallets").document(walletId)
        let snapshot = try await walletRef.collection("transactions")
            .whereField("date", isGreaterThanOrEqualTo: date)
            .getDocuments()
        
        var income: Double = 0
        var expense: Double = 0
        
        for doc in snapshot.documents {
            guard let transaction = try? doc.data(as: Transaction.self) else { continue }
            if transaction.type == .income {
                income += transaction.amount
            } else {
                expense += transaction.amount
            }
        }
        
        return (income, expense)
    }
    
    // Fetch ALL transactions for export/analytics (Be careful with cost)
    func fetchAllTransactions(walletId: String) async throws -> [Transaction] {
        let walletRef = db.collection("wallets").document(walletId)
        let snapshot = try await walletRef.collection("transactions")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Transaction.self) }
    }
    
    // MARK: - User & Member Management
    
    func findUser(byUsername username: String) async throws -> User? {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: User.self)
    }
    
    func fetchUsers(uids: [String]) async throws -> [User] {
        guard !uids.isEmpty else { return [] }
        // Firestore 'in' query supports up to 30 items. 
        // We will slice if needed or assume <30 for this MVP.
        let chunks = stride(from: 0, to: uids.count, by: 10).map {
            Array(uids[$0..<min($0 + 10, uids.count)])
        }
        
        var users: [User] = []
        for chunk in chunks {
            let snapshot = try await db.collection("users")
                .whereField("uid", in: chunk)
                .getDocuments()
            let chunkUsers = snapshot.documents.compactMap { try? $0.data(as: User.self) }
            users.append(contentsOf: chunkUsers)
        }
        return users
    }
    
    func addMember(walletId: String, userId: String, role: String) async throws {
        let walletRef = db.collection("wallets").document(walletId)
        
        // Atomically add to members array and update permissions map
        try await walletRef.updateData([
            "members": FieldValue.arrayUnion([userId]),
            "permissions.\(userId)": role
        ])
    }
    
    func removeMember(walletId: String, userId: String) async throws {
        let walletRef = db.collection("wallets").document(walletId)
        
        // Remove from members array and delete from permissions map
        try await walletRef.updateData([
            "members": FieldValue.arrayRemove([userId]),
            "permissions.\(userId)": FieldValue.delete()
        ])
    }
    

    func updateMemberRole(walletId: String, userId: String, newRole: String) async throws {
        let walletRef = db.collection("wallets").document(walletId)
        try await walletRef.updateData([
            "permissions.\(userId)": newRole
        ])
    }
    
    // MARK: - Invitations
    
    func sendInvite(walletId: String, walletName: String, toUser: User, fromUser: User, role: String) async throws {
        // Create invite document
        let inviteData = Invite(
            fromUserId: fromUser.uid,
            fromUsername: fromUser.username,
            toUserId: toUser.uid,
            toUsername: toUser.username,
            walletId: walletId,
            walletName: walletName,
            role: role,
            status: .pending,
            createdAt: Date()
        )
        
        try db.collection("invites").addDocument(from: inviteData)
        
        // Pre-add member as "pending" so they can update themselves later
        // "pending" role should block them from viewing details if we enforce it in Rules,
        // or just block editing in UI.
        try await addMember(walletId: walletId, userId: toUser.uid, role: "pending")
    }
    
    func fetchPendingInvites(forUser userId: String) async throws -> [Invite] {
        let snapshot = try await db.collection("invites")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Invite.self) }
    }
    
    func respondToInvite(_ invite: Invite, accept: Bool) async throws {
        guard let inviteId = invite.id else { return }
        let inviteRef = db.collection("invites").document(inviteId)
        
        if accept {
            // 1. Update invite status
            try await inviteRef.updateData(["status": InviteStatus.accepted.rawValue])
            
            // 2. Upgrade member role from "pending" to "editor" (or whatever invite role was)
            // Note: User is already in 'members' array from sendInvite step.
            try await updateMemberRole(walletId: invite.walletId, userId: invite.toUserId, newRole: "editor")
            
            // 3. Fetch the now-accessible wallet and add to local list (Optimistic-ish)
            // Since rules now allow reading, this fetch should succeed.
            if let acceptedWallet = try? await getWallet(id: invite.walletId) {
                DispatchQueue.main.async {
                    if !self.wallets.contains(where: { $0.id == acceptedWallet.id }) {
                        self.wallets.append(acceptedWallet)
                    }
                }
            }
        } else {
            // Update status to rejected
            try await inviteRef.updateData(["status": InviteStatus.rejected.rawValue])
            
            // If rejected, REMOVE them from pending members
            try await removeMember(walletId: invite.walletId, userId: invite.toUserId)
            
            // Send notification to the inviter
            // We need to fetch the invite details (which we have) to know who sent it
            try? await sendNotification(
                toUserId: invite.fromUserId,
                title: "Davet Reddedildi",
                message: "\(invite.toUsername) cüzdan davetinizi reddetti.",
                type: .rejection,
                relatedId: invite.walletId
            )
        }
    }
    
    // MARK: - Permission Requests
    
    func sendPermissionRequest(wallet: Wallet, fromUser: User) async throws {
        guard let walletId = wallet.id else { return }
        
        // Create request
        let request = PermissionRequest(
            fromUserId: fromUser.uid,
            fromUsername: fromUser.username,
            toOwnerId: wallet.ownerId,
            walletId: walletId,
            walletName: wallet.name,
            status: .pending,
            createdAt: Date()
        )
        
        try db.collection("permission_requests").addDocument(from: request)
    }
    
    func fetchPermissionRequests(forOwner ownerId: String) async throws -> [PermissionRequest] {
        print("DEBUG: Fetching requests for owner: \(ownerId)")
        let snapshot = try await db.collection("permission_requests")
            .whereField("toOwnerId", isEqualTo: ownerId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
            
        print("DEBUG: Found \(snapshot.documents.count) requests")
        return snapshot.documents.compactMap { try? $0.data(as: PermissionRequest.self) }
    }
    
    func respondToPermissionRequest(_ request: PermissionRequest, accept: Bool) async throws {
        guard let requestId = request.id else { return }
        let requestRef = db.collection("permission_requests").document(requestId)
        
        if accept {
            try await requestRef.updateData(["status": PermissionRequestStatus.accepted.rawValue])
            // Update role to editor
            try await updateMemberRole(walletId: request.walletId, userId: request.fromUserId, newRole: "editor")
        } else {
            try await requestRef.updateData(["status": PermissionRequestStatus.rejected.rawValue])
        }
    }
    // MARK: - Notifications (Generic)
    
    func sendNotification(toUserId: String, title: String, message: String, type: NotificationType, relatedId: String? = nil) async throws {
        let notification = AppNotification(
            userId: toUserId,
            title: title,
            message: message,
            type: type,
            relatedId: relatedId,
            isRead: false,
            createdAt: Date()
        )
        try db.collection("notifications").addDocument(from: notification)
    }
    
    func fetchNotifications(forUser userId: String) async throws -> [AppNotification] {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()
            
        return snapshot.documents.compactMap { try? $0.data(as: AppNotification.self) }
    }
    
    func markNotificationRead(_ notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData(["isRead": true])
    }
    
    // MARK: - Data Repair (Temporary)
    func repairTransactions() async throws -> String {
        var log = "Onarım Başlatıldı...\n"
        var updatedCount = 0
        
        // 1. Get all wallets
        let walletsSnap = try await db.collection("wallets").getDocuments()
        log += "Bulunan Cüzdan Sayısı: \(walletsSnap.documents.count)\n"
        
        for walletDoc in walletsSnap.documents {
            let walletId = walletDoc.documentID
            let walletRef = db.collection("wallets").document(walletId)
            let transactionsSnap = try await walletRef.collection("transactions").getDocuments()
            
            for doc in transactionsSnap.documents {
                var updates: [String: Any] = [:]
                let data = doc.data()
                
                // Fix Type (Lowercase)
                if let typeString = data["type"] as? String {
                    let lowered = typeString.lowercased()
                    if typeString != lowered {
                        updates["type"] = lowered
                        log += "Düzeltildi (Type): \(doc.documentID) -> \(lowered)\n"
                    }
                }
                
                // Backfill Username
                if data["createdByUsername"] == nil {
                    if let uid = data["createdBy"] as? String {
                        // Fetch user info (One by one is slow but acceptable for repair tool)
                        let userDoc = try await db.collection("users").document(uid).getDocument()
                        if let userData = userDoc.data(), let username = userData["username"] as? String {
                            updates["createdByUsername"] = username
                            log += "Eklendi (Username): \(doc.documentID) -> \(username)\n"
                        }
                    }
                }
                
                if !updates.isEmpty {
                    try await doc.reference.updateData(updates)
                    updatedCount += 1
                }
            }
        }
        
        log += "Tamamlandı. Toplam Güncellenen İşlem: \(updatedCount)"
        return log
    }
}
