import Foundation
import Combine
import FirebaseAuth

@MainActor
class WalletManager: ObservableObject {
    @Published var selectedWallet: Wallet?
    @Published var wallets: [Wallet] = []
    
    static let shared = WalletManager()
    
    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen to FirestoreService wallets updates
        firestoreService.$wallets
            .receive(on: RunLoop.main)
            .sink { [weak self] wallets in
                guard let self = self else { return }
                self.wallets = wallets
                
                // Logic to maintain selected wallet or select default
                if let selected = self.selectedWallet {
                    // Refresh selected wallet data from list if exists
                    if let updated = wallets.first(where: { $0.id == selected.id }) {
                        self.selectedWallet = updated
                    } else {
                        // Selected wallet removed? Select first.
                        self.selectedWallet = wallets.first
                    }
                } else {
                    // No selection, select first
                    self.selectedWallet = wallets.first
                }
            }
            .store(in: &cancellables)
    }
    
    func selectWallet(_ wallet: Wallet) {
        self.selectedWallet = wallet
    }
}
