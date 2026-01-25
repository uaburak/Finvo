import Foundation

struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let iconName: String
    let subCategories: [String]
    let colorHex: String
}

struct CategoriesData {
    static let incomeCategories: [Category] = [
        Category(name: "Maaş", iconName: "dollarsign.circle.fill", subCategories: ["Aylık Maaş", "Prim", "Ek Ödeme"], colorHex: "#34C759"),
        Category(name: "Yatırım", iconName: "chart.line.uptrend.xyaxis", subCategories: ["Hisse Senedi", "Kripto", "Döviz", "Faiz"], colorHex: "#34C759"),
        Category(name: "Hediye", iconName: "gift.fill", subCategories: ["Nakit Hediye", "Ödül"], colorHex: "#34C759"),
        Category(name: "Diğer", iconName: "plus.circle.fill", subCategories: ["Satış", "İade", "Diğer"], colorHex: "#34C759")
    ]
    
    static let expenseCategories: [Category] = [
        Category(name: "Gıda", iconName: "cart.fill", subCategories: ["Market", "Restoran", "Kafe", "Atıştırmalık"], colorHex: "#FF9500"),
        Category(name: "Ulaşım", iconName: "car.fill", subCategories: ["Benzin", "Toplu Taşıma", "Taksi", "Bakım"], colorHex: "#007AFF"),
        Category(name: "Konut", iconName: "house.fill", subCategories: ["Kira", "Aidat", "Tamirat", "Mobilya"], colorHex: "#AF52DE"),
        Category(name: "Faturalar", iconName: "bolt.fill", subCategories: ["Elektrik", "Su", "Doğalgaz", "İnternet", "Telefon"], colorHex: "#FF3B30"),
        Category(name: "Eğlence", iconName: "film.fill", subCategories: ["Sinema", "Oyun", "Konser", "Tatil"], colorHex: "#5856D6"),
        Category(name: "Sağlık", iconName: "heart.fill", subCategories: ["Doktor", "İlaç", "Spor", "Sigorta"], colorHex: "#FF2D55"),
        Category(name: "Giyim", iconName: "tshirt.fill", subCategories: ["Kıyafet", "Ayakkabı", "Aksesuar"], colorHex: "#5AC8FA"),
        Category(name: "Diğer", iconName: "ellipsis.circle.fill", subCategories: ["Kozmetik", "Eğitim", "Bağış", "Diğer"], colorHex: "#8E8E93")
    ]
}
