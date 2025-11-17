//
//  EkleButton.swift
//  Finvo
//
//  Created by Burak KOÇ on 17.11.2025.
//

import SwiftUI

struct EkleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    EkleButton {}
}

