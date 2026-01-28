import Foundation
import FirebaseFirestore

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
    case customTwoMinutes // For testing
    
    var displayName: String {
        switch self {
        case .daily: return "Günlük"
        case .weekly: return "Haftalık"
        case .monthly: return "Aylık"
        case .yearly: return "Yıllık"
        case .customTwoMinutes: return "2 Dakika (Test)"
        }
    }
}

enum DebtStatus: String, Codable {
    case active
    case completed
    case cancelled
}

struct Debt: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var totalAmount: Double
    var remainingAmount: Double
    var totalInstallments: Int
    var paidInstallments: Int
    var installmentAmount: Double // Amount per installment
    var currency: String
    var status: DebtStatus
    
    var startDate: Date
    var nextDueDate: Date
    var frequency: RecurrenceFrequency
    
    var createdBy: String
    var walletId: String
    
    // Optional: Keep track of transaction IDs linked to this debt if needed
    // var transactionIds: [String] = []
    
    var progress: Double {
        guard totalInstallments > 0 else { return 0 }
        return Double(paidInstallments) / Double(totalInstallments)
    }
    
    var isOverdue: Bool {
        return status == .active && nextDueDate < Date()
    }
}
