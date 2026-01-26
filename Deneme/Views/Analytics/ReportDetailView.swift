import SwiftUI
import Charts

struct ReportDetailView: View {
    let report: Report
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 12) {
                    Text(report.rangeType.rawValue)
                        .font(.headline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                        .foregroundColor(.blue)
                    
                    Text(report.totalExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                        .font(.system(size: 36, weight: .bold))
                    
                    Text("\(report.startDate.formatted(date: .numeric, time: .omitted)) - \(report.endDate.formatted(date: .numeric, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                
                // Income vs Expense
                HStack(spacing: 16) {
                    SummaryCard(title: "Gelir", value: report.totalIncome, color: .green, icon: "arrow.down.left")
                    SummaryCard(title: "Gider", value: report.totalExpense, color: .red, icon: "arrow.up.right")
                }
                .padding(.horizontal)
                
                // Category Breakdown
                if !report.categoryBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kategori Dağılımı")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(report.categoryBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                                BarMark(
                                    x: .value("Tutar", value),
                                    y: .value("Kategori", key)
                                )
                                .foregroundStyle(by: .value("Kategori", key))
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                // Member Breakdown (if shared)
                if let members = report.memberBreakdown, !members.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Üye Harcamaları")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(members.sorted(by: { $0.value > $1.value }), id: \.key) { key, value in
                                SectorMark(
                                    angle: .value("Tutar", value),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Üye", key))
                                .annotation(position: .overlay) {
                                    Text(key.prefix(1))
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Rapor Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: generateShareText(report: report)) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    // Simple Text Share Generation
    func generateShareText(report: Report) -> String {
        return """
        Finvo Raporu (\(report.rangeType.rawValue))
        Tarih: \(report.createdAt.formatted(date: .numeric, time: .omitted))
        
        Toplam Gelir: \(report.totalIncome.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
        Toplam Gider: \(report.totalExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
        Net Durum: \(report.netBalance.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
        """
    }
}

struct SummaryCard: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            .padding(10)
            .background(color.opacity(0.1))
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                    .font(.headline)
                    .bold()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 5)
    }
}
