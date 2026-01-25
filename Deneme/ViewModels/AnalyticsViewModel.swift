import Foundation
import Combine
import SwiftUI

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var chartData: [CategoryDouble] = [] // For Pie Chart
    @Published var monthlyData: [MonthDouble] = [] // For Bar Chart
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var exportURL: URL?
    
    // Structs for Charts
    struct CategoryDouble: Identifiable {
        let id = UUID()
        let category: String
        let value: Double
        let color: Color
    }
    
    struct MonthDouble: Identifiable {
        let id = UUID()
        let month: String
        let income: Double
        let expense: Double
    }
    
    private let firestoreService = FirestoreService.shared
    
    func fetchData(walletId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let transactions = try await firestoreService.fetchAllTransactions(walletId: walletId)
            processTransactions(transactions)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func processTransactions(_ transactions: [Transaction]) {
        // 1. Pie Chart Data (Expenses by Category for this month or all time? Let's do All Time for simplicity or filtered. PRD says "Ana kategoriye göre gider dağılımı")
        // Let's filter for expense
        let expenses = transactions.filter { $0.type == .expense }
        
        let groupedByCategory = Dictionary(grouping: expenses, by: { $0.categoryName })
        
        self.chartData = groupedByCategory.map { (key, value) in
            let total = value.reduce(0) { $0 + $1.amount }
            // Find color
            let colorHex = CategoriesData.expenseCategories.first(where: { $0.name == key })?.colorHex ?? "#8E8E93"
            return CategoryDouble(category: key, value: total, color: Color(hex: colorHex))
        }.sorted(by: { $0.value > $1.value })
        
        // 2. Bar Chart Data (Monthly Income vs Expense - Last 6 months)
        // Group by Month
        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: transactions) { transaction -> String in
            let date = transaction.date
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: date)
        }
        
        // We need to sort months chronologically, which is hard with String keys. 
        // Better to use Date components.
        // Simplified approach: iterate backwards 6 months from now.
        
        var tempMonthly: [MonthDouble] = []
        for i in 0..<6 {
            guard let date = calendar.date(byAdding: .month, value: -i, to: Date()) else { continue }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy" // e.g., "Oct 2023"
            let key = formatter.string(from: date)
            
            let monthTransactions = groupedByMonth[key] ?? []
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            tempMonthly.append(MonthDouble(month: key, income: income, expense: expense))
        }
        self.monthlyData = tempMonthly.reversed() // Oldest to newest
    }
    
    func createExportFile(walletId: String) async -> URL? {
        do {
            let transactions = try await firestoreService.fetchAllTransactions(walletId: walletId)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(transactions)
            
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "Finvo_Export_\(Date().formatted(date: .numeric, time: .omitted)).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            return fileURL
        } catch {
            errorMessage = "Dışa aktarma hatası: \(error.localizedDescription)"
            return nil
        }
    }
}
