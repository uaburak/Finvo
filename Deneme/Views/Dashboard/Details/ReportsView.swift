import SwiftUI

struct ReportsView: View {
    @StateObject var viewModel = AnalyticsViewModel()
    
    // Derived Data
    var totalIncome: Double { viewModel.allTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    var totalExpense: Double { viewModel.allTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return (totalIncome - totalExpense) / totalIncome
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. General Summary
                HStack(spacing: 12) {
                    ReportSummaryCard(title: "Toplam Gelir", amount: totalIncome, color: .green)
                    ReportSummaryCard(title: "Toplam Gider", amount: totalExpense, color: .red)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 2. Net & Savings Rate
                VStack(spacing: 12) {
                    HStack {
                        Text("Net Durum")
                            .font(.headline)
                        Spacer()
                        Text((totalIncome - totalExpense).formatted(.currency(code: "TRY")))
                            .font(.title3)
                            .bold()
                            .foregroundColor((totalIncome - totalExpense) >= 0 ? .green : .red)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Tasarruf Oranı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(savingsRate.formatted(.percent.precision(.fractionLength(1))))
                            .font(.headline)
                            .foregroundColor(savingsRate > 0.2 ? .green : (savingsRate > 0 ? .orange : .red))
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // 3. Category Breakdown (Simple List)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Kategori Bazlı Harcamalar")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(viewModel.chartData.prefix(5)) { category in
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 10, height: 10)
                                Text(category.category)
                                    .font(.subheadline)
                                Spacer()
                                Text(category.value.formatted(.currency(code: "TRY")))
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding()
                            
                            if category.id != viewModel.chartData.prefix(5).last?.id {
                                Divider().padding(.leading)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Finansal Rapor")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReportSummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                .font(.headline)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
}
