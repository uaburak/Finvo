import Foundation
import FirebaseFirestore
import Combine

@MainActor
class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var filterType: TransactionType? = nil // nil = All
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var allTransactions: [Transaction] = [] // Raw data
    private var listener: ListenerRegistration?
    private let firestoreService = FirestoreService.shared
    
    @Published var searchText: String = "" {
        didSet {
            applyFilter()
        }
    }
    
    // Load & Listen (Real-time)
    func loadInitialData(for wallet: Wallet) {
        guard let walletId = wallet.id else { return }
        
        isLoading = true
        
        // Remove existing listener if changing wallets
        listener?.remove()
        
        listener = firestoreService.listenToTransactions(walletId: walletId, limit: 100) { [weak self] newTransactions in
            guard let self = self else { return }
            self.allTransactions = newTransactions
            self.applyFilter()
            self.isLoading = false
        }
    }
    
    // Pure Local Filter
    func updateFilter(_ type: TransactionType?) {
        // HapticsManager.shared.impact(style: .light) // Disabled per user request
        self.filterType = type
        applyFilter()
    }
    
    private func applyFilter() {
        var filtered = allTransactions
        
        // 1. Type Filter
        if let type = filterType {
            filtered = filtered.filter { $0.type == type }
        }
        
        // 2. Search Text Filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filtered = filtered.filter { transaction in
                let categoryMatch = transaction.categoryName.lowercased().contains(lowercasedSearch)
                let subCategoryMatch = transaction.subCategoryName.lowercased().contains(lowercasedSearch)
                let noteMatch = (transaction.note ?? "").lowercased().contains(lowercasedSearch)
                let amountMatch = String(transaction.amount).contains(lowercasedSearch)
                let userMatch = (transaction.createdByUsername ?? "").lowercased().contains(lowercasedSearch)
                
                return categoryMatch || subCategoryMatch || noteMatch || amountMatch || userMatch
            }
        }
        
        self.transactions = filtered
    }
    
    func deleteTransaction(_ transaction: Transaction, walletId: String) async {
        guard let id = transaction.id else { return }
        do {
            // Check if this is a debt creation transaction
            // Logic: Has linkedDebtId AND is created by a real user (not "Sistem")
            // OR even simpler: If it has linkedDebtId and is NOT a recurring installment child (parentTransactionId == nil)
            // But wait, the installation transactions also have linkedDebtId? Yes.
            // But usually the user wants to cancel the debt if they delete the FIRST transaction.
            // If they delete an installment, they just delete that payment record?
            // The user said "I added a debt and deleted the transaction". This implies the creation logic.
            
            if let debtId = transaction.linkedDebtId {
                // Determine if this is the "Mother" transaction of the debt
                // In DebtAutomationService, createdByUsername is "Sistem" for installments.
                // In AddTransactionViewModel, it is the user's username.
                // Also, installments have 'isRecurring = true' but the mother transaction might not?
                // Actually, mother transaction has isRecurring = false usually? No, AddTransactionViewModel sets isRecurring=false for debt?
                // Let's check AddTransactionViewModel:
                // recurrenceFrequency: isDebt ? debtFrequency : ...
                // But isRecurring param in Transaction init?
                // isRecurring: isRecurring (which is false for Debt wizard usually unless user toggled it?)
                // Actually, for Debt, isRecurring is NOT set to true in AddTransactionViewModel unless the user explicitly checks the toggle effectively?
                // Wait, "Tekrarlayan İşlem" toggle is separate from "Borç".
                // If I add a Debt, isRecurring is false (default).
                // So the mother transaction has isRecurring = false (usually) and createdBy != "Sistem".
                
                // Safe check: If NOT created by "Sistem", we assume it's the main entry.
                // Or checking parentTransactionId == nil.
                
                let isSystem = transaction.createdByUsername == "Sistem"
                if !isSystem {
                    print("🗑️ Deleting linked debt: \(debtId)")
                    try await firestoreService.deleteDebt(walletId: walletId, debtId: debtId)
                } else {
                    // It is a system transaction (Installment)
                    // We should rollback the debt progress
                    print("🔄 Rolling back debt installment: \(debtId)")
                    try await firestoreService.rollbackDebtInstallment(walletId: walletId, debtId: debtId, amount: transaction.amount)
                }
            }
            
            try await firestoreService.deleteTransaction(walletId: walletId, transactionId: id)
            // Listener will automatically update 'allTransactions'
        } catch {
            self.errorMessage = "Silme hatası: \(error.localizedDescription)"
        }
    }
    
    // Refresh isn't strictly needed with a listener, but can remain if we want to force re-attach
    func refresh(for wallet: Wallet) async {
       loadInitialData(for: wallet)
    }
    
    // Pagination is tricky with simple listeners. 
    // For now, we fetch a larger chunk (100) to cover most use cases.
    func fetchNextPage() async {
        // Feature temporarily disabled in favor of real-time stability
    }
    
    deinit {
        listener?.remove()
    }
}
