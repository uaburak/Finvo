import Foundation
import Combine
import FirebaseAuth
// Ensure AuthenticationManager is accessible, it's not a framework but a project file, so no import needed for it usually.
// But check imports.
import Combine
import FirebaseAuth

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var invites: [Invite] = []
    @Published var permissionRequests: [PermissionRequest] = []
    
    private let firestoreService = FirestoreService.shared
    
    func refresh() async {
        await fetchInvites()
        await fetchRequests()
    }
    
    func fetchInvites() async {
        guard let uid = AuthenticationManager.shared.user?.uid else { return }
        do {
            self.invites = try await firestoreService.fetchPendingInvites(forUser: uid)
        } catch {
            print("Error fetching invites: \(error)")
        }
    }
    
    func fetchRequests() async {
        guard let uid = AuthenticationManager.shared.user?.uid else { return }
        do {
            self.permissionRequests = try await firestoreService.fetchPermissionRequests(forOwner: uid)
        } catch {
            print("Error fetching requests: \(error)")
        }
    }
    
    func accept(_ invite: Invite) async {
        try? await firestoreService.respondToInvite(invite, accept: true)
        await fetchInvites()
    }
    
    func reject(_ invite: Invite) async {
        try? await firestoreService.respondToInvite(invite, accept: false)
        await fetchInvites()
    }
    
    func respondToPermission(_ request: PermissionRequest, accept: Bool) async {
        try? await firestoreService.respondToPermissionRequest(request, accept: accept)
        await fetchRequests()
    }
}
