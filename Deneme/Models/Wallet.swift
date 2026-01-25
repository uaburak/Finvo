import Foundation
import FirebaseFirestore

enum WalletType: String, Codable {
    case personal
    case shared
}

enum WalletContext: String, Codable {
    case budget
    case todo
    case savings
    case travel
}

struct Wallet: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var type: WalletType
    var context: WalletContext // New field
    var members: [String]
    var permissions: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerId
        case type
        case context
        case members
        case permissions
    }
    
    func isOwner(userId: String) -> Bool {
        return ownerId == userId
    }
    
    func canEdit(userId: String) -> Bool {
        if isOwner(userId: userId) { return true }
        let role = permissions[userId] ?? "editor" 
        // Backward compatibility: if not in permissions but in members, default to 'editor'.
        // BUT if it is explicitly 'pending', they CANNOT edit.
        return role == "editor" // This automatically returns false for "pending", "viewer", etc.
    }
}
