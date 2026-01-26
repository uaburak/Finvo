import SwiftUI
import Charts

struct ComparisonView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            
            // 1. Leaderboard (Total Spend)
            VStack(alignment: .leading, spacing: 12) {
                Text("Liderlik Tablosu")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    ForEach(viewModel.memberData) { member in
                        HStack {
                            Circle()
                                .fill(member.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(member.username.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(member.username)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(Int(member.percentage))% Pay")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(member.value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                .font(.headline)
                                .bold()
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 5)
                .padding(.horizontal)
            }
            
            // 2. Bar Chart Comparison
            VStack(alignment: .leading, spacing: 12) {
                Text("Harcama Karşılaştırması")
                    .font(.headline)
                    .padding(.horizontal)
                
                Chart(viewModel.memberData) { member in
                    BarMark(
                        x: .value("Kişi", member.username),
                        y: .value("Tutar", member.value)
                    )
                    .foregroundStyle(member.color)
                    .annotation(position: .top) {
                        Text(member.value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 5)
                .padding(.horizontal)
            }
            
            // 3. Category Duel (Simplified)
            // Ideally, we'd need more complex data structure in ViewModel for this: [Category: [User: Amount]]
            // For MVP, we stick to the main comparison.
        }
        .padding(.top)
    }
}
