import SwiftUI

struct AssetSummaryCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var backgroundColor: Color {
        if viewModel.totalBalance < 0 {
            return .red
        } else if viewModel.totalBalance <= 10000 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Content
            VStack(alignment: .leading, spacing: 8) { // Restored VStack
                // Balance Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Varlık")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(viewModel.totalBalance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.system(size: 38, weight: .bold)) // Matched with Savings Card
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: viewModel.totalBalance)
                        .minimumScaleFactor(0.7)
                }
                
                // Extra Info (Secondary Content like Progress Bar)
                HStack(spacing: 16) {
                    // Monthly Net
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bu Ay Net")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        let net = viewModel.monthlyIncome - viewModel.monthlyExpense
                        HStack(spacing: 4) {
                            Image(systemName: net >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                            Text(net.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                .font(.caption) // Adjusted for balance
                                .fontWeight(.semibold)
                                .minimumScaleFactor(0.9)
                        }
                        .foregroundColor(net >= 0 ? .white : .white.opacity(0.9))
                    }
                    
                    // Monthly Limit Info (if exists)
                    if let limit = viewModel.monthlyLimit, limit > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Limit Kalan")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            let remaining = limit - viewModel.monthlyExpense
                            Text(remaining.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                .font(.caption) // Adjusted for balance
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.9)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(16) // Increased outer padding
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Settings Menu (Top Right)
            Menu {
                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSpendingLimit"), object: nil)
                } label: {
                    Label("Harcama Limiti belirle", systemImage: "chart.line.downtrend.xyaxis")
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
                    .padding(16) // 16px padding
            }
        }
        .background(backgroundColor)
        .cornerRadius(25)
    }
}
