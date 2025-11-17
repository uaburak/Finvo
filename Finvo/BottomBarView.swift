//
//  BottomBarView.swift
//  Finvo
//
//  Created by Burak KOÇ on 17.11.2025.
//
import SwiftUI

struct BottomBarView: View {
    @State private var selectedTab = 0
    @Binding var detent: PresentationDetent
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack {
                    // İçerik buraya gelecek
                }
            }
            
            HStack(spacing: 0) {
                TabButton(icon: "house.fill", title: "Özet", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(icon: "creditcard.fill", title: "İşlemler", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                EkleButton {
                    withAnimation {
                        detent = .fraction(0.6)
                    }
                }
                
                TabButton(icon: "chart.bar.fill", title: "Analiz", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                
                TabButton(icon: "gearshape.fill", title: "Ayarlar", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
        }
    }
}

#Preview {
    BottomBarView(detent: .constant(.height(80)))
}
