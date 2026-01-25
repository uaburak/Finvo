import Foundation
import Combine
import FirebaseAuth

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var invites: [Invite] = []
    @Published var isLoading: Bool = false
    
    private let firestoreService = FirestoreService.shared
    
    func fetchInvites() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            let pending = try await firestoreService.fetchPendingInvites(forUser: uid)
            self.invites = pending
        } catch {
            print("Error fetching invites: \(error)")
        }
        isLoading = false
    }
    
    func accept(_ invite: Invite) async {
        await respond(invite, accept: true)
    }
    
    func reject(_ invite: Invite) async {
        await respond(invite, accept: false)
    }
    
    private func respond(_ invite: Invite, accept: Bool) async {
        do {
            try await firestoreService.respondToInvite(invite, accept: accept)
            // Remove locally
            if let index = invites.firstIndex(where: { $0.id == invite.id }) {
                invites.remove(at: index)
            }
        } catch {
            print("Error responding to invite: \(error)")
        }
    }
}
