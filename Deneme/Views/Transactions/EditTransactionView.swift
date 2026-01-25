import SwiftUI
import Combine

struct EditTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = EditTransactionViewModel()
    
    var transaction: Transaction
    var walletId: String
    
    init(transaction: Transaction, walletId: String) {
        self.transaction = transaction
        self.walletId = walletId
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tutar")) {
                    TextField("Tutar", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                }
                
                Section(header: Text("Detaylar")) {
                    DatePicker("Tarih", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Not", text: $viewModel.note)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("İşlemi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        Task {
                            if await viewModel.updateTransaction(original: transaction, walletId: walletId) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                viewModel.initialize(with: transaction)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }
}

@MainActor
class EditTransactionViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var note: String = ""
    @Published var date: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func initialize(with transaction: Transaction) {
        // Only strip ".0" if it's a clean integer, otherwise show full decimal
        let amountVal = transaction.amount
        if amountVal.truncatingRemainder(dividingBy: 1) == 0 {
            self.amount = String(format: "%.0f", amountVal)
        } else {
            self.amount = String(amountVal)
        }
        
        self.note = transaction.note ?? ""
        self.date = transaction.date
    }
    
    func updateTransaction(original: Transaction, walletId: String) async -> Bool {
        guard let newAmount = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Geçersiz tutar"
            return false
        }
        
        isLoading = true
        
        var updated = original
        updated.amount = newAmount
        updated.note = note.isEmpty ? nil : note
        updated.date = date
        
        do {
            try await FirestoreService.shared.updateTransaction(walletId: walletId, transaction: updated)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
