import Foundation
import Combine
import FirebaseAuth

@MainActor
class WalletDetailViewModel: ObservableObject {
    @Published var members: [User] = []
    @Published var permissions: [String: String] = [:] // uid: role map
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Dependencies
    private let firestoreService = FirestoreService.shared
    
    // 1. Fetch Members (Fresh data guarantee)
    func fetchMembers(for wallet: Wallet) async {
        guard let walletId = wallet.id else { return }
        await refreshMembers(walletId: walletId)
    }
    
    // 2. Invite Member
    func inviteMember(username: String, to wallet: Wallet) async -> Bool {
        let cleanUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let walletId = wallet.id, !cleanUsername.isEmpty else { return false }
        
        // Get Current User info for the invite
        guard let currentUser = AuthenticationManager.shared.user else { return false }
        let currentUsername = currentUser.displayName ?? "Kullanıcı"
        let fromUser = User(uid: currentUser.uid, email: currentUser.email ?? "", username: currentUsername, isPro: false)
        
        isLoading = true
        errorMessage = nil
        
        do {
            // A. Find User
            guard let userToInvite = try await firestoreService.findUser(byUsername: cleanUsername) else {
                errorMessage = "Kullanıcı bulunamadı."
                isLoading = false
                return false
            }
            
            // B. Check if already active member
            // We use the local 'members' list which should be fresh, OR check the passed wallet object if trustable.
            // Better: Check the wallet's list from our fresh fetch.
            // If the user ID is in our fetched members list with a role that is NOT pending? 
            // Actually FirestoreService logic checks duplicates usually, but let's be safe.
            if members.contains(where: { $0.uid == userToInvite.uid }) {
                // If they are pending, we might want to allow re-sending invite?
                // For now, block if they are in the list.
                 errorMessage = "Kullanıcı zaten listede (veya davetli)."
                 isLoading = false
                 return false
            }
            
            // C. Send Invite (Service handles: Add to Members as Pending + Create Invite Doc)
            try await firestoreService.sendInvite(
                walletId: walletId,
                walletName: wallet.name,
                toUser: userToInvite,
                fromUser: fromUser,
                role: "editor" // Default to editor, but they will be 'pending' status first
            )
            
            // D. Refresh immediately to show "Davet Edildi" in the list
            await refreshMembers(walletId: walletId)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Hata: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // 3. Update Role
    func updateMemberRole(wallet: Wallet, userId: String, newRole: String) async {
        guard let walletId = wallet.id else { return }
        
        do {
            try await firestoreService.updateMemberRole(walletId: walletId, userId: userId, newRole: newRole)
            await refreshMembers(walletId: walletId)
        } catch {
            errorMessage = "Rol güncellenemedi: \(error.localizedDescription)"
        }
    }
    
    // 4. Remove Member
    func removeMember(userId: String, from wallet: Wallet) async {
        guard let walletId = wallet.id else { return }
        
        do {
            try await firestoreService.removeMember(walletId: walletId, userId: userId)
            await refreshMembers(walletId: walletId)
        } catch {
            errorMessage = "Üye çıkarılamadı: \(error.localizedDescription)"
        }
    }
    
    // 5. Delete Wallet
    func deleteWallet(_ wallet: Wallet) async -> Bool {
        guard let walletId = wallet.id else { return false }
        isLoading = true
        do {
            try await firestoreService.deleteWallet(walletId: walletId)
            // Instant UI Update
            await MainActor.run {
                WalletManager.shared.removeWallet(id: walletId)
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Cüzdan silinemedi: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func leaveWallet(_ wallet: Wallet) async -> Bool {
        guard let walletId = wallet.id, let myUid = AuthenticationManager.shared.user?.uid else { return false }
        isLoading = true
        do {
            try await firestoreService.leaveWallet(walletId: walletId, userId: myUid)
            // Instant UI Update
            await MainActor.run {
                WalletManager.shared.removeWallet(id: walletId)
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Ayrılamadı: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // Helper: Refresh Members from DB
    private func refreshMembers(walletId: String) async {
        do {
            // 1. Get fresh wallet object
            let freshWallet = try await firestoreService.getWallet(id: walletId)
            
            // 2. Update permissions map so UI knows who is pending
            self.permissions = freshWallet.permissions
            
            // 3. Get user objects for all members
            let userList = try await firestoreService.fetchUsers(uids: freshWallet.members)
            
            self.members = userList
        } catch {
            // If wallet is deleted or error, clear list
            print("Refresh Error: \(error.localizedDescription)")
        }
    }
}
