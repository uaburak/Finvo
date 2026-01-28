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
    @Published var recurrenceFrequency: RecurrenceFrequency = .monthly
    @Published var endDate: Date?
    
    // Debt Wizard State
    @Published var isDebt: Bool = false
    @Published var debtName: String = ""
    @Published var debtFrequency: RecurrenceFrequency = .monthly
    @Published var totalInstallments: String = "12"
    @Published var currentInstallment: String = "1"
    
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
        recurrenceFrequency = .monthly
        endDate = nil
        isDebt = false
        debtName = ""
        debtFrequency = .monthly
        totalInstallments = "12"
        currentInstallment = "1"
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
        
        // Debt Logic variables
        var linkedDebtId: String?
        
        do {
            if isDebt {
                // Validation for Debt
                guard let totalInst = Int(totalInstallments), let currentInst = Int(currentInstallment), 
                      totalInst > 0, currentInst > 0, currentInst <= totalInst else {
                    errorMessage = "Lütfen geçerli taksit bilgileri girin."
                    return
                }
                
                guard !debtName.isEmpty else {
                    errorMessage = "Lütfen borç adı girin."
                    return
                }
                
                // Calculate next due date based on frequency
                // For the *next* installment. Since we are paying 'currentInst' today, 
                // the next one is due 1 cycle later.
                let nextDueDate = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? Date() // Default monthly logic for now, extend for others
                
                // Create Debt Object
                // paidInstallments = currentInst because we are paying it right now.
                // remainingAmount = (total - current) * amount
                let totalAmountVal = Double(totalInst) * amountValue
                let remainingAmountVal = Double(totalInst - currentInst) * amountValue
                
                let newDebt = Debt(
                    name: debtName,
                    totalAmount: totalAmountVal,
                    remainingAmount: remainingAmountVal,
                    totalInstallments: totalInst,
                    paidInstallments: currentInst,
                    installmentAmount: amountValue,
                    currency: "TRY",
                    status: remainingAmountVal <= 0 ? .completed : .active,
                    startDate: date, // usage date
                    nextDueDate: nextDueDate, // This needs proper calculation based on frequency
                    frequency: debtFrequency,
                    createdBy: currentUser.uid,
                    walletId: walletId
                )
                
                // Save Debt first to get ID
                linkedDebtId = try await firestoreService.addDebt(walletId: walletId, debt: newDebt)
            }
            
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
                createdByUsername: username,
                linkedDebtId: linkedDebtId,
                recurrenceFrequency: isDebt ? debtFrequency : (isRecurring ? recurrenceFrequency : nil),
                endDate: isRecurring ? endDate : nil,
                nextOccurrenceDate: isRecurring ? RecurrenceManager.shared.calculateNextOccurrence(from: date, frequency: recurrenceFrequency) : nil
            )
        
            try await firestoreService.addTransaction(walletId: walletId, transaction: newTransaction)
            
            // Post notification for optimistic updates
            NotificationCenter.default.post(name: .transactionAdded, object: newTransaction)
            
            self.isLoading = false
            self.isSuccess = true
        } catch {
            self.isLoading = false
            self.errorMessage = "İşlem kaydedilemedi: \(error.localizedDescription)"
        }
    }
}
