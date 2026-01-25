import Foundation
import Combine
import FirebaseAuth
import UIKit

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
                    // Check persistence first
                    if let lastId = UserDefaults.standard.string(forKey: "lastSelectedWalletId"),
                       let persistedWallet = wallets.first(where: { $0.id == lastId }) {
                        self.selectedWallet = persistedWallet
                    } else {
                        // No specific selection or not found, select first
                        self.selectedWallet = wallets.first
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func selectWallet(_ wallet: Wallet) {
        if selectedWallet?.id != wallet.id {
            HapticsManager.shared.impact(style: .medium)
            self.selectedWallet = wallet
            // Persistence
            if let id = wallet.id {
                UserDefaults.standard.set(id, forKey: "lastSelectedWalletId")
            }
        }
    }
    
    func removeWallet(id: String) {
        // Optimistically remove from list
        if let index = wallets.firstIndex(where: { $0.id == id }) {
            wallets.remove(at: index)
        }
        
        // If the removed wallet was selected, select another one
        if selectedWallet?.id == id {
            self.selectedWallet = wallets.first
            // Clear persistence if empty
            if self.selectedWallet == nil {
                UserDefaults.standard.removeObject(forKey: "lastSelectedWalletId")
            } else if let newId = self.selectedWallet?.id {
                UserDefaults.standard.set(newId, forKey: "lastSelectedWalletId")
            }
        }
    }
}
