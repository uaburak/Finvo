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
    }

    private func processDebts() {
        self.totalDebtRemaining = activeDebts.reduce(0) { $0 + $1.remainingAmount }
        
        // Calculate next immediate payments (e.g. sum of all installment amounts for active debts)
        // Or specific logic: Next payment needed within current month?
        // Let's just sum installment amounts of active debts for now as "Monthly Debt Load"
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
}
