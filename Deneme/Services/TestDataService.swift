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
    
    func deleteTestData(for walletId: String) async throws {
        let transactionsRef = db.collection("wallets").document(walletId).collection("transactions")
        let snapshot = try await transactionsRef.whereField("isTest", isEqualTo: true).getDocuments()
        
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        
        try await batch.commit()
    }
}
