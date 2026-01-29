import Foundation
import Combine
import SwiftUI

enum AnalyticsTimeRange: String, CaseIterable {
    case week = "Haftalık"
    case month = "Aylık"
    case year = "Yıllık"
    case all = "Tümü"
}

@MainActor
class AnalyticsViewModel: ObservableObject {
    // published properties
    @Published var selectedTimeRange: AnalyticsTimeRange = .month {
        didSet {
            // Re-process data when time range changes
            processData()
        }
    }
    
    @Published var chartData: [CategoryDouble] = [] // For Pie/Donut Chart (Categories)
    @Published var trendData: [DateValue] = []      // For Line/Bar Chart (Trend)
    @Published var memberData: [MemberDouble] = []  // For Member Comparison
    @Published var memberPersonas: [MemberPersona] = [] // NEW: Social Personas
    @Published var categoryMemberComparison: [CategoryMemberBreakdown] = [] // NEW: Detailed Comparison
    
    // Summary Stats
    @Published var totalIncome: Double = 0
    @Published var totalExpense: Double = 0
    @Published var balance: Double = 0
    
    // Debt Stats
    @Published var activeDebts: [Debt] = []
    @Published var totalDebtRemaining: Double = 0
    @Published var upcomingDebtPayment: Double = 0
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var exportItem: ExportItem?
    
    struct ExportItem: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    // Interactivity
    @Published var selectedCategory: CategoryDouble?
    
    // Computed: Transactions for the selected category (for drill-down)
    var transactionsForSelectedCategory: [Transaction] {
        guard let selected = selectedCategory else { return [] }
        return filterTransactionsByTimeRange(allTransactions, range: selectedTimeRange, offset: 0)
            .filter { $0.categoryName == selected.category && $0.type == .expense }
            .sorted(by: { $0.date > $1.date })
    }
    
    // Comparison & Insights
    @Published var expenseChangePercentage: Double = 0
    @Published var isExpenseIncreased: Bool = false
    @Published var averageDailySetting: Double = 0
    @Published var largestTransaction: Transaction?
    @Published var topCategoryName: String?
    
    // Valid Transactions Cache
    private var allTransactions: [Transaction] = []
    private var userDisplayNames: [String: String] = [:] // Check names
    
    // Structs for Charts
    struct CategoryDouble: Identifiable, Equatable {
        let id = UUID()
        let category: String
        let value: Double
        let color: Color
        let percentage: Double
        
        static func == (lhs: CategoryDouble, rhs: CategoryDouble) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    struct DateValue: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double // Expense or Net
        let type: String // "Income" or "Expense"
    }
    
    struct MemberDouble: Identifiable {
        let id = UUID()
        let username: String
        let value: Double
        let color: Color
        let percentage: Double // New field
    }
    
    private let firestoreService = FirestoreService.shared
    
