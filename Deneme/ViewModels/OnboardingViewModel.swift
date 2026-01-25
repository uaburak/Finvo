import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var displayName: String = ""
    @Published var isUsernameAvailable: Bool? = nil // nil: not checked, true: available, false: taken
    @Published var isCheckingUsername: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    // Debounce timer for username check
    private var searchTask: Task<Void, Never>?
    
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
            isPro: false
        )
        
        do {
            try self.db.collection("users").document(authUser.uid).setData(from: newUser)
            self.isLoading = false
            return true
        } catch {
            self.isLoading = false
            self.errorMessage = "Profil kaydedilemedi: \(error.localizedDescription)"
            return false
        }
    }
}
