import SwiftUI
import FirebaseAuth

struct CreateWalletView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var type: WalletType = .personal
    @State private var context: WalletContext = .budget
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Dependencies
    private let firestoreService = FirestoreService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cüzdan Detayları")) {
                    TextField("Cüzdan Adı (Örn: Nakit, Ev Bütçesi)", text: $name)
                    
                    Picker("Tür", selection: $type) {
                        Text("Kişisel").tag(WalletType.personal)
                        Text("Paylaşımlı").tag(WalletType.shared)
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Kategori", selection: $context) {
                        Text("Bütçe").tag(WalletContext.budget)
                        Text("Yapılacaklar").tag(WalletContext.todo)
                    }
                    .pickerStyle(.segmented)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: createWallet) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Cüzdan Oluştur")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .navigationTitle("Yeni Cüzdan")
        }
    }
    
    private func createWallet() {
        guard let uid = authManager.user?.uid else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await firestoreService.createWallet(name: name, type: type, context: context, performAsUser: uid)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = "Hata: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    CreateWalletView()
        .environmentObject(AuthenticationManager.shared)
}
