import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var walletManager: WalletManager
    
    @State private var showCreateWallet = false
    @State private var showAddTransaction = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // If no wallet is selected (and not loading), show empty state
                if walletManager.selectedWallet == nil && !viewModel.isLoading {
                    VStack(spacing: 20) {
                        Spacer(minLength: 50)
                        Image(systemName: "wallet.pass")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Henüz bir cüzdanın yok.")
                            .font(.title2)
                        Button("Cüzdan Oluştur") {
                            showCreateWallet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 24) {
                        // Header Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Toplam Varlık")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("₺\(viewModel.totalBalance, specifier: "%.2f")")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                // Wallet Selector Placeholder
                                if let wallet = walletManager.selectedWallet {
                                    Text(wallet.name)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                    
                                    // Settings Button
                                    NavigationLink(destination: WalletSettingsView(viewModel: WalletSettingsViewModel(wallet: wallet))) {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Gelir")
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Text("₺\(viewModel.monthlyIncome, specifier: "%.2f")")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    HStack {
                                        Text("Gider")
                                            .foregroundColor(.white.opacity(0.8))
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    Text("₺\(viewModel.monthlyExpense, specifier: "%.2f")")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // Recent Transactions
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Son İşlemler")
                                    .font(.headline)
                                Spacer()
                                // Navigation to full list would go here or via TabView
                            }
                            .padding(.horizontal)
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else if viewModel.recentTransactions.isEmpty {
                                Text("Henüz işlem yok")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(viewModel.recentTransactions) { transaction in
                                    TransactionRow(transaction: transaction)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
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
            // Remove old overlay for FAB to avoid conflict or keep it? Keep it.
            // But remove the CreateWallet from overlay logic if handled in toolbar? 
            // The empty state handled create wallet, this toolbar handles switching.
            .overlay(alignment: .bottomTrailing) {
                // Show FAB only if wallet exists
                if walletManager.selectedWallet != nil {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4, x: 0, y: 4)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                 if let wallet = walletManager.selectedWallet, let walletId = wallet.id {
                     AddTransactionView(walletId: walletId)
                 } else {
                    Text("Lütfen önce bir cüzdan oluşturun.")
                 }
            }
            .sheet(isPresented: $showCreateWallet) {
                CreateWalletView()
            }
            .onAppear {
                if let uid = authManager.user?.uid {
                    FirestoreService.shared.startListeningWallets(forUser: uid)
                }
                // Initial load
                if let wallet = walletManager.selectedWallet {
                    Task { await viewModel.refreshDashboard(for: wallet) }
                }
            }
            .onChange(of: walletManager.selectedWallet) { newWallet in
                if let wallet = newWallet {
                    Task { await viewModel.refreshDashboard(for: wallet) }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(WalletManager.shared)
}
