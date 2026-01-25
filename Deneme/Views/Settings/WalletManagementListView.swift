import SwiftUI
import FirebaseAuth

struct WalletManagementListView: View {
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(walletManager.wallets) { wallet in
                NavigationLink(destination: WalletDetailView(initialWallet: wallet)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(wallet.name)
                                .font(.headline)
                            Text(wallet.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if wallet.isOwner(userId: AuthenticationManager.shared.user?.uid ?? "") {
                            Text("Sahibi")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        } else {
                            Text("Üye")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.gray)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Cüzdan Yönetimi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bitti") {
                    dismiss()
                }
            }
        }
    }
}
