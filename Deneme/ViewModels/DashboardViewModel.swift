import Foundation
import Combine
import FirebaseFirestore
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var recentTransactions: [Transaction] = []
    @Published var totalBalance: Double = 0
    @Published var monthlyIncome: Double = 0
    @Published var monthlyExpense: Double = 0
    
    // Debt Stats
    @Published var activeDebts: [Debt] = []
    @Published var totalDebtRemaining: Double = 0
    @Published var upcomingDebtPayment: Double = 0
    
    @Published var savingsBalance: Double = 0 // Tracks accumulated savings
    
    // Limits & Goals
    @Published var savingsGoal: Double?
    @Published var monthlyLimit: Double?
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var debugInfo: String = "Yükleniyor..." // Debug
    
    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for new transactions (Optimistic Update)
        NotificationCenter.default.publisher(for: .transactionAdded)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self = self, let transaction = notification.object as? Transaction else { return }
                self.handleNewTransaction(transaction)
            }
            .store(in: &cancellables)
    }
    
    private func handleNewTransaction(_ transaction: Transaction) {
        // 1. Add to recent list
        self.recentTransactions.insert(transaction, at: 0)
        if self.recentTransactions.count > 5 {
            self.recentTransactions.removeLast()
        }
        
        // 2. Update Stats (Simple addition for current month logic)
        // Check if transaction is in current month? 
        // For MVP simplicity, assume "Add" happens mostly for "Now", so yes.
        if transaction.type == .income {
            self.monthlyIncome += transaction.amount
            // Optimistic update for savings withdrawal
            if transaction.subCategoryName.localizedCaseInsensitiveContains("Birikim") || 
               transaction.subCategoryName.localizedCaseInsensitiveContains("Bozdurma") {
                self.savingsBalance = max(0, self.savingsBalance - transaction.amount)
            }
        } else {
            self.monthlyExpense += transaction.amount
            // Optimistic update for savings deposit
            if transaction.categoryName.localizedCaseInsensitiveContains("Birikim") || 
               transaction.categoryName.localizedCaseInsensitiveContains("Yatırım") {
                self.savingsBalance += transaction.amount
            }
        }
        
        // 3. Update Balance
        // If balance is net for month:
        self.totalBalance = self.monthlyIncome - self.monthlyExpense
    }
    
    func refreshDashboard(for wallet: Wallet) async {
        guard let walletId = wallet.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Reset data immediately to prevent showing previous wallet's data while loading
        self.recentTransactions = []
        self.totalBalance = 0
        self.monthlyIncome = 0
        self.monthlyExpense = 0
        self.savingsGoal = wallet.savingsGoal
        self.monthlyLimit = wallet.monthlyLimit
        
        do {
            // 1. Fetch recent transactions (Limit 5)
            let result = try await firestoreService.fetchTransactions(walletId: walletId, limit: 5)
            self.recentTransactions = result.transactions
            
            // 2. Fetch monthly stats (From start of current month)
            // Note: For Savings Balance, we ideally need ALL TIME savings. 
            // Or if we track monthly flow, it's monthly.
            // Requirement says "Savings Account". Usually an account balance is all time.
            // Let's check fetchTransactionStats. It returns income/expense sum.
            // To get specific category sum, we might need a new query or filter fetched transactions.
            // Since we only fetch 5 recent transactions here, we can't calculate total savings from them.
            // For MVP/Prototype without backend aggregation, we have to fetch ALL transactions or use a dedicated collection method.
            // Assuming for now we calculate from "stats" isn't enough because stats are aggregate.
            // Let's add a specialized fetch for savings sum.
            // "firestoreService.fetchTotalSavings(walletId: walletId)" -> We might need to implement this or simulate.
            // Let's simulate by fetching all transactions for now (WARNING: Costly in prod) or better, 
            // just depend on a `wallet.currentSavings` field if it existed. 
            // Since we can't change the backend easily, let's fetch transactions (limit 100 for now?) or use a specific query.
            // Let's look at `FirestoreService`.
            
            // Re-evaluating: The user wants "Asset = Income - Expense". "Savings = Savings Expenses".
            // If we only have monthly stats, we can't show total asset accurately either if it's all time.
            // Assuming the `monthlyIncome` / `monthlyExpense` variables are actually used for "This Month" view.
            
            // Let's add `savingsBalance` calculation based on a new Service call or logic.
            // I'll assume I can calculate it from a new fetch or existing.
            // Attempting to calculate savings from recent is wrong.
            // I will add a helper to fetch accumulated savings based on category name "Birikim".
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: Date())
            
            // Calculate Savings Balance with new robust fetch
            let savingsResult = try await firestoreService.fetchSavingsBalance(walletId: walletId)
            self.savingsBalance = savingsResult.balance
            self.debugInfo = savingsResult.debugInfo // Show on UI
            
            let startOfMonth = calendar.date(from: components) ?? Date()
            
            let stats = try await firestoreService.fetchTransactionStats(walletId: walletId, from: startOfMonth)
            self.monthlyIncome = stats.income
            self.monthlyExpense = stats.expense
            
            // 3. Fetch Active Debts
            self.activeDebts = try await firestoreService.fetchActiveDebts(walletId: walletId)
            self.totalDebtRemaining = self.activeDebts.reduce(0) { $0 + $1.remainingAmount }
            self.upcomingDebtPayment = self.activeDebts.reduce(0) { $0 + $1.installmentAmount }
            
            // Balance logic: User said "Asset" shouldn't show savings.
            // If Savings are recorded as Expenses, then Net (Income - Expense) already excludes them.
            // So `totalBalance` = `monthlyIncome` - `monthlyExpense` produces what they asked for (Liquid).
            // (Assuming `monthlyExpense` includes the savings transfer).
            // Yes, if we record it as expense, it is included in `stats.expense`.
            self.totalBalance = self.monthlyIncome - self.monthlyExpense
            
            isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Configuration
    struct QuickActionItem: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let color: Color
        let actionType: DashboardActionType
    }
    
    enum DashboardActionType: String {
        case debts = "OpenDebts"
        case limit = "OpenSpendingLimit"
        case categories = "OpenCategories"
        case wallets = "OpenWalletManagement"
        case reports = "OpenReports"
        case subscriptions = "OpenSubscriptions"
        case investments = "OpenInvestments"
    }
    
    let quickActions: [QuickActionItem] = [
        QuickActionItem(icon: "creditcard.fill", label: "Borçlar", color: .orange, actionType: .debts),
        QuickActionItem(icon: "gauge.medium", label: "Limitler", color: .purple, actionType: .limit),
        QuickActionItem(icon: "square.grid.2x2.fill", label: "Kategoriler", color: .blue, actionType: .categories),
        QuickActionItem(icon: "wallet.pass.fill", label: "Cüzdanlar", color: .gray, actionType: .wallets),
        QuickActionItem(icon: "chart.pie.fill", label: "Raporlar", color: .pink, actionType: .reports),
        QuickActionItem(icon: "arrow.triangle.2.circlepath", label: "Abonelik", color: .indigo, actionType: .subscriptions),
        QuickActionItem(icon: "leaf.fill", label: "Yatırım", color: .green, actionType: .investments)
    ]
}
