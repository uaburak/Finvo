import SwiftUI

struct SavingsWithdrawView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var categoryManager: CategoryManager
    
    var walletId: String
    var maxWithdrawalAmount: Double
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Fixed categories for withdrawal
    let categoryName = "Yatırım & Finansal Gelir" // Must match DefaultCategories
    let subCategoryName = "Birikim Bozdurma"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Info Card
                VStack(spacing: 8) {
                    Text("Çekilebilir Bakiye")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(maxWithdrawalAmount.formatted(.currency(code: "TRY")))
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.top)
                
                // Amount Input
                VStack(spacing: 8) {
                    Text("Çekilecek Tutar")
                        .font(.headline)
                    
                    TextField("0", text: $amount)
                        .font(.system(size: 40, weight: .bold))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                TextField("Not (Opsiyonel)", text: $note)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                Button(action: {
                    submitWithdrawal()
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Onayla ve Çek")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green) // Income action
                            .cornerRadius(12)
                    }
                }
                .disabled(amount.isEmpty || isLoading)
            }
            .padding()
            .navigationTitle("Para Çek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func submitWithdrawal() {
        guard let amountVal = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Geçersiz tutar"
            return
        }
        
        if amountVal > maxWithdrawalAmount {
            errorMessage = "Bakiyenizden fazla çekemezsiniz."
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let transaction = Transaction(
                    id: nil,
                    amount: amountVal,
                    currency: "TRY",
                    date: Date(),
                    type: .income, // Withdrawal from Savings is Income to Wallet
                    categoryName: categoryName,
                    subCategoryName: subCategoryName,
                    createdBy: "user", // Should be actual user ID ideally, but service handles standard
                    note: note.isEmpty ? "Birikim Hesabından Para Çekme" : note,
                    isRecurring: false
                )
                
                try await FirestoreService.shared.addTransaction(walletId: walletId, transaction: transaction)
                
                // Trigger refresh
                NotificationCenter.default.post(name: .transactionAdded, object: transaction)
                
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
