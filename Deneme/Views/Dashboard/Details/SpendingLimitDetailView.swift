import SwiftUI

struct SpendingLimitDetailView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var limit: Double {
        return viewModel.monthlyLimit ?? 0
    }
    
    var remaining: Double {
        guard limit > 0 else { return 0 }
        return max(0, limit - viewModel.monthlyExpense)
    }
    
    var progress: Double {
        guard limit > 0 else { return 0 }
        return min(viewModel.monthlyExpense / limit, 1.0)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Hero Circle
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray6), lineWidth: 20)
                            .frame(width: 220, height: 220)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(gradient: Gradient(colors: [.blue, .purple, .red]), center: .center),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 220, height: 220)
                            .animation(.spring(), value: progress)
                        
                        VStack(spacing: 8) {
                            Text("Kalan Limit")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(remaining.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("/ \(limit.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // 2. Info Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        InfoCard(title: "Harcanan", value: viewModel.monthlyExpense.formatted(.currency(code: "TRY").precision(.fractionLength(0))), icon: "creditcard.fill", color: .red)
                        InfoCard(title: "Günlük Ort.", value: (viewModel.monthlyExpense / Double(Calendar.current.component(.day, from: Date()))).formatted(.currency(code: "TRY").precision(.fractionLength(0))), icon: "calendar", color: .blue)
                    }
                    .padding(.horizontal)
                    
                    // 3. Status Message
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Durum Analizi")
                            .font(.headline)
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title3)
                                .foregroundColor(.yellow)
                                .padding(10)
                                .background(Color.yellow.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(progress > 0.8 ? "Limit Aşım Riski!" : "Bütçe Kontrol Altında")
                                    .font(.subheadline)
                                    .bold()
                                
                                Text(progress > 0.8 ? "Harcamaların bu hızla devam ederse ay sonundan önce limitin dolabilir. Gereksiz harcamaları kısmanı öneririz." : "Harcama hızın gayet ideal. Bu şekilde devam edersen ay sonunda limitini aşmayacaksın.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Limit Detayı")
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

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .bold()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}
