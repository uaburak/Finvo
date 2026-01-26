import Foundation
import Combine

@MainActor
class ReportsViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // For Creating Report
    @Published var selectedRange: ReportRangeType = .month
    
    private let firestoreService = FirestoreService.shared
    
    func fetchReports(walletId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            self.reports = try await firestoreService.fetchReports(walletId: walletId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func createSnapshot(wallet: Wallet, range: ReportRangeType) async -> Bool {
        guard let walletId = wallet.id, let userId = wallet.members.first else { return false } // Simplified owner check
        
        isLoading = true
        
        // 1. Determine Date Range
        let endDate = Date()
        let startDate: Date
        let calendar = Calendar.current
        
        switch range {
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .custom:
            startDate = endDate // Logic for custom can be expanded
        }
        
        do {
            // 2. Fetch Data filtered by range
            let transactions = try await firestoreService.fetchTransactions(walletId: walletId, startDate: startDate, endDate: endDate)
            
            // 3. Calculate Stats
            let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            // Category Breakdown
            let expenses = transactions.filter { $0.type == .expense }
            let categoryBreakdown = Dictionary(grouping: expenses, by: { $0.categoryName })
                .mapValues { $0.reduce(0) { $0 + $1.amount } }
            
            // Member Breakdown (if shared)
            var memberBreakdown: [String: Double]? = nil
            if wallet.type == .shared {
                memberBreakdown = Dictionary(grouping: expenses, by: { $0.createdByUsername ?? "Unknown" })
                    .mapValues { $0.reduce(0) { $0 + $1.amount } }
            }
            
            // 4. Create Report Object
            let report = Report(
                walletId: walletId,
                createdBy: userId,
                createdAt: Date(),
                rangeType: range,
                startDate: startDate,
                endDate: endDate,
                totalIncome: income,
                totalExpense: expense,
                categoryBreakdown: categoryBreakdown,
                memberBreakdown: memberBreakdown
            )
            
            // 5. Save
            try await firestoreService.saveReport(report)
            
            // Optimistic Update
            self.reports.insert(report, at: 0)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Rapor oluşturulamadı: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
