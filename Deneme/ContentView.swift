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
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var walletManager: WalletManager
    
    var body: some View {
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBarView()
                .padding(.horizontal, 20)
                .offset(y: 10)
        }
    }
    
    @ViewBuilder
    func CustomTabBarView() -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                GeometryReader {
                    /// Type 1
                    CustomTabBar(size: $0.size, barTint: .gray.opacity(0.3), activeTab: $activeTab) { tab in
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
                
                ZStack {
                    ForEach(CustomTab.allCases, id: \.rawValue) { tab in
                        Image(systemName: tab.actionSymbol)
                            .font(.system(size: 22, weight: .medium))
                            .blurFade(activeTab == tab)
                    }
                }
                .frame(width: 60, height: 60)
                .glassEffect(.regular.interactive(), in: .capsule)
                .animation(.smooth(duration: 0.55, extraBounce: 0), value: activeTab)
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
