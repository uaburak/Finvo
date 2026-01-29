import SwiftUI

struct FinancialInsightsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Hero Card
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(viewModel.savingsBalance > 0 ? "Harika Gidiyorsun!" : "Tasarrufa Başla")
                            .font(.title2)
                            .bold()
                        
                        Text(viewModel.savingsBalance > 0 ? "Birikimlerin artmaya devam ediyor. Bu disiplini korursan hedeflerine sandığından daha kısa sürede ulaşabilirsin." : "Henüz birikime başlamadın gibi görünüyor. Küçük miktarlarla başlamak bile zamanla büyük fark yaratır.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    
                    // 2. Tips List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Senin İçin Öneriler")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TipRow(icon: "cup.and.saucer.fill", color: .brown, title: "Kahve Harcamaları", subtitle: "Dışarıda kahve içmek yerine haftada 2 gün evde yapmayı dene.")
                            TipRow(icon: "cart.fill", color: .blue, title: "Market Listesi", subtitle: "Alışverişe çıkmadan önce mutlaka liste hazırla ve sadık kal.")
                            TipRow(icon: "arrow.triangle.2.circlepath", color: .purple, title: "Abonelikler", subtitle: "Kullanmadığın dijital abonelikleri kontrol et ve iptal et.")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Finansal İpuçları")
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

struct TipRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
}
