import SwiftUI

struct TravelDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Travel Header
            ZStack {
                // Background Image Placeholder
                LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.white)
                        Text("Seyahat Fonu")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Text("₺\(viewModel.totalBalance, specifier: "%.2f")")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Kalan Gün: 45") // Dummy
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding()
            }
            .frame(height: 200)
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding(.horizontal)
            
            // Recent Expenses
            VStack(alignment: .leading) {
                Text("Seyahat Harcamaları")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(viewModel.recentTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
}
