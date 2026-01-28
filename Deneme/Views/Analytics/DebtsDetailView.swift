import SwiftUI

struct DebtsDetailView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Summary
                VStack(spacing: 8) {
                    Text("Toplam Kalan Borç")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.totalDebtRemaining.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(viewModel.activeDebts.count) Aktif Borç")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .padding(.top, 20)
                
                // Debt List
                if viewModel.activeDebts.isEmpty {
                    ContentUnavailableView("Borcunuz Yok", systemImage: "checkmark.seal.fill")
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.activeDebts) { debt in
                            DebtRowCard(debt: debt)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Borçlarım")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct DebtRowCard: View {
    let debt: Debt
    
    var progressColor: Color {
        let p = debt.progress
        if p < 0.3 { return .green }
        if p < 0.7 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(debt.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(debt.paidInstallments) / \(debt.totalInstallments) Taksit Ödendi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(debt.percentageString)
                    .font(.headline)
                    .foregroundColor(progressColor)
            }
            
            // Progress Bar
            ProgressView(value: debt.progress)
                .tint(progressColor)
                .scaleEffect(y: 2, anchor: .center)
                .clipShape(Capsule())
            
            Divider()
            
            // Footer Info
            HStack {
                VStack(alignment: .leading) {
                    Text("Kalan")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(debt.remainingAmount.formatted(.currency(code: debt.currency).precision(.fractionLength(0))))
                        .font(.subheadline)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Sonraki Ödeme")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(debt.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(debt.nextDueDate < Date() ? .red : .primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

extension Debt {
    var percentageString: String {
        let p = progress * 100
        return "%\(Int(p))"
    }
}
