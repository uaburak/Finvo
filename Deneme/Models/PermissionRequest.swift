import Foundation
import FirebaseFirestore

enum PermissionRequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct PermissionRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let fromUserId: String
    let fromUsername: String
    let toOwnerId: String // The wallet owner who receives the request
    let walletId: String
    let walletName: String
    var status: PermissionRequestStatus
    let createdAt: Date
}
