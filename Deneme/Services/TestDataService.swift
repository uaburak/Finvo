import Foundation
import FirebaseFirestore
import FirebaseAuth

class TestDataService {
    static let shared = TestDataService()
    private let db = Firestore.firestore()
    
    func generateTestData(for walletId: String) async throws {
        // Use real categories from Manager to ensure they have icons/colors
        let availableCategories = CategoryManager.shared.categories
        
        let batch = db.batch()
        let transactionsRef = db.collection("wallets").document(walletId).collection("transactions")
        
        // Generate 100 transactions over last 3 months
        let calendar = Calendar.current
        let today = Date()
        
        for _ in 0..<100 {
            let randomDayOffset = Int.random(in: 0...90)
            let date = calendar.date(byAdding: .day, value: -randomDayOffset, to: today) ?? today
            
            // 70% Expense, 30% Income
            let isExpense = Int.random(in: 1...10) <= 7
            let type: TransactionType = isExpense ? .expense : .income
            
            // Pick a random category matching the type if possible, else random
            let filteredCats = availableCategories.filter { $0.type == (isExpense ? .expense : .income) }
            let randomCat = filteredCats.randomElement() ?? availableCategories.randomElement() 
            
            let amount = isExpense ? Double.random(in: 20...3000) : Double.random(in: 15000...50000)
            
            let notes = ["Market", "Otobüs", "Sinema bileti", "Elektrik", "Kira ödemesi", "Eczane", "Ayakkabı", "Udemy kurs", "Otel", "Spor salonu", "Kulaklık", "Akşam yemeği", "Kahve", "Depo fulleme"]
            let randomNote = notes.randomElement() ?? "İşlem"
            
            let newDocRef = transactionsRef.document()
            
            let transactionData: [String: Any] = [
                "id": newDocRef.documentID,
                "amount": amount,
                "type": type.rawValue,
                "categoryName": randomCat?.name ?? "Diğer",
                "subCategoryName": "",
                "date": Timestamp(date: date),
                "note": randomNote,
                "createdBy": AuthenticationManager.shared.user?.uid ?? "testUser",
                "createdByUsername": AuthenticationManager.shared.currentUserProfile?.username ?? "Test User",
                "createdAt": FieldValue.serverTimestamp(),
                "currency": "TRY",
                "isRecurring": false,
                "isTest": true // Flag for safe deletion
            ]
            
            batch.setData(transactionData, forDocument: newDocRef)
        }
        
        try await batch.commit()
    }
    
    // Optimized for heavy load (e.g., 1000 items)
    func generateMassiveData(for walletId: String, count: Int = 1000) async throws {
        let availableCategories = CategoryManager.shared.categories
        let transactionsRef = db.collection("wallets").document(walletId).collection("transactions")
        let calendar = Calendar.current
        let today = Date()
        
        // Firestore batch limit is 500
        let batchSize = 400
        var processed = 0
        
        while processed < count {
            let currentBatch = db.batch()
            let limit = min(batchSize, count - processed)
            
            for _ in 0..<limit {
                let randomDayOffset = Int.random(in: 0...365) // Spread over a year
                let date = calendar.date(byAdding: .day, value: -randomDayOffset, to: today) ?? today
                
                let isExpense = Bool.random()
                let type: TransactionType = isExpense ? .expense : .income
                let filteredCats = availableCategories.filter { $0.type.rawValue == type.rawValue }
                let randomCat = filteredCats.randomElement() ?? availableCategories.randomElement()
                
                let amount = Double.random(in: 10...5000)
                let newDocRef = transactionsRef.document()
                
                let transactionData: [String: Any] = [
                    "id": newDocRef.documentID,
                    "amount": amount,
                    "type": type.rawValue,
                    "categoryName": randomCat?.name ?? "StressTest",
                    "subCategoryName": "",
                    "date": Timestamp(date: date),
                    "note": "LOAD TEST DATA (#\(Int.random(in: 1000...9999)))",
                    "createdBy": AuthenticationManager.shared.user?.uid ?? "testUser",
                    "createdByUsername": "LoadTester",
                    "createdAt": FieldValue.serverTimestamp(),
                    "currency": "TRY",
                    "isRecurring": false,
                    "isTest": true
                ]
                
                currentBatch.setData(transactionData, forDocument: newDocRef)
            }
            
            try await currentBatch.commit()
            processed += limit
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms cooling to prevent flooding
        }
    }
    
    func deleteTestData(for walletId: String) async throws {
        let transactionsRef = db.collection("wallets").document(walletId).collection("transactions")
        let snapshot = try await transactionsRef.whereField("isTest", isEqualTo: true).getDocuments()
        
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        
        try await batch.commit()
    }
    // MARK: - Destructive Cleanup
    
    /// Deletes ALL transactions in the given wallet (Real & Test data)
    func deleteAllTransactions(walletId: String) async throws {
        let transactionsRef = db.collection("wallets").document(walletId).collection("transactions")
        
        // Simple loop batch deletion (Firestore handles max 500 per batch)
        // For large datasets, this might need recursion, but sufficient for test environment
        let snapshot = try await transactionsRef.limit(to: 500).getDocuments()
        
        guard !snapshot.isEmpty else { return }
        
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
        
        // Check if more exist (Recursion for full clean)
        if snapshot.count == 500 {
            try await deleteAllTransactions(walletId: walletId)
        }
    }
    
    /// Deletes all wallets owned by the user and all their invites
    func resetWalletsAndInvites(userId: String) async throws {
        // 1. Delete Owned Wallets
        let walletsSnap = try await db.collection("wallets").whereField("ownerId", isEqualTo: userId).getDocuments()
        for doc in walletsSnap.documents {
            try await FirestoreService.shared.deleteWallet(walletId: doc.documentID)
        }
        
        // 2. Delete Invites (Sent to user OR Sent by user)
        // Sent TO user
        let invitesToSnap = try await db.collection("invites").whereField("toUserId", isEqualTo: userId).getDocuments()
        for doc in invitesToSnap.documents {
            try await doc.reference.delete()
        }
        
        // Sent BY user
        let invitesFromSnap = try await db.collection("invites").whereField("fromUserId", isEqualTo: userId).getDocuments()
        for doc in invitesFromSnap.documents {
            try await doc.reference.delete()
        }
    }
    
    /// Nukes all data related to the user (Wallets, Transactions, Invites, etc.)
    func nukeUserData(userId: String) async throws {
        // 1. Reset Wallets (which deletes transactions inside them)
        try await resetWalletsAndInvites(userId: userId)
        
        // 2. Leave joined wallets
        let joinedWalletsSnap = try await db.collection("wallets").whereField("members", arrayContains: userId).getDocuments()
        for doc in joinedWalletsSnap.documents {
            // Only leave if not owner (Owner ones are already deleted above, but double check)
            let wallet = try? doc.data(as: Wallet.self)
            if let w = wallet, w.ownerId != userId {
                try await FirestoreService.shared.leaveWallet(walletId: w.id!, userId: userId)
            }
        }
        
        // 3. Clear Notifications
        let notifsSnap = try await db.collection("notifications").whereField("userId", isEqualTo: userId).getDocuments()
        let batch = db.batch()
        for doc in notifsSnap.documents {
             batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
}
