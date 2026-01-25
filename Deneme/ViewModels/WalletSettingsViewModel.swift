import Foundation
import Combine
import FirebaseAuth

@MainActor
class WalletSettingsViewModel: ObservableObject {
    @Published var wallet: Wallet
    @Published var membersDetails: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var inviteUsername: String = ""
    @Published var isInviting: Bool = false
    @Published var inviteMessage: String?
    
    // Dependencies
    private let firestoreService = FirestoreService.shared
    
    init(wallet: Wallet) {
        self.wallet = wallet
        Task { await fetchMembersDetails() }
    }
    
    func fetchMembersDetails() async {
        isLoading = true
        do {
            let members = try await firestoreService.fetchUsers(uids: wallet.members)
            self.membersDetails = members
        } catch {
            print("Error fetching members: \(error)") // Silent fail or show alert?
        }
        isLoading = false
    }
    
    func inviteUser() async {
        guard !inviteUsername.isEmpty else { return }
        isInviting = true
        inviteMessage = nil
        
        do {
            // 1. Find User to invite
            if let userToInvite = try await firestoreService.findUser(byUsername: inviteUsername) {
                // 2. Check if already member
                if wallet.members.contains(userToInvite.uid) {
                    inviteMessage = "Bu kullanıcı zaten üye."
                } else {
                    // 3. Send Invite instead of direct add
                    // Fetch current user details for the invitation
                    guard let currentUid = AuthenticationManager.shared.user?.uid else { return }
                    let senders = try await firestoreService.fetchUsers(uids: [currentUid])
                    guard let sender = senders.first else {
                         inviteMessage = "Gönderen bilgisi alınamadı."
                         return 
                    }
                    
                    try await firestoreService.sendInvite(
                        walletId: wallet.id!,
                        walletName: wallet.name,
                        toUser: userToInvite,
                        fromUser: sender,
                        role: "viewer"
                    )
                    
                    inviteMessage = "Davetiye gönderildi."
                }
            } else {
                inviteMessage = "Kullanıcı bulunamadı."
            }
        } catch {
            inviteMessage = "Hata: \(error.localizedDescription)"
        }
        
        isInviting = false
    }
    
    func removeMember(userId: String) async {
        guard let walletId = wallet.id else { return }
        do {
            try await firestoreService.removeMember(walletId: walletId, userId: userId)
            if let index = wallet.members.firstIndex(of: userId) {
                wallet.members.remove(at: index)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateRole(userId: String, newRole: String) async {
        guard let walletId = wallet.id else { return }
        do {
            try await firestoreService.updateMemberRole(walletId: walletId, userId: userId, newRole: newRole)
            wallet.permissions[userId] = newRole
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
