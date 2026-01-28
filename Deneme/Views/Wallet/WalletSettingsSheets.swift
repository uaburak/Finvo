import SwiftUI

struct WalletLimitSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    @State private var limitAmount: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Aylık Harcama Limiti")) {
                    TextField("Tutar", text: $limitAmount)
                        .keyboardType(.decimalPad)
                    
                    Text("Bu limit aşıldığında size bildirim gönderilecektir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Harcama Limiti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveLimit()
                    }
                    .disabled(limitAmount.isEmpty || isLoading)
                }
            }
            .onAppear {
                if let currentLimit = walletManager.selectedWallet?.monthlyLimit {
                    limitAmount = String(format: "%.0f", currentLimit)
                }
            }
        }
    }
    
    private func saveLimit() {
        guard var wallet = walletManager.selectedWallet, let amount = Double(limitAmount) else { return }
        isLoading = true
        
        Task {
            wallet.monthlyLimit = amount
            try? await FirestoreService.shared.updateWallet(wallet)
            
            // Refresh local wallet
            DispatchQueue.main.async {
                walletManager.updateWalletLocally(wallet)
                isLoading = false
                dismiss()
            }
        }
    }
}

struct WalletGoalSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    @State private var goalAmount: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Birikim Hedefi")) {
                    TextField("Tutar", text: $goalAmount)
                        .keyboardType(.decimalPad)
                    
                    Text("Bu hedefe ulaştığınızda tebrik edileceksiniz!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Birikim Hedefi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveGoal()
                    }
                    .disabled(goalAmount.isEmpty || isLoading)
                }
            }
            .onAppear {
                if let currentGoal = walletManager.selectedWallet?.savingsGoal {
                    goalAmount = String(format: "%.0f", currentGoal)
                }
            }
        }
    }
    
    private func saveGoal() {
        guard var wallet = walletManager.selectedWallet, let amount = Double(goalAmount) else { return }
        isLoading = true
        
        Task {
            wallet.savingsGoal = amount
            try? await FirestoreService.shared.updateWallet(wallet)
            
            // Refresh local wallet
            DispatchQueue.main.async {
                walletManager.updateWalletLocally(wallet)
                isLoading = false
                dismiss()
            }
        }
    }
}
