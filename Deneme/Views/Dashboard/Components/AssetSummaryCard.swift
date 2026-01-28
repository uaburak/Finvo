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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Varlık")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(viewModel.totalBalance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: viewModel.totalBalance)
                }
                
                Spacer()
                
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
                        .font(.title2)
                        .padding(8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}
