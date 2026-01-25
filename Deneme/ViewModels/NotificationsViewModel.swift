import Foundation
import Combine
import FirebaseAuth

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var invites: [Invite] = []
    @Published var appNotifications: [AppNotification] = []
    @Published var isLoading = false
    
    // We can keep PermissionRequests if needed, but primary focus is invites.
    @Published var permissionRequests: [PermissionRequest] = []
    
    private let firestoreService = FirestoreService.shared
    private let authManager = AuthenticationManager.shared
    
    func refresh() async {
        isLoading = true
        await fetchInvites()
        await fetchAppNotifications()
        // await fetchRequests() // Keep if needed
        isLoading = false
    }
    
    func fetchInvites() async {
        guard let uid = authManager.user?.uid else { return }
        do {
            let fetched = try await firestoreService.fetchPendingInvites(forUser: uid)
            self.invites = fetched
        } catch {
            print("Davetler yüklenemedi: \(error)")
        }
    }
    
    func fetchAppNotifications() async {
        guard let uid = authManager.user?.uid else { return }
        do {
            let fetched = try await firestoreService.fetchNotifications(forUser: uid)
            self.appNotifications = fetched
        } catch {
            print("Bildirimler yüklenemedi: \(error)")
        }
    }
    
    // Action: Accept Invite
    func accept(_ invite: Invite) async {
        do {
            try await firestoreService.respondToInvite(invite, accept: true)
            // Refresh logic to remove from list
            await fetchInvites()
        } catch {
            print("Kabul hatası: \(error)")
        }
    }
    
    // Action: Reject Invite
    func reject(_ invite: Invite) async {
        do {
            try await firestoreService.respondToInvite(invite, accept: false)
            await fetchInvites()
        } catch {
            print("Ret hatası: \(error)")
        }
    }
    
    func markRead(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        try? await firestoreService.markNotificationRead(id)
        if let index = appNotifications.firstIndex(where: { $0.id == id }) {
            appNotifications[index].isRead = true
        }
    }
    
    // Permission requests logic (Optional based on rewrite scope, but keeping for compatibility)
    func fetchRequests() async {
        guard let uid = authManager.user?.uid else { return }
        try? self.permissionRequests = await firestoreService.fetchPermissionRequests(forOwner: uid)
    }
    func respondToPermission(_ request: PermissionRequest, accept: Bool) async {
           try? await firestoreService.respondToPermissionRequest(request, accept: accept)
           await fetchRequests()
    }
}
