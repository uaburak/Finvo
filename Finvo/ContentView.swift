//
//  ContentView.swift
//  Finvo
//
//  Created by Burak KOÇ on 17.11.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showBottomBar :Bool = true
    @State private var selection: PresentationDetent = .height(80)
    
    var body: some View {
        ZStack {
            Color(.systemBackground)    // Arka plan
                .ignoresSafeArea()
            
            Text("Map yerine boş ekran")   // Buraya istediğin UI gelecek
                .font(.title)
        }
        .sheet(isPresented: $showBottomBar) {
            BottomBarView(detent: $selection)
                .padding(.vertical, 24)
                .presentationDetents(
                    [.height(80), .fraction(0.6), .large],
                    selection: $selection
                )
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    ContentView()
}
