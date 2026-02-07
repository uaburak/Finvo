import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var errorMessage: String?
    @State private var currentNonce: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "banknote.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("Finvo'ya Hoşgeldiniz")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Bütçenizi kolayca yönetin.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .padding()
            }
            
            // Sign in with Apple Button
            SignInWithAppleButton(
                onRequest: { request in
                    let nonce = authManager.randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = authManager.sha256(nonce)
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            guard let nonce = currentNonce else {
                                fatalError("Invalid state: A login callback was received, but no login request was sent.")
                            }
                            guard let appleIDToken = appleIDCredential.identityToken else {
                                print("Unable to fetch identity token")
                                return
                            }
                            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                                return
                            }
                            
                            Task {
                                do {
                                    // Firebase ile giriş yap (fullName credential içinde gönderiliyor)
                                    try await authManager.signInWithApple(
                                        idToken: idTokenString,
                                        nonce: nonce,
                                        fullName: appleIDCredential.fullName
                                    )
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                            
                        default:
                            break
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            )
            .signInWithAppleButtonStyle(.white) // Use .black for dark mode or based on color scheme
            .frame(height: 50)
            .clipShape(Capsule())
            .padding(.horizontal)
            
            // Google Sign In Button (Custom UI)
            Button(action: {
                Task {
                    do {
                        try await authManager.signInWithGoogle()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }) {
                HStack {
                    Image(systemName: "globe") // Placeholder for Google Logo
                    Text("Google ile Giriş Yap")
                }
                .font(.headline)
                .foregroundColor(.black) // Google text color usually
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            Spacer().frame(height: 40)
            
            // Gizlilik Politikası ve Şartlar (Apple Review için önemlidir)
            if #available(iOS 16.0, *) {
                VStack(spacing: 8) {
                    Text("Devam ederek şunları kabul etmiş olursunuz:")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    VStack(spacing: 4) {
                        Link("Kullanım Şartları", destination: URL(string: "https://finvo.app/terms")!)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Link("Gizlilik Politikası", destination: URL(string: "https://finvo.app/privacy")!)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}
