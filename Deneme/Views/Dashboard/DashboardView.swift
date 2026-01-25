import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var walletManager: WalletManager
    
    @State private var showCreateWallet = false
    @State private var showAddTransaction = false
    @State private var showManageWallets = false
    @State private var showPermissionAlert = false
    @State private var showRequestSentAlert = false
    @State private var loadedWalletId: String?
    
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
                    // Context-Aware Content
                    if let wallet = walletManager.selectedWallet {
                        switch wallet.context {
                        case .budget:
                            BudgetDashboardView(viewModel: viewModel)
                        case .todo:
                            // Should theoretically be handled by MainTabView but for consistency if loaded here:
                             Text("To-Do Modu: Tab değişimini kontrol et.")
                        case .savings:
                            SavingsDashboardView(viewModel: viewModel)
                        case .travel:
                            TravelDashboardView(viewModel: viewModel)
                        }
                    }
                }
            }
            .toolbar {
                // Leading: Notifications
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell.badge")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.red, .primary)
                    }
                }
                
                // Principal: Wallet Selector
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
                        
                        Button {
                            showManageWallets = true
                        } label: {
                            Label("Cüzdanları Yönet", systemImage: "list.bullet.rectangle.portrait")
                        }
                        
                    } label: {
                        HStack(spacing: 4) {
                            Text(walletManager.selectedWallet?.name ?? "Cüzdan Seç")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Trailing: Profile (Settings)
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        if let photoURL = authManager.user?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray)
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
                        if let wallet = walletManager.selectedWallet, let uid = authManager.user?.uid {
                            if wallet.canEdit(userId: uid) {
                                showAddTransaction = true
                            } else {
                                showPermissionAlert = true
                            }
                        }
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
            .alert("Yetkiniz Yok", isPresented: $showPermissionAlert) {
                Button("Yetki İste") {
                     Task { await requestPermission() }
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Bu cüzdanda işlem yapabilmek için 'Düzenleyici' yetkisine ihtiyacınız var. Cüzdan sahibinden yetki isteyebilirsiniz.")
            }
            .alert("İstek Gönderildi", isPresented: $showRequestSentAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Yetki isteğiniz cüzdan sahibine iletildi.")
            }
            .sheet(isPresented: $showCreateWallet) {
                CreateWalletView()
            }
            .sheet(isPresented: $showManageWallets) {
                NavigationStack {
                    WalletManagementListView()
                }
            }
            .onAppear {
                if let uid = authManager.user?.uid {
                    FirestoreService.shared.startListeningWallets(forUser: uid)
                }
                // Initial load only if needed
                if let wallet = walletManager.selectedWallet {
                    if loadedWalletId != wallet.id {
                        loadedWalletId = wallet.id
                        Task { await viewModel.refreshDashboard(for: wallet) }
                    }
                }
            }
            .onChange(of: walletManager.selectedWallet) { _, newWallet in
                if let wallet = newWallet {
                    loadedWalletId = wallet.id
                    Task { await viewModel.refreshDashboard(for: wallet) }
                }
            }
        }
    }
    func requestPermission() async {
        guard let wallet = walletManager.selectedWallet, 
              let user = AuthenticationManager.shared.currentUserProfile ?? 
                         (authManager.user == nil ? nil : User(uid: authManager.user!.uid, email: "", username: authManager.user?.displayName ?? "User", isPro: false))
        else { return }
        
        do {
            try await FirestoreService.shared.sendPermissionRequest(wallet: wallet, fromUser: user)
            print("DEBUG: Request sent successfully")
            showPermissionAlert = false
            showRequestSentAlert = true
        } catch {
            print("Yetki isteği gönderilemedi: \(error)")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(WalletManager.shared)
}
