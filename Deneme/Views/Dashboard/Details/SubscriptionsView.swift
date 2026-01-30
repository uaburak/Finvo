import SwiftUI

struct SubscriptionsView: View {
    @StateObject var viewModel = AnalyticsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var subscriptionTransactions: [Transaction] {
        viewModel.allTransactions.filter { $0.categoryName == "Dijital Abonelikler" }
            .sorted(by: { $0.date > $1.date })
    }
    
    var totalSpent: Double {
        subscriptionTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Monthly Summary Card
                VStack(spacing: 12) {
                    Text("Toplam Abonelik Harcaması")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(totalSpent.formatted(.currency(code: "TRY")))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(subscriptionTransactions.count) İşlem")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.1))
                        .foregroundColor(.indigo)
                        .cornerRadius(8)
                }
                .padding(.top, 20)
                
                // Transactions List
                LazyVStack(spacing: 12) {
                    ForEach(subscriptionTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    
                    if subscriptionTransactions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Abonelik işlemi bulunamadı.")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Abonelikler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SubscriptionsView()
    }
}
