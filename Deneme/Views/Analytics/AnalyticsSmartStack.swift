import SwiftUI

struct AnalyticsSmartStack: View {
    @ObservedObject var viewModel: AnalyticsViewModel
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
                        // Card 0: Net Balance
                        viewFor(index: 0)
                            .scaleEffect(scaleFor(index: 0, frameHeight: frameHeight))
                            .offset(y: offsetFor(index: 0, frameHeight: frameHeight))
                            .zIndex(zIndexFor(index: 0))
                        
                        // Card 1: Monthly Pulse
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
                                    finalOffset = -frameHeight - spacing
                                    nextIndex = (selectedIndex + 1) % 2
                                } 
                                // Drag DOWN -> Go Prev
                                else if offset > threshold || (offset > 0 && velocity > frameHeight) {
                                    finalOffset = frameHeight + spacing
                                    nextIndex = (selectedIndex - 1 + 2) % 2
                                } else {
                                    finalOffset = 0
                                }
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    offset = finalOffset
                                }
                                
                                if finalOffset != 0 {
                                    triggerHaptic()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        selectedIndex = nextIndex
                                        offset = 0
                                    }
                                }
                            }
                    )
                    
                    // Indicators
                    VStack(spacing: 6) {
                        ForEach(0..<2) { index in
                            Circle()
                                .fill(selectedIndex == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                    }
                    .offset(x: 12)
                }
            }
        }
    }
    
    @ViewBuilder
    func viewFor(index: Int) -> some View {
        if index == 0 {
            AnalyticsNetBalanceCard(viewModel: viewModel)
        } else {
            AnalyticsMonthlyPulseCard(viewModel: viewModel)
        }
    }
    
    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func offsetFor(index: Int, frameHeight: CGFloat) -> CGFloat {
        var diff = CGFloat(index - selectedIndex)
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
        let progress = min(dist / frameHeight, 1.0)
        return 1.0 - (progress * 0.2)
    }

    func zIndexFor(index: Int) -> Double {
        return index == selectedIndex ? 1 : 0
    }
}

// MARK: - Sub Cards

struct AnalyticsNetBalanceCard: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "building.columns.fill")
                        .font(.caption)
                    Text("Net Durum")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white.opacity(0.9))
                
                Text(viewModel.balance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.balance)
            }
            
            Spacer()
            
            Image(systemName: viewModel.balance >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(24)
        .background {
            LinearGradient(
                colors: viewModel.balance >= 0 ? [Color.green, Color.green.opacity(0.7)] : [Color.red, Color.red.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .cornerRadius(25)
    }
}

struct AnalyticsMonthlyPulseCard: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var progress: Double {
        guard viewModel.totalIncome > 0 else { return 0 }
        return min(viewModel.totalExpense / viewModel.totalIncome, 1.0)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption)
                    Text("Aylık Nabız")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white.opacity(0.9))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("%\(Int(progress * 100))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Harcanan")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 40, height: 40)
        }
        .padding(24)
        .background {
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .cornerRadius(25)
    }
}
