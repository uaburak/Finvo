import SwiftUI

struct DashboardSmartStack: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedIndex: Int
    
    // Config
    @State private var offset: CGFloat = 0
    let spacing: CGFloat = 12
    
    var body: some View {
        GeometryReader { geo in
            let frameHeight = geo.size.height
            
            ZStack {
                // Main Container: Stack with Overlay Indicators
                ZStack(alignment: .trailing) {
                    
                    // Card Stack Container
                    ZStack {
                        // We render BOTH cards always.
                        // Their position depends on 'offset' and 'selectedIndex'.
                        
                        // Card 0
                        viewFor(index: 0)
                            .scaleEffect(scaleFor(index: 0, frameHeight: frameHeight))
                            .offset(y: offsetFor(index: 0, frameHeight: frameHeight))
                            .zIndex(zIndexFor(index: 0))
                        
                        // Card 1
                        viewFor(index: 1)
                            .scaleEffect(scaleFor(index: 1, frameHeight: frameHeight))
                            .offset(y: offsetFor(index: 1, frameHeight: frameHeight))
                            .zIndex(zIndexFor(index: 1))
                            
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation.height
                            }
                            .onEnded { value in
                                let threshold = frameHeight / 3
                                let velocity = value.predictedEndTranslation.height
                                
                                var nextIndex = selectedIndex
                                var finalOffset: CGFloat = 0
                                
                                // Drag UP -> Go Next
                                if offset < -threshold || (offset < 0 && velocity < -frameHeight) {
                                    finalOffset = -frameHeight - spacing // Current moves UP out
                                    nextIndex = (selectedIndex + 1) % 2
                                } 
                                // Drag DOWN -> Go Prev
                                else if offset > threshold || (offset > 0 && velocity > frameHeight) {
                                    finalOffset = frameHeight + spacing // Current moves DOWN out
                                    nextIndex = (selectedIndex - 1 + 2) % 2
                                } else {
                                    // Snap back
                                    finalOffset = 0
                                }
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    offset = finalOffset
                                }
                                
                                if finalOffset != 0 {
                                    triggerHaptic() // Feedback
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        // Reset
                                        selectedIndex = nextIndex
                                        offset = 0 // Instant reset because relative positions update with index
                                    }
                                }
                            }
                    )
                    
                    // Indicators (Floating on right)
                    VStack(spacing: 6) {
                        ForEach(0..<2) { index in
                            Circle()
                                .fill(selectedIndex == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                    }
                    .offset(x: 12) // Push slightly into the gutter/margin
                }
            }
        }
    }
    
    @ViewBuilder
    func viewFor(index: Int) -> some View {
        if index == 0 {
            AssetSummaryCard(viewModel: viewModel)
        } else {
            SavingsGoalCard(viewModel: viewModel)
        }
    }
    
    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func offsetFor(index: Int, frameHeight: CGFloat) -> CGFloat {
        // Core Logic for Infinite Scroll with 2 items
        
        // 1. Calculate logical position relative to selected (-1 for prev, 0 for current, 1 for next)
        var diff = CGFloat(index - selectedIndex)
        
        // 2. Adjust wrapping for "Other" card based on drag direction
        let otherIndex = (selectedIndex + 1) % 2
        
        if index == otherIndex {
            if offset < 0 {
                if diff == -1 { diff = 1 }
            } else if offset > 0 {
                if diff == 1 { diff = -1 }
            } else {
                 if diff == -1 { diff = 1 } 
            }
        }
        
        return (diff * (frameHeight + spacing)) + offset
    }
    
    func scaleFor(index: Int, frameHeight: CGFloat) -> CGFloat {
        let currentRealOffset = offsetFor(index: index, frameHeight: frameHeight)
        let dist = abs(currentRealOffset)
        // Shrink as it moves away. At 0 offset -> 1.0 scale. At full height offset -> 0.8 scale.
        let progress = min(dist / frameHeight, 1.0)
        return 1.0 - (progress * 0.2)
    }

    func zIndexFor(index: Int) -> Double {
        return index == selectedIndex ? 1 : 0
    }
}
