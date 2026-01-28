import Foundation
import FirebaseFirestore
import UserNotifications

class RecurrenceManager {
    static let shared = RecurrenceManager()
    
    // Calculates the next occurrence date based on frequency
    func calculateNextOccurrence(from date: Date, frequency: RecurrenceFrequency) -> Date? {
        let calendar = Calendar.current
        switch frequency {
        case .daily: return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly: return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly: return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly: return calendar.date(byAdding: .year, value: 1, to: date)
        case .customTwoMinutes: return calendar.date(byAdding: .minute, value: 2, to: date)
        }
    }
}

class RecurringTransactionService {
    static let shared = RecurringTransactionService()
    private let firestoreService = FirestoreService.shared
    
    // Main function to check and process recurring transactions
    func checkAndProcessRecurringTransactions(for walletId: String) async {
        print("🔍 RecurringService: Checking wallet \(walletId)...")
        
        do {
            // 1. Fetch recurring transactions that are due (nextOccurrenceDate <= Now)
            // Note: In a real app, you'd use a compound query index for this.
            // For now, we fetch likely candidates or all active recurring transactions and filter client-side 
            // to avoid complex index requirements initially.
            let snapshot = try await Firestore.firestore().collection("wallets").document(walletId).collection("transactions")
                .whereField("isRecurring", isEqualTo: true)
                .getDocuments()
            
            let recurringTransactions = snapshot.documents.compactMap { try? $0.data(as: Transaction.self) }
            
            for transaction in recurringTransactions {
                guard let nextDate = transaction.nextOccurrenceDate, nextDate <= Date() else { continue }
                
                // Check End Date
                if let endDate = transaction.endDate, nextDate > endDate {
                    // Recurrence expired. Turn off recurrence.
                    print("🛑 RecurringService: Expired \(transaction.note ?? "Transaction")")
                    var expiredTransaction = transaction
                    expiredTransaction.isRecurring = false
                    try? await firestoreService.updateTransaction(walletId: walletId, transaction: expiredTransaction)
                    continue
                }
                
                print("⚡️ RecurringService: Processing \(transaction.note ?? "Transaction")")
                await processRecurringInstance(walletId: walletId, parentTransaction: transaction)
            }
            
        } catch {
            print("❌ RecurringService Error: \(error.localizedDescription)")
        }
    }
    
    private func processRecurringInstance(walletId: String, parentTransaction: Transaction) async {
        guard let frequency = parentTransaction.recurrenceFrequency,
              let currentNextDate = parentTransaction.nextOccurrenceDate else { return }
        
        // 1. Create the New Occurrence Transaction
        let newTransaction = Transaction(
            amount: parentTransaction.amount,
            currency: parentTransaction.currency,
            date: currentNextDate, // The date it was SUPPOSED to happen
            type: parentTransaction.type,
            categoryName: parentTransaction.categoryName,
            subCategoryName: parentTransaction.subCategoryName,
            createdBy: parentTransaction.createdBy,
            note: (parentTransaction.note ?? "") + " (Otomatik)",
            isRecurring: false, // The instance itself is NOT recurring, it's a child
            createdByUsername: parentTransaction.createdByUsername ?? "Sistem", // Use original creator
            linkedDebtId: nil,
            recurrenceFrequency: nil,
            endDate: nil,
            nextOccurrenceDate: nil,
            parentTransactionId: parentTransaction.id
        )
        
        do {
            try await firestoreService.addTransaction(walletId: walletId, transaction: newTransaction)
            
            // 2. Update the Parent Transaction's nextOccurrenceDate
            var updatedParent = parentTransaction
            
            // Calculate NEXT NEXT date
            // Importantly: Calculate from the CURRENT next date, not from Now(), to prevent drift.
            if let nextNextDate = RecurrenceManager.shared.calculateNextOccurrence(from: currentNextDate, frequency: frequency) {
                updatedParent.nextOccurrenceDate = nextNextDate
                
                // Recursion Check (Time Traveler protection)
                // If the nextNextDate is ALSO in the past (e.g. system was offline for a month and it's a daily transaction),
                // we might want to process it immediately.
                // For safety, let's limit recursion or just let the next app launch handle it?
                // For a "2 minute" test, we definitely want recursion or fast polling.
                // Let's allow one level of recursion or loop in the main function.
                
                try await firestoreService.updateTransaction(walletId: walletId, transaction: updatedParent)
                
                sendNotification(title: "Tekrarlayan İşlem", body: "\(newTransaction.categoryName) işlemi otomatik oluşturuldu.")
                
                // If we are way behind, call again?
                if nextNextDate <= Date() {
                    // Small delay to prevent tight loops
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    await processRecurringInstance(walletId: walletId, parentTransaction: updatedParent)
                }
            } else {
                // Calculation failed? Stop recurrence.
                updatedParent.isRecurring = false
                try await firestoreService.updateTransaction(walletId: walletId, transaction: updatedParent)
            }
            
        } catch {
            print("❌ RecurringService Process Error: \(error.localizedDescription)")
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
