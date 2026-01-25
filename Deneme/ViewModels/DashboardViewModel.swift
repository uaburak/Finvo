import Foundation
import Combine
import FirebaseFirestore

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var recentTransactions: [Transaction] = []
    @Published var totalBalance: Double = 0
    @Published var monthlyIncome: Double = 0
    @Published var monthlyExpense: Double = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // No init needed for listening wallets anymore, handled by WalletManager
    
    func refreshDashboard(for wallet: Wallet) async {
        guard let walletId = wallet.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch recent transactions (Limit 5)
            let result = try await firestoreService.fetchTransactions(walletId: walletId, limit: 5)
            self.recentTransactions = result.transactions
            
            // 2. Fetch monthly stats (From start of current month)
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: Date())
            let startOfMonth = calendar.date(from: components) ?? Date()
            
            let stats = try await firestoreService.fetchTransactionStats(walletId: walletId, from: startOfMonth)
            self.monthlyIncome = stats.income
            self.monthlyExpense = stats.expense
            
            // Balance logic might need all-time calc, but for now lets simulate or use stats
            // In a real app, balance might be stored in Wallet document and updated via Cloud Functions.
            // For MVP, we might approximate or fetch all (costly!).
            // User requested "Verified Data Cost Optimized".
            // Let's assume Balance is Income - Expense of *this month* for the dashboard view for now,
            // OR ideally, we should update the 'Wallet' document with a 'currentBalance' field whenever a transaction is added.
            // Since we didn't add 'balance' to Wallet model in Step 1, let's keep it simple:
            // Calculate balance based on visible period or just Show Income vs Expense for now.
            // Let's just calculate net for this month.
            self.totalBalance = self.monthlyIncome - self.monthlyExpense
            
            isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    

}
