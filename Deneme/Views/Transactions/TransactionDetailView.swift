import SwiftUI
import FirebaseAuth

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletManager: WalletManager
    var transaction: Transaction
    
    @State private var showEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header (Icon & Amount)
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 80, height: 80)
                        
                        // We rely on SF Symbol name being valid. 
                        // If Category model has icon name, usually we store categoryName.
                        // Ideally we fetch category color/icon, but for now we fallback.
                        Image(systemName: "list.bullet") 
                            .font(.largeTitle)
                            .foregroundColor(.blue)
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
