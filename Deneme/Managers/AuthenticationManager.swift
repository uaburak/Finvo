import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated: Bool = false
    @Published var isProfileComplete: Bool = false
    
    private let db = Firestore.firestore()
    
    static let shared = AuthenticationManager()
    
    private init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = self.user != nil
        
        // Kimlik durumu değişikliklerini dinle
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.user = user
            self.isAuthenticated = user != nil
            if user != nil {
                Task {
                    await self.checkUserProfile()
                }
            } else {
                self.isProfileComplete = false
            }
        }
    }
    
    // Kullanıcının Firestore'da profil kaydı olup olmadığını kontrol eder
    func checkUserProfile() async {
        guard let uid = user?.uid else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            self.isProfileComplete = doc.exists
        } catch {
            print("Kullanıcı profili kontrol edilirken hata oluştu: \(error)")
        }
    }
    
    // Google ile Giriş Yap
    func signInWithGoogle() async throws {
        // 1. Root View Controller'ı bul (Google ekranını üzerinde açmak için)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Root View Controller bulunamadı.")
            return
        }

        // 2. Google SDK üzerinden giriş akışını başlat
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = gidSignInResult.user
        
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID Token eksik"])
        }
        let accessToken = user.accessToken.tokenString

        // 3. Firebase kimlik bilgisi oluştur
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        // 4. Firebase'e giriş yap
        try await Auth.auth().signIn(with: credential)
    }
    
    // Apple ile Giriş Yap (UI'dan gelen credential ile çalışır)
    func signInWithApple(credential: AuthCredential) async throws {
        try await Auth.auth().signIn(with: credential)
    }
    
    // Çıkış Yap
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // Hesabı Sil
    func deleteAccount() async throws {
        guard let user = user else { return }
        try await user.delete()
    }
}
