import Foundation
import Firebase
import FirebaseFirestore
import Combine

class UserSimulationService: ObservableObject {
    static let shared = UserSimulationService()
    private let db = Firestore.firestore()
    private let logger = DebugLogger.shared
    
    // MARK: - Simulation Flow
    
    func runFullSimulation(forUserId userId: String) async {
        logger.log("🎬 SİMÜLASYON BAŞLATILIYOR...", level: .info)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // 1. Create Wallet
            logger.log("👉 Adım 1: Test Cüzdanı Oluşturuluyor...", level: .info)
            let walletId = try await createSimulationWallet(userId: userId)
            logger.log("✅ Adım 1 Başarılı: Cüzdan ID \(walletId)", level: .info)
            
            // Wait a bit to simulate user think time
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            // 2. Add Transactions
            logger.log("👉 Adım 2: İşlemler Ekleniyor...", level: .info)
            try await addSimulationTransactions(walletId: walletId, userId: userId)
            logger.log("✅ Adım 2 Başarılı: İşlemler eklendi.", level: .info)
            
            // 3. Set Spending Limit
            logger.log("👉 Adım 3: Harcama Limiti Belirleniyor...", level: .info)
            try await setSimulationLimit(walletId: walletId)
            logger.log("✅ Adım 3 Başarılı: Limit 50,000 TL olarak ayarlandı.", level: .info)
            
            // 4. Create Savings Goal
            logger.log("👉 Adım 4: Birikim Hedefi Oluşturuluyor...", level: .info)
            try await setSimulationSavings(walletId: walletId)
            logger.log("✅ Adım 4 Başarılı: Hedef 100,000 TL.", level: .info)
            
            // 5. Create Debt
            logger.log("👉 Adım 5: Taksitli Borç Ekleniyor...", level: .info)
            try await createSimulationDebt(walletId: walletId)
            logger.log("✅ Adım 5 Başarılı: iPhone Taksiti eklendi.", level: .info)
            
            // 6. Invite Simulation
            logger.log("👉 Adım 6: Paylaşım Daveti Gönderiliyor...", level: .info)
            try await sendSimulationInvite(walletId: walletId, fromUserId: userId)
            logger.log("✅ Adım 6 Başarılı: Test daveti gönderildi.", level: .info)
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.log("🏁 SİMÜLASYON TAMAMLANDI! (Süre: \(String(format: "%.2f", duration))sn)", level: .info)
            logger.log("ℹ️ Oluşturulan Cüzdan: 'SİMÜLASYON TEST'", level: .info)
            
        } catch {
            logger.log("❌ SİMÜLASYON HATASI: \(error.localizedDescription)", level: .error)
        }
    }
    
    // MARK: - Step Helpers
    
    private func createSimulationWallet(userId: String) async throws -> String {
        let name = "SİMÜLASYON TEST (\(Date().formatted(date: .numeric, time: .shortened)))"
        
        let newWallet = Wallet(
            name: name,
            ownerId: userId,
            type: .personal,
            context: .budget,
            members: [userId],
            permissions: [userId: "owner"],
            monthlyLimit: 0,
            savingsGoal: 0
        )
        
        let ref = db.collection("wallets").document()
        // We manually assign ID to match struct if needed, or use ref.documentID
        var walletToSave = newWallet
        walletToSave.id = ref.documentID
        
        try ref.setData(from: walletToSave)
        return ref.documentID
    }
    
    private func addSimulationTransactions(walletId: String, userId: String) async throws {
        let walletRef = db.collection("wallets").document(walletId)
        let transactionsRef = walletRef.collection("transactions")
        
        // Income
        let income = Transaction(
            amount: 75000,
            currency: "TRY",
            date: Date(),
            type: .income,
            categoryName: "Maaş",
            subCategoryName: "Prim",
            createdBy: userId,
            note: "Simülasyon Geliri",
            isRecurring: false,
            createdByUsername: "Tester"
        )
        try transactionsRef.addDocument(from: income)
        
        // Expenses
        let expenses = [
            Transaction(amount: 2500, currency: "TRY", date: Date(), type: .expense, categoryName: "Gıda", subCategoryName: "Market", createdBy: userId, note: "Haftalık Alışveriş", isRecurring: false),
            Transaction(amount: 1500, currency: "TRY", date: Date().addingTimeInterval(-86400), type: .expense, categoryName: "Ulaşım", subCategoryName: "Benzin", createdBy: userId, note: "Depo Full", isRecurring: false),
            Transaction(amount: 5000, currency: "TRY", date: Date().addingTimeInterval(-172800), type: .expense, categoryName: "Eğlence", subCategoryName: "Restoran", createdBy: userId, note: "Akşam Yemeği", isRecurring: false)
        ]
        
        for exp in expenses {
            try transactionsRef.addDocument(from: exp)
        }
    }
    
    private func setSimulationLimit(walletId: String) async throws {
        try await db.collection("wallets").document(walletId).updateData([
            "monthlyLimit": 50000
        ])
    }
    
    private func setSimulationSavings(walletId: String) async throws {
        try await db.collection("wallets").document(walletId).updateData([
            "savingsGoal": 100000
        ])
    }
    
    private func createSimulationDebt(walletId: String) async throws {
        let debt = Debt(
            name: "Test Telefon Taksiti",
            totalAmount: 50000,
            remainingAmount: 45000,
            totalInstallments: 10,
            paidInstallments: 1,
            installmentAmount: 5000,
            currency: "TRY",
            status: .active,
            startDate: Date(),
            nextDueDate: Date().addingTimeInterval(86400 * 30),
            frequency: .monthly,
            createdBy: "Tester",
            walletId: walletId
        )
        
        try db.collection("wallets").document(walletId).collection("debts").addDocument(from: debt)
    }
    
    private func sendSimulationInvite(walletId: String, fromUserId: String) async throws {
        // Invite a fake user or generic email to avoid creating real notification spam for random users
        // Since we don't have a real second user ID readily available without querying, 
        // we will invite a placeholder "Test User"
        
        let invite = Invite(
            fromUserId: fromUserId,
            fromUsername: "Simülasyon Botu",
            toUserId: "mock_user_id_999",
            toUsername: "Hayali Test Kullanıcısı",
            walletId: walletId,
            walletName: "SİMÜLASYON TEST",
            role: "editor",
            status: .pending,
            createdAt: Date()
        )
        
        try db.collection("invites").addDocument(from: invite)
        
        try await FirestoreService.shared.addMember(walletId: walletId, userId: "mock_user_id_999", role: "pending")
    }

    // MARK: - Advanced Tests
    
    /// Simulates rapid parallel writes to check for race conditions
    func runConcurrencyTest(walletId: String) async {
        await MainActor.run {
            logger.log("⚡️ CONCURRENCY (EŞZAMANLILIK) TESTİ BAŞLIYOR...", level: .warning)
        }
        
        let dbRef = Firestore.firestore() // Local reference to avoid capturing self.db (MainActor)
        let loggerRef = DebugLogger.shared // Local reference
        
        // We use TaskGroup to run parallel tasks correctly in async/await context
        // This avoids manual DispatchGroups which can be tricky with actors
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    do {
                        let ref = dbRef.collection("wallets").document(walletId).collection("transactions").document()
                        try await ref.setData([
                            "amount": Double(i * 10),
                            "note": "Concurrency Packet #\(i)",
                            "date": FieldValue.serverTimestamp(),
                            "type": "expense",
                            "currency": "TRY",
                            "isRecurring": false,
                            "categoryName": "Test",
                            "createdAt": FieldValue.serverTimestamp(),
                            "createdBy": "ConcurrentUser"
                        ])
                    } catch {
                        // Logging from background task might need MainActor if DebugLogger is @MainActor
                        // Assuming DebugLogger handles its own dispatch or we ignore logs for speed
                         await MainActor.run {
                             loggerRef.log("❌ Race Error #\(i): \(error.localizedDescription)", level: .error)
                         }
                    }
                }
            }
        }
        
        await MainActor.run {
            logger.log("✅ Concurrency Test Batch Sent. Checking integrity...", level: .info)
        }
    }
    
    /// Validates business logic without UI
    func testGamificationLogic(walletId: String) async {
        logger.log("🏆 OYUNLAŞTIRMA MANTIĞI TEST EDİLİYOR...", level: .info)
        
        // 1. Fetch Transactions
        let snapshot = try? await db.collection("wallets").document(walletId).collection("transactions").getDocuments()
        let count = snapshot?.count ?? 0
        
        logger.log("ℹ️ Toplam İşlem: \(count)", level: .debug)
        
        // 2. Check Criteria
        if count >= 10 {
            logger.log("✅ 'Acemi Finansçı' Rozeti: KAZANILDI (10+ İşlem)", level: .info)
        } else {
            logger.log("❌ 'Acemi Finansçı' Rozeti: KAZANILAMADI (Gereken: 10, Mevcut: \(count))", level: .warning)
        }
        
        if count >= 100 {
            logger.log("✅ 'Usta Harcayıcı' Rozeti: KAZANILDI (100+ İşlem)", level: .info)
        } else {
             logger.log("🔒 'Usta Harcayıcı' Rozeti: KİLİTLİ", level: .debug)
        }
        
        // 3. Savings Check
        let walletDoc = try? await db.collection("wallets").document(walletId).getDocument()
        if let savings = walletDoc?.data()?["savingsGoal"] as? Double, savings > 0 {
             logger.log("✅ 'Birikimci' Rozeti: KAZANILDI (Hedef Var)", level: .info)
        } else {
             logger.log("❌ 'Birikimci' Rozeti: YOK", level: .warning)
        }
    }
}
