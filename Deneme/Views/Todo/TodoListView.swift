import SwiftUI

struct TodoListView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var showCreateWallet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let wallet = walletManager.selectedWallet {
                    Text("\(wallet.name) - Yapılacaklar Listesi")
                        .font(.headline)
                        .padding()
                    Text("Bu özellik geliştirme aşamasındadır.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("Cüzdan seçilmedi")
                        .padding()
                }
                Spacer()
            }
            .navigationTitle("To-Do")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Menu {
                        ForEach(walletManager.wallets) { wallet in
                            Button {
                                walletManager.selectWallet(wallet)
                            } label: {
                                HStack {
                                    Text(wallet.name)
                                    if walletManager.selectedWallet?.id == wallet.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            showCreateWallet = true
                        } label: {
                            Label("Yeni Cüzdan Oluştur", systemImage: "plus.circle")
                        }
                        
                    } label: {
                        HStack {
                            Text(walletManager.selectedWallet?.name ?? "Cüzdan Seç")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateWallet) {
                CreateWalletView()
            }
        }
    }
}

#Preview {
    TodoListView()
        .environmentObject(WalletManager.shared)
}
