import SwiftUI
import FirebaseAuth

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    var transaction: Transaction
    
    @State private var showEditSheet = false
    
    // Helper to find category info
    private var categoryInfo: (icon: String, color: String) {
        if let category = CategoryManager.shared.categories.first(where: { $0.name == transaction.categoryName }) {
            if let subStr = transaction.subCategoryName.isEmpty ? nil : transaction.subCategoryName,
               let sub = category.subCategories.first(where: { $0.name == subStr }) {
                return (sub.icon, sub.colorHex)
            }
            return (category.icon, category.colorHex)
        }
        return ("list.bullet", "#007AFF") // Fallback
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header (Icon & Amount)
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: categoryInfo.icon) 
                            .font(.largeTitle)
                            .foregroundColor(Color(hex: categoryInfo.color))
                    }
                    
                    VStack(spacing: 4) {
                        Text(transaction.categoryName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(transaction.amount, specifier: "%.2f") \(transaction.currency)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(transaction.type == .income ? .green : .red)
                    }
                }
                .padding(.top, 20)
                
                Divider()
                
                // Info Rows
                VStack(spacing: 20) {
                    DetailRow(title: "Tarih", value: transaction.date.formatted(date: .long, time: .shortened))
                    
                    if !transaction.subCategoryName.isEmpty {
                        DetailRow(title: "Alt Kategori", value: transaction.subCategoryName)
                    }
                    
                    DetailRow(title: "Ekleyen", value: transaction.createdByUsername ?? "Bilinmiyor")
                    
                    if let note = transaction.note, !note.isEmpty {
                        DetailRow(title: "Not", value: note)
                    }
                    
                    if transaction.isRecurring {
                        DetailRow(title: "Tekrar", value: "Evet", icon: "repeat")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Edit Button (Orange as requested)
                // Edit Button (Orange as requested)
                // Only show if user has permission
                if let wallet = walletManager.selectedWallet, 
                   wallet.canEdit(userId: AuthenticationManager.shared.user?.uid ?? "") {
                    
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Düzenle", systemImage: "pencil")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("İşlem Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            if let walletId = walletManager.selectedWallet?.id {
                EditTransactionView(transaction: transaction, walletId: walletId)
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var icon: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .fontWeight(.medium)
        }
    }
}
