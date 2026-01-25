import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable {
    case info // General info
    case rejection // "User rejected your invite"
    case acceptance // "User accepted your invite"
}

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String // Processed for this user
    var title: String
    var message: String
    var type: NotificationType
    var relatedId: String? // e.g., WalletID or InviteID
    var isRead: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case title
        case message
        case type
        case relatedId
        case isRead
        case createdAt
    }
}
