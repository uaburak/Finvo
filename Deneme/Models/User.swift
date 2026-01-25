import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let email: String
    let username: String
    var displayName: String?
    var photoURL: String?
    var isPro: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case email
        case username
        case displayName
        case photoURL
        case isPro
    }
}
