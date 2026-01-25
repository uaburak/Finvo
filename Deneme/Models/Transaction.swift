import Foundation
import FirebaseFirestore

enum TransactionType: String, Codable {
    case income
    case expense
}

struct Transaction: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var amount: Double
    var currency: String
    var date: Date
    var type: TransactionType
    var categoryName: String
    var subCategoryName: String
    var createdBy: String
    var note: String?
    var isRecurring: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case currency
        case date
        case type
        case categoryName
        case subCategoryName
        case createdBy
        case note
        case isRecurring
    }
}
