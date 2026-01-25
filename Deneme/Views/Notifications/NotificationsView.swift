import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.invites.isEmpty {
                    Text("Bekleyen davetiniz yok.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Section(header: Text("Davetler")) {
                        ForEach(viewModel.invites) { invite in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(invite.walletName) cüzdanına davet")
                                        .font(.headline)
                                    Text("Gönderen: \(invite.fromUsername)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    Task { await viewModel.accept(invite) }
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                                .buttonStyle(.borderless)
                                
                                Button(action: {
                                    Task { await viewModel.reject(invite) }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Bildirimler")
            .onAppear {
                Task { await viewModel.fetchInvites() }
            }
            .refreshable {
                await viewModel.fetchInvites()
            }
        }
    }
}

#Preview {
    NotificationsView()
}
