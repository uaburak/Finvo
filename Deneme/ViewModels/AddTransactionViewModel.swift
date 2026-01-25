import Foundation
import FirebaseAuth
import Combine

@MainActor
class AddTransactionViewModel: ObservableObject {
    // Wizard State
    @Published var selectedType: TransactionType = .expense
    @Published var selectedCategory: Category?
    @Published var selectedSubCategory: String?
    @Published var amount: String = "0"
    @Published var note: String = ""
    @Published var date: Date = Date()
    @Published var isRecurring: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSuccess: Bool = false
    
    // Dependencies
    private let firestoreService = FirestoreService.shared
    
    func reset() {
        selectedType = .expense
        selectedCategory = nil
        selectedSubCategory = nil
        amount = "0"
        note = ""
        date = Date()
        isRecurring = false
        isSuccess = false
        errorMessage = nil
    }
    
    func saveTransaction(walletId: String) async {
        guard let category = selectedCategory, let subCategory = selectedSubCategory else {
            errorMessage = "Lütfen kategori ve alt kategori seçin."
            return
        }
        
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Lütfen geçerli bir tutar girin."
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Kullanıcı oturumu bulunamadı."
            return
        }
        
        self.isLoading = true
        
        // Use cached username from AuthenticationManager
        // Fallback to displayName or default if profile not loaded yet
        let username = AuthenticationManager.shared.currentUserProfile?.username 
            ?? currentUser.displayName 
            ?? "Kullanıcı"
        
        let newTransaction = Transaction(
            amount: amountValue,
            currency: "TRY", // Default for now
            date: date,
            type: selectedType,
            categoryName: category.name,
            subCategoryName: subCategory,
            createdBy: currentUser.uid,
            note: note.isEmpty ? nil : note,
            isRecurring: isRecurring,
            createdByUsername: username
        )
        
        do {
            try await firestoreService.addTransaction(walletId: walletId, transaction: newTransaction)
            self.isLoading = false
            self.isSuccess = true
        } catch {
            self.isLoading = false
            self.errorMessage = "İşlem kaydedilemedi: \(error.localizedDescription)"
        }
    }
}
