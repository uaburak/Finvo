//
//  IslemlerView.swift
//  Finvo
//
//  Created by Burak KOÇ on 17.11.2025.
//

import SwiftUI

struct IslemlerView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("İşlemler")
                    .font(.title)
            }
            .navigationTitle("İşlemler")
        }
    }
}

#Preview {
    IslemlerView()
}

