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
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: categoryColor).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .font(.body)
                    .foregroundColor(Color(hex: categoryColor))
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.subCategoryName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text("\(transaction.type == .income ? "+" : "-") \(transaction.amount, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}
