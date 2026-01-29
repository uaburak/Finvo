import SwiftUI
import Charts

struct MemberCategoryMatrixView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Kategorilere Göre Harcamalar", systemImage: "chart.bar.doc.horizontal")
                .font(.headline)
                .foregroundStyle(.indigo)
                .padding(.horizontal)
            
            if viewModel.categoryMemberComparison.isEmpty {
                Text("Henüz yeterli veri yok.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.categoryMemberComparison) { categoryData in
                            CategoryComparisonCard(data: categoryData)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CategoryComparisonCard: View {
    let data: AnalyticsViewModel.CategoryMemberBreakdown
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(data.categoryName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(data.totalAmount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Bars
            VStack(spacing: 8) {
                ForEach(data.memberShares) { member in
                    HStack {
                        // User Initials
                        Circle()
                            .fill(member.color.opacity(0.2))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(member.username.prefix(1)))
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(member.color)
                            )
                        
                        // Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray6))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(member.color)
                                    .frame(width: max(0, geo.size.width * CGFloat(member.percentage / 100)), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        // Pct
                        Text("%\(Int(member.percentage))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .frame(width: 220, height: 160) // Fixed size cards
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}
