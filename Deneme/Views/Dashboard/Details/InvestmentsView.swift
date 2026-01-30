import SwiftUI

struct InvestmentsView: View {
    @StateObject var viewModel = AnalyticsViewModel()
    
    var investmentTransactions: [Transaction] {
        viewModel.allTransactions.filter {
            $0.categoryName == "Birikim & Yatırım" ||
            $0.categoryName == "Yatırım & Finansal Gelir" ||
            $0.categoryName == "Gayrimenkul & Pasif Gelir"
        }
        .sorted(by: { $0.date > $1.date })
    }
    
    var totalInvested: Double {
        investmentTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var totalReturn: Double {
        investmentTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var netValue: Double {
        totalReturn - totalInvested // Simple Logic: Returns - Cost (Though cost stays as asset usually, this is just cash flow)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Toplam Yatırım")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(totalInvested.formatted(.currency(code: "TRY")))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Toplam Getiri")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(totalReturn.formatted(.currency(code: "TRY")))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Transactions
                LazyVStack(spacing: 12) {
                    if investmentTransactions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Yatırım işlemi bulunamadı.")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(investmentTransactions) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Yatırımlar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        InvestmentsView()
    }
}
