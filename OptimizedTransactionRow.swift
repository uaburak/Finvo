import SwiftUI

struct OptimizedTransactionRow: View {
    let transaction: Transaction
    let viewModel: TransactionsViewModel
    let currency: String
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon Container
            TransactionIconView(
                transaction: transaction,
                viewModel: viewModel
            )
            
            // Transaction Details
            TransactionDetailsView(
                transaction: transaction,
                viewModel: viewModel
            )
            
            Spacer()
            
            // Amount and Date
            TransactionAmountView(
                transaction: transaction,
                currency: currency
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDelete()
            } label: {
                Label("Delete".localized, systemImage: "trash")
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onEdit()
            } label: {
                Label("Edit".localized, systemImage: "pencil")
            }
            .tint(.orange)
        }
    }
}

// MARK: - Sub Components
struct TransactionIconView: View {
    let transaction: Transaction
    let viewModel: TransactionsViewModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(viewModel.getColor(for: transaction))
                .frame(width: 40, height: 40)
                .shadow(color: viewModel.getColor(for: transaction).opacity(0.3), radius: 4, x: 0, y: 2)
            
            Image(systemName: viewModel.getIcon(for: transaction))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct TransactionDetailsView: View {
    let transaction: Transaction
    let viewModel: TransactionsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.getSubCategoryName(by: transaction.subCategoryID).isEmpty ?
                 viewModel.getMainCategoryName(by: transaction.mainCategoryID) :
                 viewModel.getSubCategoryName(by: transaction.subCategoryID))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(viewModel.getMainCategoryName(by: transaction.mainCategoryID))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct TransactionAmountView: View {
    let transaction: Transaction
    let currency: String
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(transaction.type == .income ? "+" : "")\(CurrencyFormatter.shared.format(transaction.amount, currency: currency))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(transaction.type == .income ? .green : .red)
            
            Text(transaction.date, style: .date)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    OptimizedTransactionRow(
        transaction: Transaction(
            mainCategoryID: UUID(),
            amount: -1500,
            date: Date(),
            type: .expense,
            name: "Market Alışverişi"
        ),
        viewModel: TransactionsViewModel(
            transactionService: CloudKitTransactionService(),
            categoryService: CloudKitCategoryService()
        ),
        currency: "₺",
        onEdit: {},
        onDelete: {}
    )
    .padding()
}
