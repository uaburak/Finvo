import SwiftUI
import Charts

struct TopSpendingDetailView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    // Local struct for stats to conform to Identifiable
    struct CategoryStat: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
        let color: Color
        let percentage: Double
    }
    
    // Convert generic recent transactions to category stats
    var categoryStats: [CategoryStat] {
        let expenses = viewModel.recentTransactions.filter { $0.type == .expense }
        let total = expenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }
        
        let grouped = Dictionary(grouping: expenses, by: { $0.categoryName })
        return grouped.map { (key, value) in
            let sum = value.reduce(0) { $0 + $1.amount }
            let color = getColor(for: key)
            return CategoryStat(name: key, amount: sum, color: color, percentage: (sum / total) * 100)
        }.sorted { $0.amount > $1.amount }
    }
    
    func getColor(for name: String) -> Color {
        if let cat = DefaultCategories.defaults.first(where: { $0.name == name }) {
            return cat.color
        }
        return .gray
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Hero Chart
                    ZStack {
                        Chart(categoryStats) { item in
                            SectorMark(
                                angle: .value("Tutar", item.amount),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .cornerRadius(8)
                            .foregroundStyle(item.color)
                        }
                        .frame(height: 250)
                        
                        VStack(spacing: 4) {
                            Text("Toplam")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.monthlyExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                .font(.title2)
                                .bold()
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // 2. Breakdown List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Harcama Dağılımı")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(categoryStats, id: \.name) { item in
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(item.color.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(String(item.name.prefix(1)))
                                                .font(.headline)
                                                .foregroundColor(item.color)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        ProgressView(value: item.percentage, total: 100)
                                            .tint(item.color)
                                            .scaleEffect(y: 2, anchor: .center)
                                            .clipShape(Capsule())
                                            .frame(height: 4)
                                            .frame(width: 80)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(item.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                            .font(.subheadline)
                                            .bold()
                                        Text("%\(Int(item.percentage))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Harcama Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}
