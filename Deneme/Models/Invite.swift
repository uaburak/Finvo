import Foundation
import FirebaseFirestore

enum InviteStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct Invite: Identifiable, Codable {
    @DocumentID var id: String?
    var fromUserId: String
    var fromUsername: String
    var toUserId: String
    var toUsername: String
    var walletId: String
    var walletName: String
    var role: String
    var status: InviteStatus
    var createdAt: Date
}
