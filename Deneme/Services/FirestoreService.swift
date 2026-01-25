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
    func createWallet(name: String, type: WalletType, context: WalletContext, performAsUser uid: String) async throws {
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
            }
    }
    
    func stopListeningWallets() {
        walletsListener?.remove()
        walletsListener = nil
        wallets = []
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
            
            // 2. Add member to wallet
            try await addMember(walletId: invite.walletId, userId: invite.toUserId, role: invite.role)
        } else {
            // Update status to rejected
            try await inviteRef.updateData(["status": InviteStatus.rejected.rawValue])
        }
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
