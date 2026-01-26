import Foundation
import FirebaseFirestore

enum ReportRangeType: String, Codable, CaseIterable {
    case month = "Aylık"
    case sixMonths = "6 Aylık"
    case year = "Yıllık"
    case custom = "Özel"
}

struct Report: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var walletId: String
    var createdBy: String // User ID
    var createdAt: Date
    
    // Range Info
    var rangeType: ReportRangeType
    var startDate: Date
    var endDate: Date
    
    // Consolidated Stats
    var totalIncome: Double
    var totalExpense: Double
    
    // Breakdowns
    var categoryBreakdown: [String: Double] // CategoryName -> Amount
    var memberBreakdown: [String: Double]? // MemberUsername -> Amount (For shared wallets)
    
    // Net Flow
    var netBalance: Double {
        return totalIncome - totalExpense
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case walletId
        case createdBy
        case createdAt
        case rangeType
        case startDate
        case endDate
        case totalIncome
        case totalExpense
        case categoryBreakdown
        case memberBreakdown
    }
}
