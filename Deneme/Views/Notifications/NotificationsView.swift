import SwiftUI
import Combine
import FirebaseAuth

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
                
                if !viewModel.permissionRequests.isEmpty {
                    Section(header: Text("Yetki İstekleri")) {
                        ForEach(viewModel.permissionRequests) { request in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(request.walletName)")
                                        .font(.headline)
                                    Text("\(request.fromUsername) düzenleme yetkisi istiyor")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    Task { await viewModel.respondToPermission(request, accept: true) }
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                }
                                .buttonStyle(.borderless)
                                
                                Button(action: {
                                    Task { await viewModel.respondToPermission(request, accept: false) }
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
                Task { await viewModel.refresh() }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}



#Preview {
    NotificationsView()
}
