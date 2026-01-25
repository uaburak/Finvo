import SwiftUI
import FirebaseAuth

struct CreateWalletView: View {
    @Environment(\.dismiss) var dismiss
    
    // Inputs
    @State private var name: String = ""
    @State private var type: WalletType = .personal
    @State private var context: WalletContext = .budget
    
    // State
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Dependencies
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var walletManager: WalletManager
    private let firestoreService = FirestoreService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cüzdan Detayları")) {
                    TextField("Cüzdan Adı (Örn: Nakit, Tatil)", text: $name)
                    
                    Picker("Tür", selection: $type) {
                        Text("Kişisel").tag(WalletType.personal)
                        Text("Paylaşımlı").tag(WalletType.shared)
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Kategori", selection: $context) {
                        Text("Bütçe").tag(WalletContext.budget)
                        Text("Yapılacaklar").tag(WalletContext.todo)
                        Text("Birikim").tag(WalletContext.savings)
                        Text("Seyahat").tag(WalletContext.travel)
                    }
                    .pickerStyle(.segmented)
                }
                
                if let error = errorMessage {
                     Section {
                         Text(error).foregroundColor(.red)
                     }
                }
                
                Section {
                    Button(action: createWalletAction) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Oluştur")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .navigationTitle("Yeni Cüzdan")
        }
    }
    
    private func createWalletAction() {
        guard let uid = authManager.user?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Create in Firestore & Get Object
                let newWallet = try await firestoreService.createWallet(
                    name: name,
                    type: type,
                    context: context,
                    performAsUser: uid
                )
                
                // 2. Auto-Select in Manager (Main Thread)
                await MainActor.run {
                    walletManager.selectWallet(newWallet)
                }
                
                // 3. Dismiss
                isLoading = false
                dismiss()
                
            } catch {
                isLoading = false
                errorMessage = "Hata: \(error.localizedDescription)"
            }
        }
    }
}
