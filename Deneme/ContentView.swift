//
//  ContentView.swift
//  CustomGlassTabBar
//
//  Created by Balaji Venkatesh on 28/09/25.
//

import SwiftUI

/// Tab Items!
enum CustomTab: String, CaseIterable {
    case dashboard = "Özet"
    case analytics = "Analiz"
    case settings = "Ayarlar"
    
    var symbol: String {
        switch self {
        case .dashboard: return "house"
        case .analytics: return "chart.pie"
        case .settings: return "gearshape"
        }
    }
    
    var actionSymbol: String {
        switch self {
        case .dashboard: return "house.fill"
        case .analytics: return "chart.pie.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

struct ContentView: View {
    @State private var activeTab: CustomTab = .dashboard
    @State private var showAddTransaction = false
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var walletManager: WalletManager
    @AppStorage("isOnboardingSeen") var isOnboardingSeen: Bool = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.isProfileComplete {
                    customTabBarView
                } else {
                    ExtendedOnboardingView()
                }
            } else {
                if isOnboardingSeen {
                    LoginView()
                } else {
                    OnboardingView()
                }
            }
        }
        .animation(.default, value: authManager.isAuthenticated)
        .animation(.default, value: authManager.isProfileComplete)
    }
    
    @ViewBuilder
    var customTabBarView: some View {
        TabView(selection: $activeTab) {
            Tab.init(value: .dashboard) {
                DashboardView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            
            Tab.init(value: .analytics) {
                AnalyticsView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            
            Tab.init(value: .settings) {
                SettingsView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .safeAreaBar(edge: .bottom, spacing: 0) {
            CustomTabBarView()
                .padding(.horizontal, 16)
                .offset(y: 14)
        }
        .sheet(isPresented: $showAddTransaction) {
            if let wallet = walletManager.selectedWallet, let walletId = wallet.id {
                AddTransactionView(walletId: walletId)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "wallet.pass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Lütfen önce bir cüzdan oluşturun.")
                        .foregroundColor(.secondary)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    @ViewBuilder
    func CustomTabBarView() -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                GeometryReader {
                    CustomTabBar(size: $0.size, barTint: .gray.opacity(0.2), activeTab: $activeTab) { tab in
                        VStack(spacing: 3) {
                            Image(systemName: tab.symbol)
                                .font(.title3)
                            
                            Text(tab.rawValue)
                                .font(.system(size: 10))
                                .fontWeight(.medium)
                        }
                        .symbolVariant(.fill)
                        .frame(maxWidth: .infinity)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                
                // Add Button
                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(.tint)
                )
                .glassEffect(.regular.interactive(), in: .capsule)
            }
        }
        .frame(height: 60)
    }
}

/// Blur Fade In/Out
extension View {
    @ViewBuilder
    func blurFade(_ status: Bool) -> some View {
        self
            .compositingGroup()
            .blur(radius: status ? 0 : 10)
            .opacity(status ? 1 : 0)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(WalletManager.shared)
}
