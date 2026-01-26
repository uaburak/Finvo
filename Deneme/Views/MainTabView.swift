import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var walletManager = WalletManager.shared
    
    @StateObject private var tabManager = TabManager()
    
    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            // Context Switching Logic
            if let wallet = walletManager.selectedWallet, wallet.context == .todo {
                // --- To-Do Context ---
                TodoListView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("To-Do", systemImage: "checkmark.circle.fill")
                    }
                    .tag(TabManager.dashboard)
                
            } else {
                // --- Budget Context (Default) ---
                DashboardView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("Özet", systemImage: "chart.pie.fill")
                    }
                    .tag(TabManager.dashboard)
                
                TransactionListView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("İşlemler", systemImage: "list.bullet")
                    }
                    .tag(TabManager.transactions)
                
                AnalyticsView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("Analiz", systemImage: "chart.bar.xaxis")
                    }
                    .tag(TabManager.analytics)
                
                CategoriesView()
                    .environmentObject(tabManager) // Inject for use in child view
                    .tabItem {
                        Label("Kategoriler", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(TabManager.categories)
                
            }
            

            
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
                .tag(TabManager.settings)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager.shared)
}
