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
        if let type = filterType {
            self.transactions = allTransactions.filter { $0.type == type }
        } else {
            self.transactions = allTransactions
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
