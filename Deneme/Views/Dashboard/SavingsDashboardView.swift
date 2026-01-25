import SwiftUI

struct SavingsDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Savings Header
            VStack(alignment: .leading, spacing: 16) {
                Text("Birikim Hedefi")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    Text("₺\(viewModel.totalBalance, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "banknote")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Progress Bar Placeholder
                VStack(alignment: .leading, spacing: 5) {
                    Text("Hedef: ₺50,000") // Static for now, can be added to Wallet model
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 8)
                                .opacity(0.3)
                                .foregroundColor(.white)
                            
                            Rectangle()
                                .frame(width: min(geometry.size.width * 0.25, geometry.size.width), height: 8) // 25% Dummy progress
                                .foregroundColor(.green)
                        }
                        .cornerRadius(4)
                    }
                    .frame(height: 8)
                }
            }
            .padding()
            .background(Color.purple) // Different color for Savings
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding(.horizontal)
            
            // Recent Contributions (Transactions)
            VStack(alignment: .leading) {
                Text("Son Katkılar")
                    .font(.headline)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ForEach(viewModel.recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
    }
}
