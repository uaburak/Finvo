//
//  AnaSayfaView.swift
//  Finvo
//
//  Created by Burak KOÇ on 17.11.2025.
//

import SwiftUI

struct AnaSayfaView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Ana Sayfa")
                    .font(.title)
            }
            .navigationTitle("Bütçe")
        }
    }
}

#Preview {
    AnaSayfaView()
}

