import SwiftUI
import Combine
import FirebaseAuth

struct WalletDetailView: View {
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = WalletDetailViewModel()
    
    let wallet: Wallet
    
    @State private var showAddMemberSheet = false
    @State private var newMemberUsername = ""
    @State private var isAddingMember = false
    @State private var addMemberError: String?
    
    var isOwner: Bool {
        guard let uid = AuthenticationManager.shared.user?.uid else { return false }
        return wallet.isOwner(userId: uid)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Cüzdan Bilgileri")) {
                HStack {
                    Text("Cüzdan Adı")
                    Spacer()
                    Text(wallet.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Tür")
                    Spacer()
                    Text(wallet.type.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Üyeler")) {
                ForEach(viewModel.members) { member in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(member.username)
                                .font(.body)
                            if let name = member.displayName {
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if wallet.isOwner(userId: member.uid) {
                            Text("Yönetici")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else if isOwner {
                            // Menu to change role
                            Menu {
                                Button {
                                    Task { await viewModel.updateMemberRole(wallet: wallet, userId: member.uid, newRole: "editor") }
                                } label: {
                                    if (wallet.permissions[member.uid] ?? "editor") == "editor" {
                                        Label("Düzenleyici (Tam Yetki)", systemImage: "checkmark")
                                    } else {
                                        Text("Düzenleyici (Tam Yetki)")
                                    }
                                }
                                
                                Button {
                                    Task { await viewModel.updateMemberRole(wallet: wallet, userId: member.uid, newRole: "viewer") }
                                } label: {
                                    if (wallet.permissions[member.uid]) == "viewer" {
                                        Label("İzleyici (Sadece Görme)", systemImage: "checkmark")
                                    } else {
                                        Text("İzleyici (Sadece Görme)")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    Task { await viewModel.removeMember(userId: member.uid, from: wallet) }
                                } label: {
                                    Label("Kullanıcıyı Çıkar", systemImage: "minus.circle")
                                }
                                
                            } label: {
                                HStack(spacing: 4) {
                                    Text((wallet.permissions[member.uid] ?? "editor") == "editor" ? "Düzenleyici" : "İzleyici")
                                        .font(.caption)
                                        .foregroundColor((wallet.permissions[member.uid] ?? "editor") == "editor" ? .orange : .gray)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        } else {
                            // View only role for non-owners looking at other members
                            let role = wallet.permissions[member.uid] ?? "editor"
                            Text(role == "editor" ? "Düzenleyici" : "İzleyici")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if isOwner {
                    Button {
                        showAddMemberSheet = true
                    } label: {
                        Label("Üye Ekle", systemImage: "person.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section {
                if isOwner {
                    Button(role: .destructive) {
                        Task {
                            if await viewModel.deleteWallet(wallet) {
                                dismiss() // Go back to list
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Cüzdanı Sil")
                        }
                    }
                } else {
                    Button(role: .destructive) {
                         Task {
                             if await viewModel.leaveWallet(wallet) {
                                 dismiss()
                             }
                         }
                    } label: {
                         if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Cüzdandan Ayrıl")
                        }
                    }
                }
            } footer: {
               if let error = viewModel.errorMessage {
                   Text(error)
                       .foregroundColor(.red)
               }
            }
        }
        .navigationTitle("Cüzdan Ayarları")
        .onAppear {
            Task { await viewModel.fetchMembers(for: wallet) }
        }
        .alert("Üye Ekle", isPresented: $showAddMemberSheet) {
            TextField("Kullanıcı Adı", text: $newMemberUsername)
            Button("İptal", role: .cancel) { newMemberUsername = "" }
            Button("Ekle") {
                Task {
                    await viewModel.addMember(username: newMemberUsername, to: wallet)
                    newMemberUsername = ""
                }
            }
        } message: {
            Text("Eklemek istediğiniz kişinin kullanıcı adını girin.")
        }
    }
}

@MainActor
class WalletDetailViewModel: ObservableObject {
    @Published var members: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService.shared
    
    func fetchMembers(for wallet: Wallet) async {
        do {
            self.members = try await firestoreService.fetchUsers(uids: wallet.members)
        } catch {
            print("Error fetching members: \(error)")
        }
    }
    
    func addMember(username: String, to wallet: Wallet) async {
        guard let walletId = wallet.id else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userToAdd = try await firestoreService.findUser(byUsername: username) else {
                errorMessage = "Kullanıcı bulunamadı."
                isLoading = false
                return
            }
            
            // Check if already member
            if wallet.members.contains(userToAdd.uid) {
                errorMessage = "Kullanıcı zaten cüzdanda."
                isLoading = false
                return
            }
            
            try await firestoreService.addMember(walletId: walletId, userId: userToAdd.uid, role: "editor")
            await fetchMembers(for: wallet) // Refresh list
            isLoading = false
        } catch {
            errorMessage = "Hata: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func removeMember(userId: String, from wallet: Wallet) async {
        guard let walletId = wallet.id else { return }
        // isLoading = true // Don't block UI for tiny action
        
        do {
            try await firestoreService.removeMember(walletId: walletId, userId: userId)
            await fetchMembers(for: wallet)
        } catch {
            errorMessage = "Üye çıkarılamadı: \(error.localizedDescription)"
        }
    }
    
    func deleteWallet(_ wallet: Wallet) async -> Bool {
        guard let walletId = wallet.id else { return false }
        isLoading = true
        do {
            try await firestoreService.deleteWallet(walletId: walletId)
            isLoading = false
            return true
        } catch {
            errorMessage = "Silinemedi: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func leaveWallet(_ wallet: Wallet) async -> Bool {
        guard let walletId = wallet.id, let myUid = AuthenticationManager.shared.user?.uid else { return false }
        isLoading = true
        do {
            try await firestoreService.leaveWallet(walletId: walletId, userId: myUid)
            isLoading = false
            return true
        } catch {
            errorMessage = "Ayrılamadı: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func updateMemberRole(wallet: Wallet, userId: String, newRole: String) async {
        guard let walletId = wallet.id else { return }
        // Optimistic UI update could be done here, but for now we wait.
        
        do {
            try await firestoreService.updateMemberRole(walletId: walletId, userId: userId, newRole: newRole)
            await fetchMembers(for: wallet)
        } catch {
            errorMessage = "Rol güncellenemedi: \(error.localizedDescription)"
        }
    }
}
