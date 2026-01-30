import SwiftUI

struct WalletCreateSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var type: WalletType = .personal
    @State private var context: WalletContext = .budget
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("Cüzdan Detayları")) {
                TextField("Cüzdan Adı", text: $name)
                
                Picker("Tip", selection: $type) {
                    Text("Kişisel").tag(WalletType.personal)
                    Text("Paylaşımlı").tag(WalletType.shared)
                }
                
                Picker("Bağlam", selection: $context) {
                    Text("Bütçe").tag(WalletContext.budget)
                    Text("Yapılacaklar").tag(WalletContext.todo)
                    Text("Birikim").tag(WalletContext.savings)
                    Text("Seyahat").tag(WalletContext.travel)
                }
            }
            
            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Yeni Cüzdan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Oluştur") {
                    createWallet()
                }
                .disabled(name.isEmpty || isLoading)
            }
        }
    }
    
    private func createWallet() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await FirestoreService.shared.createWallet(name: name, type: type, context: context)
                DispatchQueue.main.async {
                    isLoading = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
