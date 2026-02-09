import SwiftUI

struct UpcomingPaymentsDetailView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var nextPayment: Debt? {
        return viewModel.activeDebts.sorted(by: { $0.nextDueDate < $1.nextDueDate }).first
    }
    
    var sortedDebts: [Debt] {
        return viewModel.activeDebts.sorted(by: { $0.nextDueDate < $1.nextDueDate })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Hero Card
                    VStack(spacing: 8) {
                        Text("Sıradaki Ödeme")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let debt = nextPayment {
                            Text(debt.installmentAmount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text(debt.name)
                                    .fontWeight(.medium)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(debt.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.red)
                            }
                            .font(.callout)
                            
                        } else {
                            Text("Ödeme Yok")
                                .font(.title)
                                .bold()
                            Text("Şu an planlanmış bir borcun görünmüyor.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.04), radius: 5)
                    
                    // 2. All Debts List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Tüm Ödemeler")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.activeDebts.count) Adet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if sortedDebts.isEmpty {
                            ContentUnavailableView("Listeniz Boş", systemImage: "checklist")
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(sortedDebts) { debt in
                                    HStack(spacing: 16) {
                                        Circle()
                                            .fill(Color.orange.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "creditcard.fill")
                                                    .foregroundColor(.orange)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(debt.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            
                                            Text("\(debt.paidInstallments)/\(debt.totalInstallments) Taksit")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(debt.installmentAmount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                                .font(.subheadline)
                                                .bold()
                                            
                                            Text(debt.nextDueDate.formatted(date: .numeric, time: .omitted))
                                                .font(.caption2)
                                                .foregroundColor(debt.isOverdue ? .red : .secondary)
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
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Ödeme Takvimi")
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
