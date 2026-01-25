import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    
    // Helper to find category info
    private var categoryIcon: String {
        // Quick lookup or pass full category object
        // For now, simpler lookup or use generic icon if dynamic search is too costly here
        return CategoriesData.expenseCategories.first(where: { $0.name == transaction.categoryName })?.iconName 
            ?? CategoriesData.incomeCategories.first(where: { $0.name == transaction.categoryName })?.iconName 
            ?? "circle.fill"
    }
    
    private var categoryColor: String {
        return CategoriesData.expenseCategories.first(where: { $0.name == transaction.categoryName })?.colorHex
            ?? CategoriesData.incomeCategories.first(where: { $0.name == transaction.categoryName })?.colorHex
            ?? "#8E8E93"
    }
    
    var body: some View {
        HStack(alignment: .center) {
            // SOL Taraf (Kategori ve Kullanıcı)
            VStack(alignment: .leading, spacing: 4) {
                // Sol Üst: Kategori (ve Alt Kategori)
                HStack {
                     // Kategori İkonu (Opsiyonel: İsterseniz kaldırabilirsiniz, ama şık durur)
                     Image(systemName: categoryIcon)
                         .font(.caption)
                         .foregroundColor(Color(hex: categoryColor))
                    
                    Text(transaction.subCategoryName.isEmpty ? transaction.categoryName : transaction.subCategoryName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Sol Alt: Kullanıcı Adı
                Text("@\(transaction.createdByUsername ?? "kullanıcı")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // SAĞ Taraf (Tutar ve Tarih)
            VStack(alignment: .trailing, spacing: 4) {
                // Sağ Üst: Tutar
                Text("\(transaction.type == .income ? "+" : "-") \(transaction.amount, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.type == .income ? .green : .red)
                
                // Sağ Alt: Tarih ve Tekrar İkonu
                HStack(spacing: 4) {
                    if transaction.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}
