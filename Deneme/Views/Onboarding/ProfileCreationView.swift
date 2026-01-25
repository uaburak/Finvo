import SwiftUI

struct ProfileCreationView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Profilini Oluştur")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Kullanıcı Adı")
                    .font(.headline)
                
                TextField("kullaniciadi", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: viewModel.username) {
                        viewModel.checkUsernameUnique()
                    }
                
                if viewModel.isCheckingUsername {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let isAvailable = viewModel.isUsernameAvailable {
                    Text(isAvailable ? "Kullanıcı adı müsait ✅" : "Bu kullanıcı adı alınmış ❌")
                        .font(.caption)
                        .foregroundColor(isAvailable ? .green : .red)
                }
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Görünen İsim (Opsiyonel)")
                    .font(.headline)
                
                TextField("Ad Soyad", text: $viewModel.displayName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    if await viewModel.saveUserProfile() {
                        await authManager.fetchUserProfile()
                    }
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Tamamla")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.isUsernameAvailable == true ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(viewModel.isUsernameAvailable != true || viewModel.isLoading)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
    }
}

#Preview {
    ProfileCreationView()
}
