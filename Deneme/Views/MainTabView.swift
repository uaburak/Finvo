import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var walletManager = WalletManager.shared
    
    var body: some View {
        TabView {
            // Context Switching Logic
            if let wallet = walletManager.selectedWallet, wallet.context == .todo {
                // --- To-Do Context ---
                TodoListView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("To-Do", systemImage: "checkmark.circle.fill")
                    }
                
            } else {
                // --- Budget Context (Default) ---
                DashboardView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("Özet", systemImage: "chart.pie.fill")
                    }
                
                TransactionListView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("İşlemler", systemImage: "list.bullet")
                    }
                
                AnalyticsView()
                    .environmentObject(walletManager)
                    .tabItem {
                        Label("Analiz", systemImage: "chart.bar.xaxis")
                    }
                
                CategoriesView()
                    .tabItem {
                        Label("Kategoriler", systemImage: "square.grid.2x2.fill")
                    }
                
                TestView()
                    .tabItem {
                        Label("Test", systemImage: "hammer.fill")
                    }
            }
            

            
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager.shared)
}
