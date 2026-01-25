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
        HapticsManager.shared.impact(style: .light)
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
