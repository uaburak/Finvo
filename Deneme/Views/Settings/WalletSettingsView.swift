import SwiftUI

struct WalletSettingsView: View {
    @StateObject var viewModel: WalletSettingsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Cüzdan Bilgileri")) {
                Text(viewModel.wallet.name)
                    .font(.headline)
                
                HStack {
                    Text("Tip")
                    Spacer()
                    Text(viewModel.wallet.type == .personal ? "Kişisel" : "Paylaşımlı")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Üye Ekle")) {
                HStack {
                    TextField("Kullanıcı Adı", text: $viewModel.inviteUsername)
                        .textInputAutocapitalization(.never)
                    
                    Button("Davet Et") {
                        Task { await viewModel.inviteUser() }
                    }
                    .disabled(viewModel.inviteUsername.isEmpty || viewModel.isInviting)
                }
                
                if let message = viewModel.inviteMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("Hata") || message.contains("bulunamadı") ? .red : .green)
                }
            }
            
            Section(header: Text("Üyeler")) {
                ForEach(viewModel.wallet.members, id: \.self) { userId in
                    HStack {
                        VStack(alignment: .leading) {
                            if let user = viewModel.membersDetails.first(where: { $0.uid == userId }) {
                                Text(user.username)
                                    .font(.body)
                                if let disp = user.displayName {
                                    Text(disp)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(userId) // Fallback
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(roleText(for: userId))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Role Management (Only Owner usually)
                        // For simplicity, showing a menu for everyone for now, but logical check needed.
                        Menu("Yönet") {
                            Button("Yönetici Yap") {
                                Task { await viewModel.updateRole(userId: userId, newRole: "admin") }
                            }
                            Button("İzleyici Yap") {
                                Task { await viewModel.updateRole(userId: userId, newRole: "viewer") }
                            }
                            Button("Çıkar", role: .destructive) {
                                Task { await viewModel.removeMember(userId: userId) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Cüzdan Ayarları")
    }
    
    func roleText(for userId: String) -> String {
        guard let role = viewModel.wallet.permissions[userId] else { return "Bilinmeyen" }
        switch role {
        case "owner": return "Sahip"
        case "admin": return "Yönetici"
        case "viewer": return "İzleyici"
        default: return role
        }
    }
}
