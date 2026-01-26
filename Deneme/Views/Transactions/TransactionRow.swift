import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    
    // Helper to find category info
    private var category: Category? {
        CategoryManager.shared.categories.first { $0.name == transaction.categoryName }
    }
    
    private var subCategory: SubCategory? {
        guard let category = category else { return nil }
        return category.subCategories.first { $0.name == transaction.subCategoryName }
    }
    
    private var categoryIcon: String {
        return subCategory?.icon ?? category?.icon ?? "circle.fill"
    }
    
    private var categoryColor: String {
        return subCategory?.colorHex ?? category?.colorHex ?? "#8E8E93"
    }
    
    var body: some View {
        ListItem(
            icon: categoryIcon,
            iconColor: Color(hex: categoryColor) ?? .gray,
            title: transaction.subCategoryName.isEmpty ? transaction.categoryName : transaction.subCategoryName,
            subtitle: transaction.categoryName, // Not shown if username exists, but good fallback
            username: transaction.createdByUsername,
            isRecurring: transaction.isRecurring,
            value: "\(transaction.type == .income ? "+" : "-") \(transaction.amount.formatted(.currency(code: "TRY").precision(.fractionLength(0))))",
            valueColor: transaction.type == .income ? .green : .red,
            secondaryInfo: transaction.date.formatted(date: .abbreviated, time: .shortened)
        )
    }
}