    func fetchData(for wallet: Wallet) async {
        guard let walletId = wallet.id else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            self.allTransactions = try await firestoreService.fetchAllTransactions(walletId: walletId)
            
            // NEW: Fetch User Profiles for Display Names
            let userIds = Set(self.allTransactions.map { $0.createdBy })
            let users = try await firestoreService.fetchUsers(uids: Array(userIds))
            self.userDisplayNames = Dictionary(uniqueKeysWithValues: users.map { ($0.username, $0.displayName ?? $0.username) })
            
            self.activeDebts = try await firestoreService.fetchActiveDebts(walletId: walletId)
            processData()
            processDebts()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func processData() {
        let currentRangeTransactions = filterTransactionsByTimeRange(allTransactions, range: selectedTimeRange, offset: 0)
        let previousRangeTransactions = filterTransactionsByTimeRange(allTransactions, range: selectedTimeRange, offset: 1) // 1 period back
        
        // 1. Calculate Summaries
        let income = currentRangeTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = currentRangeTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        self.totalIncome = income
        self.totalExpense = expense
        self.balance = income - expense
        
        // 2. Comparison Logic (Expense vs Previous)
        let prevExpense = previousRangeTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        if prevExpense > 0 {
            self.expenseChangePercentage = ((expense - prevExpense) / prevExpense) * 100
        } else {
            self.expenseChangePercentage = expense > 0 ? 100 : 0
        }
        self.isExpenseIncreased = expense > prevExpense
        
        // 3. Advanced Insights
        // Average Daily
        let dayCount = dayCount(for: selectedTimeRange)
        self.averageDailySetting = expense / Double(dayCount)
        
        // Largest Transaction
        self.largestTransaction = currentRangeTransactions.filter { $0.type == .expense }.max(by: { $0.amount < $1.amount })
        
        // Top Category
        let expensesOnly = currentRangeTransactions.filter { $0.type == .expense }
        let groupedByCategory = Dictionary(grouping: expensesOnly, by: { $0.categoryName })
        if let topCat = groupedByCategory.max(by: { $0.value.reduce(0) { $0+$1.amount } < $1.value.reduce(0) { $0 + $1.amount } }) {
            self.topCategoryName = topCat.key
        } else {
            self.topCategoryName = nil
        }
        
        // 4. Category Breakdown
        let totalExp = expensesOnly.reduce(0) { $0 + $1.amount }
        self.chartData = groupedByCategory.map { (key, transactions) in
            let sum = transactions.reduce(0) { $0 + $1.amount }
            let percent = totalExp > 0 ? (sum / totalExp) * 100 : 0
            let category = CategoryManager.shared.categories.first(where: { $0.name == key })
            let colorHex = category?.colorHex ?? "#8E8E93"
            return CategoryDouble(category: key, value: sum, color: Color(hex: colorHex) ?? .gray, percentage: percent)
        }.sorted(by: { $0.value > $1.value })
        
        // 5. Trend Data
        let groupedByDate: [Date: [Transaction]]
        if selectedTimeRange == .week || selectedTimeRange == .month {
             groupedByDate = Dictionary(grouping: currentRangeTransactions) { Calendar.current.startOfDay(for: $0.date) }
        } else {
            groupedByDate = Dictionary(grouping: currentRangeTransactions) { transaction in
                let components = Calendar.current.dateComponents([.year, .month], from: transaction.date)
                return Calendar.current.date(from: components) ?? transaction.date
            }
        }
        
        var tempTrend: [DateValue] = []
        for (date, transactions) in groupedByDate {
            let dailyExpense = transactions.filter({ $0.type == .expense }).reduce(0) { $0 + $1.amount }
            tempTrend.append(DateValue(date: date, value: dailyExpense, type: "Gider"))
        }
        self.trendData = tempTrend.sorted(by: { $0.date < $1.date })
        // 6. Member Comparison
        let groupedByUser = Dictionary(grouping: expensesOnly, by: { $0.createdByUsername ?? "Bilinmeyen" })
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow]
        
        let totalExpensesForMembers = expensesOnly.reduce(0) { $0 + $1.amount }
        
        self.memberData = groupedByUser.keys.enumerated().map { (index, username) in
            let transactions = groupedByUser[username] ?? []
            let sum = transactions.reduce(0) { $0 + $1.amount }
            let color = colors[index % colors.count]
            let percent = totalExpensesForMembers > 0 ? (sum / totalExpensesForMembers) * 100 : 0
            return MemberDouble(username: username, value: sum, color: color, percentage: percent)
        }.sorted(by: { $0.value > $1.value })
        
        // 7. Calculate Personas
        calculatePersonas(groupedByUser: groupedByUser, totalExpense: totalExpensesForMembers)
        
        // 8. Calculate Category Matrix
        calculateCategoryMemberMatrix(transactions: expensesOnly)
    }
    
    private func calculateCategoryMemberMatrix(transactions: [Transaction]) {
        let groupedByCat = Dictionary(grouping: transactions, by: { $0.categoryName })
        var breakdown: [CategoryMemberBreakdown] = []
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow] 
        let allUsers = Set(transactions.map { $0.createdByUsername ?? "Bilinmeyen" }).sorted()
        
