import SwiftUI
import Combine
import FirebaseAuth

struct WalletDetailView: View {
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = WalletDetailViewModel()
    
    // The wallet structure passed in might be stale, so we rely on ViewModel for data.
    // We only use this for initial ID and static info like OwnerID (which rarely changes).
    let initialWallet: Wallet
    
    @State private var showAddMemberSheet = false
    @State private var newMemberUsername = ""
    @State private var showInviteSentAlert = false
    
    var isOwner: Bool {
        guard let uid = AuthenticationManager.shared.user?.uid else { return false }
        return initialWallet.ownerId == uid
    }
    
    var body: some View {
        Form {
            // --- Info Section ---
            Section(header: Text("Cüzdan Bilgileri")) {
                HStack {
                    Text("Cüzdan Adı")
                    Spacer()
                    Text(initialWallet.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Tür")
                    Spacer()
                    Text(initialWallet.type.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
            }
            
            // --- Members Section ---
            Section(header: Text("Üyeler")) {
                ForEach(viewModel.members) { member in
                    memberRow(member)
                }
                
                if isOwner {
                    Button {
                        showAddMemberSheet = true
                    } label: {
                        Label("Üye Davet Et", systemImage: "person.badge.plus")
                            .foregroundColor(.blue)
                    }
                    .alert("Üye Davet Et", isPresented: $showAddMemberSheet) {
                        TextField("Kullanıcı Adı", text: $newMemberUsername)
                        Button("İptal", role: .cancel) { newMemberUsername = "" }
                        Button("Davet Gönder") {
                            Task {
                                let success = await viewModel.inviteMember(username: newMemberUsername, to: initialWallet)
                                if success {
                                    newMemberUsername = ""
                                    showInviteSentAlert = true
                                }
                            }
                        }
                    } message: {
                        Text("Davet etmek istediğiniz kişinin kullanıcı adını girin.")
                    }
                }
            }
            
            // --- Actions Section ---
            Section {
                if isOwner {
                    Button(role: .destructive) {
                        Task {
                            if await viewModel.deleteWallet(initialWallet) {
                                dismiss()
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
                             if await viewModel.leaveWallet(initialWallet) {
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
        .alert("Davet Gönderildi", isPresented: $showInviteSentAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text("Kullanıcıya bildirim gönderildi. Kabul ettiğinde eklenecektir.")
        }
        .onAppear {
            Task { await viewModel.fetchMembers(for: initialWallet) }
        }
    }
    
    // Subview for Member Row to keep body clean
    private func memberRow(_ member: User) -> some View {
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
            
            // Role Logic
            let role = viewModel.permissions[member.uid] ?? "editor"
            let isMemberOwner = (member.uid == initialWallet.ownerId)
            
            if isMemberOwner {
                Text("Yönetici")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .bold()
            } else if role == "pending" {
                Text("Davet Edildi")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .italic()
                
                if isOwner {
                    // Option to cancel invite could be added here
                }
            } else {
                // Active Member (Editor/Viewer)
                if isOwner {
                    // Owner can change roles
                    Menu {
                        Button("Düzenleyici Yap") {
                             Task { await viewModel.updateMemberRole(wallet: initialWallet, userId: member.uid, newRole: "editor") }
                        }
                        Button("İzleyici Yap") {
                             Task { await viewModel.updateMemberRole(wallet: initialWallet, userId: member.uid, newRole: "viewer") }
                        }
                        Divider()
                        Button("Çıkar", role: .destructive) {
                             Task { await viewModel.removeMember(userId: member.uid, from: initialWallet) }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(role == "editor" ? "Düzenleyici" : "İzleyici")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                } else {
                    // Viewer sees role text
                    Text(role == "editor" ? "Düzenleyici" : "İzleyici")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
