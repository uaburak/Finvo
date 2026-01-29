import SwiftUI
import Charts

struct CategoryComparisonDetailView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.categoryMemberComparison) { categoryData in
                    CategoryDetailedRow(data: categoryData)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Harcama Yarışları")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CategoryDetailedRow: View {
    let data: AnalyticsViewModel.CategoryMemberBreakdown
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(data.categoryName)
                    .font(.headline)
                Spacer()
                Text(data.totalAmount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Bars List
            VStack(spacing: 12) {
                ForEach(data.memberShares) { member in
                    HStack(spacing: 12) {
                        // User Avatar
                        Circle()
                            .fill(member.color.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(member.username.prefix(1)))
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(member.color)
                            )
                        
                        // Name & Bar
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(member.username)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("%\(Int(member.percentage))")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(.secondary)
                            }
                            
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
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// Summary Card for Bento Grid
struct ComparisonSummaryCard: View {
    var body: some View {
        BentoCard {
            VStack(alignment: .leading, spacing: 0) { // Removed extra spacing
                HStack {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(.red)
                    Text("Harcama Yarışları")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 12)
                
                Spacer()
                
                Text("Kategorilerde Kim Lider?")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Detayları İncele")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
    }
}
