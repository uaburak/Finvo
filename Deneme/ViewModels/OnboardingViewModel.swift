import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var isUsernameAvailable: Bool? = nil // nil: not checked, true: available, false: taken
    @Published var isCheckingUsername: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    // Debounce timer for username check
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Expanded Onboarding State
    @Published var currency: String = "₺" // Default
    @Published var gender: String = "Belirtmek İstemiyorum"
    
    // Wallet Details
    @Published var walletName: String = "Cüzdanım"
    @Published var walletType: WalletType = .personal
    @Published var walletContext: WalletContext = .budget
    @Published var initialBalance: String = ""
    
    // Limits & Goals
    @Published var spendingLimit: String = ""
    @Published var savingsGoal: String = ""
    
    // Notifications
    @Published var isNotificationEnabled: Bool = false
    
    private var createdWallet: Wallet?
    
    // MARK: - Functions
    
    func checkUsernameUnique() {
        searchTask?.cancel()
        isUsernameAvailable = nil
        
        guard !username.isEmpty, username.count >= 3 else {
            return
        }
        
        isCheckingUsername = true
        
        searchTask = Task {
            // Wait for user to stop typing
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            
            if Task.isCancelled { return }
            
            do {
                let querySnapshot = try await db.collection("users")
                    .whereField("username", isEqualTo: username)
                    .getDocuments()
                
                DispatchQueue.main.async {
                    self.isCheckingUsername = false
                    self.isUsernameAvailable = querySnapshot.documents.isEmpty
                }
            } catch {
                DispatchQueue.main.async {
                    self.isCheckingUsername = false
                    self.errorMessage = "Kullanıcı adı kontrol hatası: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Step 1: Create User Profile
    func saveUserProfile() async -> Bool {
        guard let authUser = Auth.auth().currentUser else {
            self.errorMessage = "Oturum açmış kullanıcı bulunamadı."
            return false
        }
        
        guard let isAvailable = isUsernameAvailable, isAvailable else {
            self.errorMessage = "Lütfen geçerli ve benzersiz bir kullanıcı adı seçin."
            return false
        }
        
        self.isLoading = true
        
        let newUser = User(
            uid: authUser.uid,
            email: authUser.email ?? "",
            username: username,
            displayName: displayName.isEmpty ? nil : displayName,
            photoURL: authUser.photoURL?.absoluteString,
            isPro: false,
            currency: currency,
            gender: gender
        )
        
        do {
            try self.db.collection("users").document(authUser.uid).setData(from: newUser)
            
            // Firebase Auth profilini de güncelle (Önemli fix)
            let changeRequest = authUser.createProfileChangeRequest()
            changeRequest.displayName = newUser.displayName
            try? await changeRequest.commitChanges()
            
            // Don't stop loading here, continue to next steps in flow usually
            // but for step-by-step, we might return true
            self.isLoading = false
            return true
        } catch {
            self.isLoading = false
            self.errorMessage = "Profil kaydedilemedi: \(error.localizedDescription)"
            return false
        }
    }
    
    // Step 2 & 3: Create Wallet and Set Limits
    func createInitialWallet() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        self.isLoading = true
        
        do {
            // 1. Create Wallet
            var newWallet = try await FirestoreService.shared.createWallet(
                name: walletName.isEmpty ? "Cüzdanım" : walletName,
                type: walletType,
                context: walletContext,
                performAsUser: uid
            )
            
            // 2. Add Initial Balance (if > 0)
            if let balance = Double(initialBalance), balance > 0, let walletId = newWallet.id {
                let transaction = Transaction(
                    amount: balance,
                    currency: currency,
                    date: Date(),
                    type: .income,
                    categoryName: "Diğer Gelirler",
                    subCategoryName: "Açılış Bakiyesi",
                    createdBy: uid,
                    note: "Cüzdan açılış bakiyesi",
                    isRecurring: false,
                    createdByUsername: username
                )
                try await FirestoreService.shared.addTransaction(walletId: walletId, transaction: transaction)
            }
            
            // 3. Set Limits & Goals
            if let limit = Double(spendingLimit), limit > 0 {
                newWallet.monthlyLimit = limit
            }
            
            if let goal = Double(savingsGoal), goal > 0 {
                newWallet.savingsGoal = goal
            }
            
            // Update wallet if limits changed
            if newWallet.monthlyLimit != nil || newWallet.savingsGoal != nil {
                try await FirestoreService.shared.updateWallet(newWallet)
            }
            
            // 4. Handle Notification Permission (Logic usually in View, but we track state)
            if isNotificationEnabled {
                // We assume view handled the actual permission request to OS
                // Here we might save a preference if needed
            }
            
            // 5. Select this wallet
            await MainActor.run {
                WalletManager.shared.selectWallet(newWallet)
            }
            
            self.isLoading = false
            return true
            
        } catch {
            self.isLoading = false
            self.errorMessage = "Cüzdan oluşturulamadı: \(error.localizedDescription)"
            return false
        }
    }
}
