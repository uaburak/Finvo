//
//  AyarlarView.swift
//  Finvo
//
//  Created by Burak KOÇ on 17.11.2025.
//

import SwiftUI

struct AyarlarView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Ayarlar")
                    .font(.title)
            }
            .navigationTitle("Ayarlar")
        }
    }
}

#Preview {
    AyarlarView()
}

