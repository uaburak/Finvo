import SwiftUI

enum BadgeCalculationMode: Equatable {
    case highestCategoryVolume(categories: [String]) // Winner has most volume in specific categories
    case highestTotalVolume // Winner has most volume overall (e.g., Top Spender, Top Earner)
    case lowestTotalVolume // Winner has least volume overall (e.g., Tutumlu)
}

enum BadgeTransactionType {
    case income
    case expense
}

struct BadgeDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String // SF Symbol
    let color: Color
    let mode: BadgeCalculationMode
    let transactionType: BadgeTransactionType
    
    // Optional: Only apply if total amount exceeds threshold? (Can add later)
    
    // Computed property for convenience
    var relatedCategories: [String] {
        switch mode {
        case .highestCategoryVolume(let cats): return cats
        default: return []
        }
    }
}

struct BadgeConfig {
    static let allBadges: [BadgeDefinition] = [
        // MARK: - EXPENSE BADGES (Category Based)
        
        // 1. Evin Direği
        BadgeDefinition(
            id: "evin_diregi", title: "Evin Direği", description: "Faturaların Efendisi",
            icon: "house.fill", color: .blue,
            mode: .highestCategoryVolume(categories: ["Faturalar", "Kira", "Elektrik", "Su", "Doğalgaz", "İnternet", "Aidat", "Telefon"]),
            transactionType: .expense
        ),
        
        // 2. Gurme
        BadgeDefinition(
            id: "gurme", title: "Gurme", description: "Boğazına Düşkün",
            icon: "fork.knife", color: .orange,
            mode: .highestCategoryVolume(categories: ["Yeme & İçme", "Market", "Restoran", "Cafe", "Gıda"]),
            transactionType: .expense
        ),
        
        // 3. Gezgin
        BadgeDefinition(
            id: "gezgin", title: "Gezgin", description: "Yolların Ustası",
            icon: "car.fill", color: .indigo,
            mode: .highestCategoryVolume(categories: ["Ulaşım", "Benzin", "Araba", "Taksi", "Otobüs", "Seyahat"]),
            transactionType: .expense
        ),
        
        // 4. Tekno Kurdu
        BadgeDefinition(
            id: "tekno_kurdu", title: "Tekno Kurdu", description: "Gelecekten Geliyor",
            icon: "desktopcomputer", color: .purple,
            mode: .highestCategoryVolume(categories: ["Teknoloji", "Elektronik", "Bilgisayar", "Telefon"]),
            transactionType: .expense
        ),
        
        // 5. Parti İnsanı
        BadgeDefinition(
            id: "parti_insani", title: "Parti İnsanı", description: "Hayatını Yaşıyor",
            icon: "party.popper.fill", color: .pink,
            mode: .highestCategoryVolume(categories: ["Eğlence", "Sinema", "Oyun", "Hobi", "Aktivite", "Eğlence & Sosyal"]),
            transactionType: .expense
        ),
        
        // 6. Moda İkonu
        BadgeDefinition(
            id: "moda_ikonu", title: "Moda İkonu", description: "Tarz Sahibi",
            icon: "tshirt.fill", color: .cyan,
            mode: .highestCategoryVolume(categories: ["Alışveriş", "Giyim", "Ayakkabı", "Aksesuar", "Moda", "Alışveriş & Giyim"]),
            transactionType: .expense
        ),
        
        // 7. Sağlıkçı
        BadgeDefinition(
            id: "saglikci", title: "Sağlıkçı", description: "Kendine İyi Bakıyor",
            icon: "heart.text.square.fill", color: .red,
            mode: .highestCategoryVolume(categories: ["Sağlık", "Eczane", "Hastane", "Spor", "Fitness", "Sağlık & Bakım"]),
            transactionType: .expense
        ),
        
        // 8. Bakımlı
        BadgeDefinition(
            id: "bakimli", title: "Bakımlı", description: "Işıltısı Yeter",
            icon: "sparkles", color: .mint,
            mode: .highestCategoryVolume(categories: ["Kuaför", "Berber", "Kozmetik", "Bakım"]),
            transactionType: .expense
        ),
        
        // 9. Hayvan Dostu
        BadgeDefinition(
            id: "hayvan_dostu", title: "Hayvan Dostu", description: "Pati Sever",
            icon: "pawprint.fill", color: .brown,
            mode: .highestCategoryVolume(categories: ["Evcil Hayvan", "Veteriner", "Mama"]),
            transactionType: .expense
        ),
        
        // 10. Abone
        BadgeDefinition(
            id: "abone", title: "Abone", description: "Dijital Yerli",
            icon: "play.tv.fill", color: .indigo,
            mode: .highestCategoryVolume(categories: ["Dijital Abonelikler", "Netflix", "Spotify", "Apple", "Google"]),
            transactionType: .expense
        ),
        
        // 11. Bilgin
        BadgeDefinition(
            id: "bilgin", title: "Bilgin", description: "Öğrenmeye Açık",
            icon: "book.fill", color: .orange,
            mode: .highestCategoryVolume(categories: ["Eğitim", "Kitap", "Kurs", "Okul", "Kırtasiye"]),
            transactionType: .expense
        ),
        
        // 12. Yatırımcı (Expense side - e.g. buying gold)
        BadgeDefinition(
            id: "yatirimci", title: "Yatırımcı", description: "Geleceği Düşünen",
            icon: "chart.line.uptrend.xyaxis", color: .green,
            mode: .highestCategoryVolume(categories: ["Yatırım", "Altın Alım", "Döviz Alım", "Bireysel Emeklilik", "Birikim & Yatırım"]),
            transactionType: .expense
        ),
        
        // 13. Sadık (Debt Payer)
        BadgeDefinition(
            id: "sadik", title: "Sadık", description: "Borcunu Bilir",
            icon: "signature", color: .gray,
            mode: .highestCategoryVolume(categories: ["Borç Ödeme", "Kredi Kartı", "Kredi", "Borç & Finansal Ödemeler"]),
            transactionType: .expense
        ),
        
        // 14. Gamer
        BadgeDefinition(
            id: "gamer", title: "Gamer", description: "Oyun Dünyası",
            icon: "gamecontroller.fill", color: .purple,
            mode: .highestCategoryVolume(categories: ["PlayStation Plus", "Xbox Game Pass", "Nintendo Switch Online", "Steam (EA Play vb.)", "Twitch (Sub)", "Hobi / Oyun / Oyuncak"]),
            transactionType: .expense
        ),
        
        // 15. Kahve Tutkunu
        BadgeDefinition(
            id: "kahve_tutkunu", title: "Kahve Tutkunu", description: "Kafeinsiz Yapamaz",
            icon: "cup.and.saucer.fill", color: .brown,
            mode: .highestCategoryVolume(categories: ["Kafe / Kahve", "Starbucks", "Kahve"]),
            transactionType: .expense
        ),
        
        // 16. Dekoratör
        BadgeDefinition(
            id: "dekorator", title: "Dekoratör", description: "Evim Güzel Evim",
            icon: "lamp.table.fill", color: .orange,
            mode: .highestCategoryVolume(categories: ["Mobilya / Dekorasyon", "Ev Bakım / Tamirat", "Bahçe / Balkon Bakımı"]),
            transactionType: .expense
        ),
        
        // MARK: - INCOME BADGES
        
        // 17. Profesyonel (Salary)
        BadgeDefinition(
            id: "profesyonel", title: "Profesyonel", description: "Emeğinin Karşılığı",
            icon: "briefcase.fill", color: .blue,
            mode: .highestCategoryVolume(categories: ["Maaş", "Kariyer", "Maaş & Kariyer", "Ana Maaş", "Ek Mesai"]),
            transactionType: .income
        ),
        
        // 18. Rantçı (Passive Income)
        BadgeDefinition(
            id: "rantci", title: "Rantçı", description: "Para Parayı Çeker",
            icon: "building.2.fill", color: .purple,
            mode: .highestCategoryVolume(categories: ["Yatırım Geliri", "Faiz", "Temettü", "Kira", "Gayrimenkul", "Yatırım & Finansal Gelir", "Konut Kira Geliri"]),
            transactionType: .income
        ),
        
        // 19. Para Babası (Top Total Income)
        BadgeDefinition(
            id: "para_babasi", title: "Para Babası", description: "En Çok Kazanan",
            icon: "dollarsign.circle.fill", color: .green,
            mode: .highestTotalVolume,
            transactionType: .income
        ),
        
        // MARK: - SPECIAL BADGES
        
        // 20. Bonkör (Top Total Spender)
        BadgeDefinition(
            id: "bonkor", title: "Bonkör", description: "Eli En Açık",
            icon: "star.fill", color: .yellow,
            mode: .highestTotalVolume,
            transactionType: .expense
        ),
        
        // 21. Tutumlu (Lowest Total Spender)
        BadgeDefinition(
            id: "tutumlu", title: "Tutumlu", description: "Ekonomist",
            icon: "leaf.fill", color: .green,
            mode: .lowestTotalVolume,
            transactionType: .expense
        )
    ]
}
