import SwiftUI

struct MemberPersona: Identifiable {
    let id = UUID()
    let username: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let keyStat: String
    let badgeColor: Color
    
    // For Detail View Logic
    let userId: String // To filter transactions correctly
    let relatedCategories: [String] // Categories that contributed to this badge
}
