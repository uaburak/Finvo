import SwiftUI

struct SavingsGoalCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // Calculates progress: 0.0 to 1.0
    var progress: Double {
        guard let goal = viewModel.savingsGoal, goal > 0 else { return 0 }
        let current = viewModel.savingsBalance
        // Clamp between 0 and 1
        return min(max(current / goal, 0), 1)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Content
            VStack(alignment: .leading, spacing: 8) { // Reduced spacing
                // Header & Goal
                VStack(alignment: .leading, spacing: 4) {
                    Text("Birikim Hedefi")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let goal = viewModel.savingsGoal, goal > 0 {
                        Text(viewModel.savingsBalance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.system(size: 38, weight: .bold)) // Increased size
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: viewModel.savingsBalance)
                            .minimumScaleFactor(0.7)
                        // Removed explicit goal text as requested
                    } else {
                        Text("Hedef Belirlenmedi")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                
                // Progress Bar
                if let goal = viewModel.savingsGoal, goal > 0 {
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background Track
                                Capsule()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(height: 10) // Reduced height
                                
                                // Progress Fill
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: geometry.size.width * progress, height: 10) // Reduced height
                                    .animation(.spring, value: progress)
                            }
                        }
                        .frame(height: 10) // Reduced height
                        .padding(.top, 4) // Reduced padding
                        
                        HStack {
                            Text("%\(Int(progress * 100)) Tamamlandı")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                            Text("Kalan: \((goal - viewModel.savingsBalance).formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                } else {
                    Text("Birikim hedefi belirlemek için ayarlara tıklayın.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16) // Increased padding
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Settings Menu (Top Right)
            Menu {
                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSpendingLimit"), object: nil)
                } label: {
                    Label("Harcama Limiti belirle", systemImage: "chart.line.downtrend.xyaxis")
                }
                
                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSavingsWithdraw"), object: nil)
                } label: {
                    Label("Para Çek", systemImage: "arrow.counterclockwise.circle")
                }
                
                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSavingsGoal"), object: nil)
                } label: {
                    Label("Birikim Hedefi belirle", systemImage: "target")
                }
                
                Divider()
                
                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenWalletManagement"), object: nil)
                } label: {
                    Label("Cüzdanı Yönet", systemImage: "gear")
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(16)
            }
        }
        .background(Color.green)
        .cornerRadius(25)
    }
}
