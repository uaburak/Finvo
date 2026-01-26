import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("appLanguage") private var appLanguage: String = "tr"
    
    @State private var showRepairAlert = false
    @State private var showRepairResult = false
    @State private var repairResult = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Section: Account
                Section(header: Text("Hesap")) {
                    HStack {
                        if let photoURL = authManager.user?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(authManager.user?.displayName ?? "Kullanıcı")
                                .font(.headline)
                            Text(authManager.user?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Button("Profili Düzenle") {
                        // Navigate to profile edit
                    }
                }
                
                // Section: App Preferences
                Section(header: Text("Uygulama Tercihleri")) {
                    Picker("Dil", selection: $appLanguage) {
                        Text("Türkçe").tag("tr")
                        Text("English").tag("en")
                        Text("Deutsch").tag("de")
                        Text("Русский").tag("ru")
                    }
                }
                
                // Section: Data & Privacy
                Section(header: Text("Veri Yönetimi")) {
                    Button(action: {
                        // Export Action
                    }) {
                        Label("Verileri Dışa Aktar (JSON)", systemImage: "square.and.arrow.up")
                    }
                }
                
                // Section: Support & About
                Section(header: Text("Hakkında")) {
                    HStack {
                        Text("Sürüm")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    Link("Gizlilik Politikası", destination: URL(string: "https://example.com/privacy")!)
                }
                
                // Section: Test / Developer
                Section(header: Text("Test / Geliştirici")) {
                    Toggle("Pro Üyelik (Simülasyon)", isOn: Binding(
                        get: { authManager.currentUserProfile?.isPro ?? false },
                        set: { newValue in
                            Task {
                                await authManager.updateProStatus(isPro: newValue)
                            }
                        }
                    ))
                    .tint(.blue)
                }
                
                // Section: Logout
                Section {
                    Button(role: .destructive) {
                        do {
                            try authManager.signOut()
                        } catch {
                            print("Error signing out: \(error)")
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Çıkış Yap")
                            Spacer()
                        }
                    }
                }
            }

            .navigationTitle("Ayarlar")
            .alert("Veri Onarımı", isPresented: $showRepairAlert) {
                Button("Başlat") {
                    Task {
                        do {
                            let result = try await FirestoreService.shared.repairTransactions()
                            repairResult = result
                            showRepairResult = true
                        } catch {
                            repairResult = "Hata: \(error.localizedDescription)"
                            showRepairResult = true
                        }
                    }
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Bu işlem veritabanındaki eski kayıtları yeni formata uygun hale getirecek. Devam etmek istiyor musunuz?")
            }
            .alert("Sonuç", isPresented: $showRepairResult) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(repairResult)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager.shared)
}
