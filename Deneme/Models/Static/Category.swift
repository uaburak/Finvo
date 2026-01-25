import Foundation
import SwiftUI

enum CategoryType: String, Codable, CaseIterable {
    case income
    case expense
}

struct SubCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var colorHex: String
    var isVisible: Bool = true
    
    var color: Color {
        return Color(hex: colorHex) ?? .gray
    }
}

struct Category: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var colorHex: String
    var type: CategoryType
    var subCategories: [SubCategory]
    var isVisible: Bool = true
    var isCustom: Bool = false
    
    var color: Color {
        return Color(hex: colorHex) ?? .gray
    }
}