        for (category, catTransactions) in groupedByCat {
            let total = catTransactions.reduce(0) { $0 + $1.amount }
            if total < self.totalExpense * 0.01 { continue }
            
            var members: [MemberDouble] = []
            let groupedByUser = Dictionary(grouping: catTransactions, by: { $0.createdByUsername ?? "Bilinmeyen" })
            
            for (username, userTrans) in groupedByUser {
                let sum = userTrans.reduce(0) { $0 + $1.amount }
                let index = allUsers.firstIndex(of: username) ?? 0
                let color = colors[index % colors.count]
                members.append(MemberDouble(username: username, value: sum, color: color, percentage: (sum/total)*100))
            }
            members.sort(by: { $0.value > $1.value })
            breakdown.append(CategoryMemberBreakdown(id: UUID(), categoryName: category, totalAmount: total, memberShares: members))
        }
        self.categoryMemberComparison = breakdown.sorted(by: { $0.totalAmount > $1.totalAmount })
    }
    
    struct CategoryMemberBreakdown: Identifiable {
        let id: UUID
        let categoryName: String
        let totalAmount: Double
        let memberShares: [MemberDouble]
    }
    
    private func calculatePersonas(groupedByUser: [String: [Transaction]], totalExpense: Double) {
        var newPersonas: [MemberPersona] = []
        
        // Helper to find winner of a category group
        // Helper to find top spender for a set of categories (Main or Sub)
        func findWinner(for categories: [String]) -> (user: String, amount: Double)? {
            var totals: [String: Double] = [:]
            for (user, trans) in groupedByUser {
                // Check unique match in either Category or SubCategory
                let matchingTrans = trans.filter { t in
                    categories.contains(t.categoryName) || categories.contains(t.subCategoryName)
                }
                let sum = matchingTrans.reduce(0) { $0 + $1.amount }
                if sum > 0 { totals[user] = sum }
            }
            guard let max = totals.max(by: { $0.value < $1.value }) else { return nil }
            return (user: max.key, amount: max.value)
        }
        
        // Helper for Income Badges (Hack: we need income transactions)
        let currentTrans = filterTransactionsByTimeRange(allTransactions, range: selectedTimeRange, offset: 0)
        let incomeTrans = currentTrans.filter { $0.type == .income }
        let groupedIncome = Dictionary(grouping: incomeTrans, by: { $0.createdByUsername ?? "Bilinmeyen" })
        
        func findIncomeWinner(for categories: [String]) -> (user: String, amount: Double)? {
             var totals: [String: Double] = [:]
             for (user, trans) in groupedIncome {
                 let matchingTrans = trans.filter { t in
                    categories.contains(t.categoryName) || categories.contains(t.subCategoryName)
                 }
                 let sum = matchingTrans.reduce(0) { $0 + $1.amount }
                 if sum > 0 { totals[user] = sum }
             }
             guard let max = totals.max(by: { $0.value < $1.value }) else { return nil }
             return (user: max.key, amount: max.value)
        }
        
        // Helper to get total income winner
        func findTopEarner() -> (user: String, amount: Double)? {
            let sortedInc = groupedIncome.map { ($0.key, $0.value.reduce(0){$0 + $1.amount}) }.sorted(by: { $0.1 > $1.1 })
            return sortedInc.first
        }
        
        let sortedUsers = groupedByUser.map { ($0.key, $0.value.reduce(0){$0 + $1.amount}) }.sorted(by: { $0.1 > $1.1 })
        
        // Helper to get First Name
        func getFirstName(for username: String) -> String {
            let fullName = userDisplayNames[username] ?? username
            return fullName.components(separatedBy: " ").first ?? fullName
        }
        
        // 1. Evin Direği (Bills)
        let billsCats = ["Faturalar", "Kira", "Elektrik", "Su", "Doğalgaz", "İnternet", "Aidat", "Telefon"]
            if let winner = findWinner(for: billsCats) {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Evin Direği",
                description: "Faturaların Efendisi",
                icon: "house.fill",
                color: .blue,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .blue,
                userId: winner.user,
                relatedCategories: billsCats
            ))
        }
        
        // 2. Gurme (Food)
        let foodCats = ["Yeme & İçme", "Market", "Restoran", "Cafe", "Gıda"]
        if let winner = findWinner(for: foodCats) {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Gurme",
                description: "Boğazına Düşkün",
                icon: "fork.knife",
                color: .orange,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .orange,
                userId: winner.user,
                relatedCategories: foodCats
            ))
        }
        
        // 3. Gezgin (Transport)
        let transportCats = ["Ulaşım", "Benzin", "Araba", "Taksi", "Otobüs", "Seyahat"]
        if let winner = findWinner(for: transportCats) {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Gezgin",
                description: "Yolların Ustası",
                icon: "car.fill",
                color: .indigo,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .indigo,
                userId: winner.user,
                relatedCategories: transportCats
            ))
        }
        
        // 4. Teknoloji Tutkunu (Electronics - New!)
        let techCats = ["Teknoloji", "Elektronik", "Bilgisayar", "Telefon"]
        if let winner = findWinner(for: techCats) {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Tekno Kurdu",
                description: "Gelecekten Geliyor",
                icon: "desktopcomputer",
                color: .purple,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .purple,
                userId: winner.user,
                relatedCategories: techCats
            ))
        }
        
        // 5. Eğlence (Entertainment)
        let funCats = ["Eğlence", "Sinema", "Oyun", "Hobi", "Aktivite", "Eğlence & Sosyal"]
        if let winner = findWinner(for: funCats) {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Parti İnsanı",
                description: "Hayatını Yaşıyor",
                icon: "party.popper.fill",
                color: .pink,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .pink,
                userId: winner.user,
                relatedCategories: funCats
            ))
        }
        
        // --- NEW BADGES ---
        
        // 6. Moda İkonu (Shopping/Clothing)
        let fashionCats = ["Alışveriş", "Giyim", "Ayakkabı", "Aksesuar", "Moda", "Alışveriş & Giyim"]
        if let winner = findWinner(for: fashionCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Moda İkonu",
                description: "Tarz Sahibi",
                icon: "tshirt.fill",
                color: .cyan,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .cyan,
                userId: winner.user,
                relatedCategories: fashionCats
            ))
        }
        
        // 7. Sağlıkçı (Health)
        let healthCats = ["Sağlık", "Eczane", "Hastane", "Spor", "Fitness", "Sağlık & Bakım"]
        if let winner = findWinner(for: healthCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Sağlıkçı",
                description: "Kendine İyi Bakıyor",
                icon: "heart.text.square.fill",
                color: .red,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .red,
                userId: winner.user,
                relatedCategories: healthCats
            ))
        }
        
        // 8. Kişisel Bakım (Self Care)
        let careCats = ["Kuaför", "Berber", "Kozmetik", "Bakım"]
        if let winner = findWinner(for: careCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Bakımlı",
                description: "Işıltısı Yeter",
                icon: "sparkles",
                color: .mint,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .mint,
                userId: winner.user,
                relatedCategories: careCats
            ))
        }
        
        // 9. Evcil Hayvan Dostu
        let petCats = ["Evcil Hayvan", "Veteriner", "Mama"]
        if let winner = findWinner(for: petCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Hayvan Dostu",
                description: "Pati Sever",
                icon: "pawprint.fill",
                color: .brown,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .brown,
                userId: winner.user,
                relatedCategories: petCats
            ))
        }
        
        // 10. Abonelik Canavarı (Subscriptions)
        let subCats = ["Dijital Abonelikler", "Netflix", "Spotify", "Apple", "Google"]
        if let winner = findWinner(for: subCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Abone",
                description: "Dijital Yerli",
                icon: "play.tv.fill",
                color: .indigo,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .indigo,
                userId: winner.user,
                relatedCategories: subCats
            ))
        }
        
        // 11. Eğitim & Kitap
        let eduCats = ["Eğitim", "Kitap", "Kurs", "Okul", "Kırtasiye"]
        if let winner = findWinner(for: eduCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Bilgin",
                description: "Öğrenmeye Açık",
                icon: "book.fill",
                color: .orange,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .orange,
                userId: winner.user,
                relatedCategories: eduCats
            ))
        }
        
        // 12. Yatırımcı (Expense to Investment)
        let investExpCats = ["Yatırım", "Altın Alım", "Döviz Alım", "Bireysel Emeklilik", "Birikim & Yatırım"]
        if let winner = findWinner(for: investExpCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Yatırımcı",
                description: "Geleceği Düşünen",
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .green,
                userId: winner.user,
                relatedCategories: investExpCats
            ))
        }
        
        // 13. Borç Yiğidin Kamçısı (Debt Payments)
        let debtCats = ["Borç Ödeme", "Kredi Kartı", "Kredi", "Borç & Finansal Ödemeler"]
        if let winner = findWinner(for: debtCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Sadık",
                description: "Borcunu Bilir",
                icon: "signature",
                color: .gray,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .gray,
                userId: winner.user,
                relatedCategories: debtCats
            ))
        }
        
        // 14. Gamer (Subcategories)
        let gameCats = ["PlayStation Plus", "Xbox Game Pass", "Nintendo Switch Online", "Steam (EA Play vb.)", "Twitch (Sub)", "Hobi / Oyun / Oyuncak"]
        if let winner = findWinner(for: gameCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Gamer",
                description: "Oyun Dünyası",
                icon: "gamecontroller.fill",
                color: .purple,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .purple,
                userId: winner.user,
                relatedCategories: gameCats
            ))
        }
        
        // 15. Kahve Tutkunu
        let coffeeCats = ["Kafe / Kahve", "Starbucks", "Kahve"]
        if let winner = findWinner(for: coffeeCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Kahve Tutkunu",
                description: "Kafeinsiz Yapamaz",
                icon: "cup.and.saucer.fill",
                color: .brown,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .brown,
                userId: winner.user,
                relatedCategories: coffeeCats
            ))
        }
        
        // 16. Dekoratör
        let decorCats = ["Mobilya / Dekorasyon", "Ev Bakım / Tamirat", "Bahçe / Balkon Bakımı"]
        if let winner = findWinner(for: decorCats) {
             newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Dekoratör",
                description: "Evim Güzel Evim",
                icon: "lamp.table.fill",
                color: .orange,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .orange,
                userId: winner.user,
                relatedCategories: decorCats
            ))
        }

        // --- INCOME BADGES ---
        
        // 17. Maaşlı (Salary)
        let salaryCats = ["Maaş", "Kariyer", "Maaş & Kariyer", "Ana Maaş", "Ek Mesai"]
        if let winner = findIncomeWinner(for: salaryCats) {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Profesyonel",
                description: "Emeğinin Karşılığı",
                icon: "briefcase.fill",
                color: .blue,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .blue,
                userId: winner.user,
                relatedCategories: salaryCats
            ))
        }
        
        // 18. Pasif Gelir Kralı
        let passiveCats = ["Yatırım Geliri", "Faiz", "Temettü", "Kira", "Gayrimenkul", "Yatırım & Finansal Gelir", "Konut Kira Geliri"]
        if let winner = findIncomeWinner(for: passiveCats) {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: winner.user),
                title: "Rantçı",
                description: "Para Parayı Çeker",
                icon: "building.2.fill",
                color: .purple,
                keyStat: winner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .purple,
                userId: winner.user,
                relatedCategories: passiveCats
            ))
        }
        
        // 19. Para Babası (Top Earner)
        if let topEarner = findTopEarner() {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: topEarner.user),
                title: "Para Babası",
                description: "En Çok Kazanan",
                icon: "dollarsign.circle.fill",
                color: .green,
                keyStat: topEarner.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .green,
                userId: topEarner.user,
                relatedCategories: []
            ))
        }

        
        // 20. Bonkör (Top Spender)
        if let topSpender = sortedUsers.first {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: topSpender.0),
                title: "Bonkör",
                description: "Eli En Açık",
                icon: "star.fill",
                color: .yellow,
                keyStat: topSpender.1.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .yellow,
                userId: topSpender.0,
                relatedCategories: [] // All categories basically
            ))
        }
        
        // 21. Tutumlu (Lowest Spender - if at least 2 users)
        if sortedUsers.count >= 2, let lowSpender = sortedUsers.last {
            newPersonas.append(MemberPersona(
                username: getFirstName(for: lowSpender.0),
                title: "Tutumlu",
                description: "Ekonomist",
                icon: "leaf.fill",
                color: .green,
                keyStat: lowSpender.1.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                badgeColor: .green,
                userId: lowSpender.0,
                relatedCategories: []
            ))
        }
        
        // Sort
        self.memberPersonas = newPersonas
    }
    private func processDebts() {
        self.totalDebtRemaining = activeDebts.reduce(0) { $0 + $1.remainingAmount }
        
        // Calculate next immediate payments
        self.upcomingDebtPayment = activeDebts.reduce(0) { $0 + $1.installmentAmount }
    }
    
    private func filterTransactionsByTimeRange(_ transactions: [Transaction], range: AnalyticsTimeRange, offset: Int) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate target range start/end
        var components = DateComponents()
        switch range {
        case .week: components.weekOfYear = -offset
        case .month: components.month = -offset
        case .year: components.year = -offset
        case .all: return transactions // No concept of offset for 'All' effectively
        }
        
        guard let targetDate = calendar.date(byAdding: components, to: now) else { return [] }
        
        let startDate: Date
        let endDate: Date
        
        switch range {
        case .week:
            guard let rangeStart = calendar.dateInterval(of: .weekOfYear, for: targetDate)?.start else { return [] }
            guard let rangeEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: rangeStart) else { return [] }
            startDate = rangeStart
            endDate = rangeEnd
            
        case .month:
            guard let rangeStart = calendar.dateInterval(of: .month, for: targetDate)?.start else { return [] }
            guard let rangeEnd = calendar.date(byAdding: .month, value: 1, to: rangeStart) else { return [] }
            startDate = rangeStart
            endDate = rangeEnd
            
        case .year:
            guard let rangeStart = calendar.dateInterval(of: .year, for: targetDate)?.start else { return [] }
            guard let rangeEnd = calendar.date(byAdding: .year, value: 1, to: rangeStart) else { return [] }
            startDate = rangeStart
            endDate = rangeEnd
            
        case .all:
            return transactions
        }
        
        return transactions.filter { $0.date >= startDate && $0.date < endDate }
    }
    
    private func dayCount(for range: AnalyticsTimeRange) -> Int {
        switch range {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .all: return 365 // approximation or total count
        }
    }
    
    func createExportFile(walletId: String) async -> ExportItem? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(allTransactions)
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "Finvo_Export_\(Date().formatted(date: .numeric, time: .omitted)).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            return ExportItem(url: fileURL)
        } catch {
            errorMessage = "Dışa aktarma hatası: \(error.localizedDescription)"
            return nil
        }
    }
    
    // Helper to get transactions for a specific persona
    // Helper to get transactions for a specific persona
    func getTransactions(forMember userId: String, categories: [String]) -> [Transaction] {
        // Use filtered transactions by CURRENT time range
        // Since we are inside the same class, we can call the private helper.
        let filteredByDate = filterTransactionsByTimeRange(allTransactions, range: selectedTimeRange, offset: 0)
        
        return filteredByDate.filter { t in
            // Match against createdBy (UID) if available, otherwise fallback to username logic
            // Ideally 'userId' passed here IS the 'createdBy' UID.
            // But if we only have username in legacy data, we might need to check display maps.
            // However, our new logic passes 'winner.user' which is the username from 'groupedByUser'.
            // groupedByUser keys are 'createdByUsername'.
            // So 'userId' here is actually 'username' from the transaction.
            let isUser = (t.createdByUsername ?? "Bilinmeyen") == userId
            
            let isCategory = categories.isEmpty || 
                             categories.contains(t.categoryName) || 
                             categories.contains(t.subCategoryName)
            
            // Allow income transactions if categories match (e.g. Salary badge)
            // But expense badges only want expenses.
            // Heuristic: If category type is Income, allow income.
             let isIncomeCategory = DefaultCategories.defaults.contains { cat in
                cat.type == .income && (categories.contains(cat.name) || cat.subCategories.contains { sub in categories.contains(sub.name) })
            }
            
            if isIncomeCategory {
                 return isUser && isCategory && t.type == .income
            } else {
                 return isUser && isCategory && t.type == .expense
            }
            
        }.sorted(by: { $0.date > $1.date })
    }
}
