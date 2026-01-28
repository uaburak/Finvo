import SwiftUI

struct RecentTransactionsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son İşlemler")
                    .font(.headline)
                Spacer()
                
                NavigationLink(destination: Text("Tüm İşlemler")) { // Replace with actual Transaction List view if available
                    Text("Tümü")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.recentTransactions.isEmpty {
                Text("Henüz işlem yok")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 0) { // Spacing handled by row padding usually
                    ForEach(viewModel.recentTransactions.prefix(4)) { transaction in
                        TransactionRow(transaction: transaction)
                            .padding(.vertical, 4)
                        
                        if transaction.id != viewModel.recentTransactions.prefix(4).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
