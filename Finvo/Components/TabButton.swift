//
//  TabButton.swift
//  Finvo
//
//  Created by Burak KOÇ on 17.11.2025.
//

import SwiftUI

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    TabButton(icon: "house.fill", title: "Ana Sayfa", isSelected: true) {}
}

