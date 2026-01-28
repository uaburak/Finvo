import Foundation
import FirebaseFirestore
import UserNotifications

class DebtAutomationService {
    static let shared = DebtAutomationService()
    private let firestoreService = FirestoreService.shared
    private let db = Firestore.firestore()
    
    // Run automation for a specific wallet
    func checkAndProcessDueDebts(walletId: String) async {
        print("🔍 DebtAutomation: Checking wallet \(walletId)...")
        
        do {
            let activeDebts = try await firestoreService.fetchActiveDebts(walletId: walletId)
            
            for var debt in activeDebts {
                if debt.nextDueDate <= Date() {
                    print("⚡️ DebtAutomation: Processing due debt: \(debt.name)")
                    await processDebtInstallment(walletId: walletId, debt: &debt)
                }
            }
        } catch {
            print("❌ DebtAutomation Error: \(error.localizedDescription)")
        }
    }
    
    private func processDebtInstallment(walletId: String, debt: inout Debt) async {
        // 1. Create Transaction
        // currentInstallment for the NEW transaction is actually (paid + 1)
        // But wait, if paidInstallments is 7, it means 7 are DONE. Next is 8.
        let installmentNumber = debt.paidInstallments + 1
        
        // Safety check
        if installmentNumber > debt.totalInstallments {
            // Already full? Should have been completed. Mark complete and return.
            var completedDebt = debt
            completedDebt.status = .completed
            try? await firestoreService.updateDebt(walletId: walletId, debt: completedDebt)
            return
        }
        
        let newTransaction = Transaction(
            amount: debt.installmentAmount,
            currency: debt.currency,
            date: Date(), // Transaction happens NOW
            type: .expense, // Debts are typically expenses
            categoryName: "Borç Ödemesi", // Or keep original category if stored in Debt
            subCategoryName: debt.name,
            createdBy: debt.createdBy,
            note: "Borcun \(installmentNumber). Taksidi",
            isRecurring: true,
            createdByUsername: "Sistem", // System created
            linkedDebtId: debt.id,
            recurrenceFrequency: debt.frequency
        )
        
        do {
            try await firestoreService.addTransaction(walletId: walletId, transaction: newTransaction)
            
            // 2. Update Debt
            debt.paidInstallments += 1
            debt.remainingAmount -= debt.installmentAmount
            if debt.remainingAmount < 0 { debt.remainingAmount = 0 }
            
            // Calculate NEXT due date
            if let nextDate = calculateNextDueDate(from: debt.nextDueDate, frequency: debt.frequency) {
                debt.nextDueDate = nextDate
            }
            
            // Check completion
            if debt.paidInstallments >= debt.totalInstallments || debt.remainingAmount <= 0 {
                debt.status = .completed
                sendNotification(title: "Borç Bitti! 🎉", body: "\(debt.name) borcunun son taksidi ödendi.")
            } else {
                sendNotification(title: "Otomatik İşlem", body: "\(debt.name) taksidi ödendi. (\(installmentNumber)/\(debt.totalInstallments))")
            }
            
            try await firestoreService.updateDebt(walletId: walletId, debt: debt)
            
            // Recursive check? 
            // If nextDueDate is STILL in the past (e.g. missed 2 months), should we process again?
            // "Zaman Yolcusu" implies catching up.
            // Yes, let's call recursively if the NEW nextDueDate is still <= Today.
            if debt.status == .active && debt.nextDueDate <= Date() {
                // Determine if we should really loop. To prevent infinite loops, check if date moved forward.
                // It moved forward by calculateNextDueDate.
                // Add a small delay or just continue.
                print("🔄 DebtAutomation: Catching up another installment for \(debt.name)")
                await processDebtInstallment(walletId: walletId, debt: &debt)
            }
            
        } catch {
            print("❌ Error processing installment: \(error.localizedDescription)")
        }
    }
    
    private func calculateNextDueDate(from date: Date, frequency: RecurrenceFrequency) -> Date? {
        let calendar = Calendar.current
        switch frequency {
        case .daily: return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly: return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly: return calendar.date(byAdding: .year, value: 1, to: date)
        case .customTwoMinutes: return calendar.date(byAdding: .minute, value: 2, to: date)
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
