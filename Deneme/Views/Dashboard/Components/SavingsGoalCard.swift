import SwiftUI

struct SavingsGoalCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // Calculates progress: 0.0 to 1.0
    var progress: Double {
        guard let goal = viewModel.savingsGoal, goal > 0 else { return 0 }
        let current = viewModel.totalBalance
        // Clamp between 0 and 1
        return min(max(current / goal, 0), 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Birikim Hedefi")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let goal = viewModel.savingsGoal, goal > 0 {
                        Text(viewModel.totalBalance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: viewModel.totalBalance)
                        
                        Text("/ \(goal.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Hedef Belirlenmedi")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Settings Menu (Same as Asset Card)
                Menu {
                    Button {
                        NotificationCenter.default.post(name: NSNotification.Name("OpenSavingsGoal"), object: nil)
                    } label: {
                        Label("Hedefi Düzenle", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding(8)
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
                                .frame(height: 12)
                            
                            // Progress Fill
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geometry.size.width * progress, height: 12)
                                .animation(.spring, value: progress)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("%\(Int(progress * 100)) Tamamlandı")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Text("Kalan: \((goal - viewModel.totalBalance).formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
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
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
        .cornerRadius(20)
    }
}
