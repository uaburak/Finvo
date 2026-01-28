import SwiftUI

extension View {
    /// Applies a glass effect (blur material) clipped to the specified shape.
    /// Usage: .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    func glassEffect<S: Shape>(in shape: S) -> some View {
        self
            .background(.regularMaterial) // Or .ultraThinMaterial based on preference
            .clipShape(shape)
    }
}
