import SwiftUI

struct BudgetDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 24) {
             // Header Card
             VStack(alignment: .leading, spacing: 16) {
                 HStack {
                     VStack(alignment: .leading) {
                         Text("Toplam Varlık")
                             .font(.caption)
                             .foregroundColor(.white.opacity(0.8))
                         Text("₺\(viewModel.totalBalance, specifier: "%.2f")")
                             .font(.system(size: 32, weight: .bold))
                             .foregroundColor(.white)
                     }
                     Spacer()
                 }
                 
                 HStack {
                     VStack(alignment: .leading) {
                         HStack {
                             Image(systemName: "arrow.up.circle.fill")
                                 .foregroundColor(.green)
                             Text("Gelir")
                                 .foregroundColor(.white.opacity(0.8))
                         }
                         Text("₺\(viewModel.monthlyIncome, specifier: "%.2f")")
                             .font(.headline)
                             .foregroundColor(.white)
                     }
                     
                     Spacer()
                     
                     VStack(alignment: .trailing) {
                         HStack {
                             Text("Gider")
                                 .foregroundColor(.white.opacity(0.8))
                             Image(systemName: "arrow.down.circle.fill")
                                 .foregroundColor(.red)
                         }
                         Text("₺\(viewModel.monthlyExpense, specifier: "%.2f")")
                             .font(.headline)
                             .foregroundColor(.white)
                     }
                 }
             }
             .padding()
             .background(Color.blue)
             .cornerRadius(20)
             .shadow(radius: 5)
             .padding(.horizontal)
             
             // Recent Transactions
             VStack(alignment: .leading) {
                 HStack {
                     Text("Son İşlemler")
                         .font(.headline)
                     Spacer()
                 }
                 .padding(.horizontal)
                 
                 if viewModel.isLoading {
                     ProgressView()
                         .frame(maxWidth: .infinity)
                 } else if viewModel.recentTransactions.isEmpty {
                     Text("Henüz işlem yok")
                         .font(.subheadline)
                         .foregroundColor(.secondary)
                         .padding()
                         .frame(maxWidth: .infinity, alignment: .center)
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
