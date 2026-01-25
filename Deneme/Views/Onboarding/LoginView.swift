import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var errorMessage: String?
    
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
                    request.requestedScopes = [.fullName, .email]
                    // Here you would also generate a nonce for Firebase Auth
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        // Handle authentication via AuthManager
                        // verify logic would be in authManager
                        print("Apple Sign In Success: \(authResults)")
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            )
            .frame(height: 50)
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
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            Spacer().frame(height: 40)
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
}
