import Foundation
import FirebaseFirestore
import Combine

@MainActor
class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var filterType: TransactionType? = nil // nil = All
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var walletId: String?
    private var lastDocument: DocumentSnapshot?
    private let firestoreService = FirestoreService.shared
    private var hasMoreData: Bool = true
    
    func loadInitialData(walletId: String) async {
        self.walletId = walletId
        self.transactions = []
        self.lastDocument = nil
        self.hasMoreData = true
        await fetchNextPage()
    }
    
    func fetchNextPage() async {
        guard let walletId = walletId, !isLoading, hasMoreData else { return }
        
        isLoading = true
        do {
            // Note: firestoreService.fetchTransactions needs to support filtering or we filter clientside?
            // PRD: "Firestore kurallarını okuma maliyetlerini minimize edecek şekilde tasarla"
            // Filtering server-side is better. We need to update FirestoreService or just filter locally if dataset is small.
            // For now, let's update FirestoreService to support type filter or just fetch all and filter client side (less efficient).
            // Let's update FirestoreService signature to accept type filter.
            let result = try await firestoreService.fetchTransactions(walletId: walletId, limit: 20, lastDoc: lastDocument, type: filterType)
            
            if result.transactions.isEmpty {
                hasMoreData = false
            } else {
                self.transactions.append(contentsOf: result.transactions)
                self.lastDocument = result.lastDoc
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        guard let walletId = walletId else { return }
        self.transactions = []
        self.lastDocument = nil
        self.hasMoreData = true
        await fetchNextPage()
    }
    
    func updateFilter(_ type: TransactionType?) {
        self.filterType = type
        Task { await refresh() }
    }
}
