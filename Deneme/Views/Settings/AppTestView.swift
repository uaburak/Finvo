import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AppTestView: View {
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    // MARK: - Legacy State
    @State private var isLoading = false
    @State private var statusMessage: String?
    @State private var showDeleteTransactionsAlert = false
    @State private var showResetWalletsAlert = false
    @State private var showNukeAlert = false
    
    // MARK: - Performance & Log State
    @ObservedObject private var logger = DebugLogger.shared
    @State private var perfResults: (writeMs: Double, readMs: Double)? = nil
    @State private var diagnosticResults: [DiagnosticResult] = []
    
    var body: some View {
        Form {
            // MARK: - 🚀 Performans & Sağlık
            Section(header: Text("🚀 Sistem Durumu & Performans")) {
                Button {
                    runPerformanceTest()
                } label: {
                    HStack {
                        Label("Firestore Hız Testi (Ping)", systemImage: "speedometer")
                        Spacer()
                        if let res = perfResults {
                            Text("W:\(Int(res.writeMs))ms R:\(Int(res.readMs))ms")
                                .font(.caption).bold()
                                .foregroundColor(res.writeMs < 100 ? .green : .red)
                        }
                    }
                }
                .disabled(isLoading)
                
                Button {
                    runDiagnostics()
                } label: {
                    Label("Sistem Sağlık Taraması", systemImage: "stethoscope")
                }
                .disabled(isLoading)
                
                if !diagnosticResults.isEmpty {
                    ForEach(diagnosticResults) { result in
                        HStack {
                            Image(systemName: result.status == .passing ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(result.status == .passing ? .green : .orange)
                            VStack(alignment: .leading) {
                                Text(result.name).bold()
                                Text(result.details).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // MARK: - 🎞️ End-to-End Simülasyon
            Section(header: Text("🎞️ Kullanıcı Senaryosu (End-to-End)")) {
                Button {
                    runSimulation()
                } label: {
                    Label("Tam Tur Simülasyon Başlat", systemImage: "play.circle.fill")
                        .foregroundColor(.purple)
                }
                .disabled(isLoading || authManager.user == nil)
                
                Text("Gerçek bir kullanıcı gibi sırayla: Cüzdan Oluşturma -> İşlem Ekleme -> Limit Koyma -> Birikim Hedefi -> Borç Ekleme -> Davet Gönderme adımlarını otomatik test eder.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // MARK: - ⚡️ İleri Seviye Testler
            Section(header: Text("⚡️ İleri Seviye Testler (Stress & Logic)")) {
                Button {
                    runStressTest()
                } label: {
                    Label("Yük Testi: 1000 İşlem Ekle", systemImage: "ant.circle.fill")
                        .foregroundColor(.red)
                }
                .disabled(isLoading || walletManager.selectedWallet == nil)
                
                Button {
                    runConcurrencyTest()
                } label: {
                    Label("Eşzamanlılık (Race Condition) Testi", systemImage: "bolt.horizontal.circle.fill")
                        .foregroundColor(.orange)
                }
                .disabled(isLoading || walletManager.selectedWallet == nil)
                
                Button {
                   runGamificationCheck()
                } label: {
                    Label("Oyunlaştırma & Rozet Kontrolü", systemImage: "trophy.circle.fill")
                        .foregroundColor(.yellow)
                }
                .disabled(isLoading || walletManager.selectedWallet == nil)
            }
            
            // MARK: - 📟 Debug Konsol
            Section(header: Text("📟 Debug Konsol")) {
                 NavigationLink(destination: ConsoleView()) {
                     Label("Canlı Logları İzle", systemImage: "terminal")
                 }
                 
                 Text("Son Log: \(logger.logs.last?.message ?? "Henüz log yok")")
                     .font(.caption)
                     .foregroundColor(.secondary)
                     .lineLimit(1)
            }

            // MARK: - Test Laboratuvarı
            Section(header: Text("🧪 Test Laboratuvarı")) {
                Button {
                    generateTestData()
                } label: {
                    Label("Rastgele Veri Doldur (100 İşlem)", systemImage: "sparkles")
                        .foregroundColor(.blue)
                }
                .disabled(isLoading || walletManager.selectedWallet == nil)
                
                Button {
                    sendTestNotification()
                } label: {
                    Label("Bildirim Testi Gönder", systemImage: "bell.badge")
                        .foregroundColor(.orange)
                }
            }
            
            // MARK: - Temizlik Bölgesi
            Section(header: Text("🧹 Temizlik Bölgesi")) {
                Button(role: .destructive) {
                    deleteTestOnlyData()
                } label: {
                    Label("Sadece 'Test' Verilerini Sil", systemImage: "eraser")
                }
                .disabled(isLoading)
            }
            
            // MARK: - TEHLİKELİ BÖLGE
            Section(header: Text("💀 TEHLİKELİ BÖLGE (DANGER)")) {
                Button(role: .destructive) {
                    showDeleteTransactionsAlert = true
                } label: {
                    Label("SEÇİLİ CÜZDAN: Tüm İşlemleri Sil", systemImage: "trash.slash")
                }
                .disabled(isLoading || walletManager.selectedWallet == nil)
                .alert("Tüm İşlemler Silinecek", isPresented: $showDeleteTransactionsAlert) {
                    Button("SİL", role: .destructive) { deleteAllTransactions() }
                    Button("İptal", role: .cancel) { }
                } message: {
                    Text("Bu işlem seçili cüzdandaki GERÇEK ve TEST tüm verileri kalıcı olarak silecektir. Geri alınamaz.")
                }
                
                Button(role: .destructive) {
                    showResetWalletsAlert = true
                } label: {
                    Label("Tüm Cüzdanları ve Davetleri Sıfırla", systemImage: "folder.badge.minus")
                }
                .disabled(isLoading)
                .alert("Cüzdanlar Sıfırlanacak", isPresented: $showResetWalletsAlert) {
                    Button("SIFIRLA", role: .destructive) { resetWallets() }
                    Button("İptal", role: .cancel) { }
                } message: {
                    Text("Sahibi olduğunuz tüm cüzdanlar silinecek, üyesi olduğunuz cüzdanlardan çıkılacak ve tüm davetler silinecektir.")
                }
                
                Button(role: .destructive) {
                    showNukeAlert = true
                } label: {
                    Label("TÜM KULLANICI VERİLERİNİ SİL (NUKE)", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                }
                .disabled(isLoading)
                .alert("HESAP SIFIRLAMA (NUKE)", isPresented: $showNukeAlert) {
                    Button("ONAYLIYORUM SİL", role: .destructive) { nukeUserData() }
                    Button("İptal", role: .cancel) { }
                } message: {
                    Text("Bu işlem hesabınızı tamamen sıfırlar. Tüm cüzdanlar, işlemler, bildirimler ve ayarlar silinir. Uygulama fabrika ayarlarına döner.")
                }
            }
            
            if let message = statusMessage {
                 Section {
                     Text(message)
                         .font(.caption)
                         .foregroundColor(message.contains("Hata") ? .red : .green)
                         .multilineTextAlignment(.center)
                 }
             }
        }
        .navigationTitle("Geliştirici Paneli")
        .disabled(isLoading)
    }
    
    // MARK: - Actions
    
    private func runPerformanceTest() {
        isLoading = true
        statusMessage = "Hız testi yapılıyor..."
        Task {
            let result = await DiagnosticsService.shared.measureFirestoreLatency()
            perfResults = result
            statusMessage = "✅ Test tamamlandı. W:\(Int(result.writeMs))ms R:\(Int(result.readMs))ms"
            logger.log("Hız Testi: Yazma \(result.writeMs)ms, Okuma \(result.readMs)ms")
            isLoading = false
        }
    }
    
    private func runDiagnostics() {
        guard let walletId = walletManager.selectedWallet?.id else {
            statusMessage = "Hata: Cüzdan seçili değil"
            return
        }
        isLoading = true
        statusMessage = "Sistem taranıyor..."
        Task {
            let integrity = await DiagnosticsService.shared.checkDataIntegrity(walletId: walletId)
            let orphan = await DiagnosticsService.shared.checkOrphanData()
            diagnosticResults = integrity + orphan
            statusMessage = "✅ Tarama bitti. \(diagnosticResults.count) kontrol yapıldı."
            logger.log("Diagnostik Tarama: \(diagnosticResults.count) sonuç bulundu.")
            isLoading = false
        }
    }
    
    private func runSimulation() {
        guard let uid = authManager.user?.uid else { return }
        isLoading = true
        statusMessage = "Simülasyon arka planda çalışıyor..."
        
        // Switch to Console View automatically or just notify
        // For now, let's just run it
        Task {
            await UserSimulationService.shared.runFullSimulation(forUserId: uid)
            statusMessage = "✅ Simülasyon Tamamlandı. Detaylar konsolda."
            isLoading = false
        }
    }
    
    // MARK: - Advanced Actions
    
    private func runStressTest() {
        guard let walletId = walletManager.selectedWallet?.id else { return }
        isLoading = true
        statusMessage = "1000 İşlem basılıyor (Bu biraz sürebilir)..."
        Task {
            do {
                try await TestDataService.shared.generateMassiveData(for: walletId, count: 1000)
                statusMessage = "✅ Yük Testi Bitti. UI performansını kontrol et."
                logger.log("Stress Test: 1000 işlem eklendi.")
            } catch {
                statusMessage = "Hata: \(error.localizedDescription)"
                logger.log("Stress Error: \(error.localizedDescription)", level: .error)
            }
            isLoading = false
        }
    }
    
    private func runConcurrencyTest() {
        guard let walletId = walletManager.selectedWallet?.id else { return }
        isLoading = true
        statusMessage = "Race Condition testi çalışıyor..."
        Task {
            await UserSimulationService.shared.runConcurrencyTest(walletId: walletId)
            statusMessage = "✅ Test komutları gönderildi. Konsolu izleyin."
            isLoading = false
        }
    }
    
    private func runGamificationCheck() {
        guard let walletId = walletManager.selectedWallet?.id else { return }
        isLoading = true
        statusMessage = "Rozetler kontrol ediliyor..."
        Task {
            await UserSimulationService.shared.testGamificationLogic(walletId: walletId)
            statusMessage = "✅ Kontrol bitti. Konsola bakın."
            isLoading = false
        }
    }
    
    private func generateTestData() {
        guard let walletId = walletManager.selectedWallet?.id else { return }
        isLoading = true
        statusMessage = "Veri üretiliyor..."
        
        Task {
            do {
                try await TestDataService.shared.generateTestData(for: walletId)
                statusMessage = "✅ 100 İşlem Eklendi!"
                logger.log("Test: 100 işlem eklendi.")
            } catch {
                statusMessage = "Hata: \(error.localizedDescription)"
                logger.log("Hata (Generate): \(error.localizedDescription)", level: .error)
            }
            isLoading = false
        }
    }
    
    private func deleteTestOnlyData() {
        guard let walletId = walletManager.selectedWallet?.id else { return }
        isLoading = true
        statusMessage = "Test verileri temizleniyor..."
        
        Task {
            do {
                try await TestDataService.shared.deleteTestData(for: walletId)
                statusMessage = "✅ Test verileri temizlendi."
                logger.log("Test: Veriler temizlendi.")
            } catch {
                statusMessage = "Hata: \(error.localizedDescription)"
                logger.log("Hata (Clean): \(error.localizedDescription)", level: .error)
            }
            isLoading = false
        }
    }
    
    private func deleteAllTransactions() {
        guard let walletId = walletManager.selectedWallet?.id else { return }
        isLoading = true
        statusMessage = "Tüm işlemler siliniyor..."
        
        Task {
            do {
                try await TestDataService.shared.deleteAllTransactions(walletId: walletId)
                statusMessage = "✅ Cüzdan temizlendi."
             } catch {
                statusMessage = "Hata: \(error.localizedDescription)"
             }
             isLoading = false
         }
     }
     
     private func resetWallets() {
         guard let uid = authManager.user?.uid else { return }
         isLoading = true
         statusMessage = "Cüzdanlar sıfırlanıyor..."
         
         Task {
             do {
                 try await TestDataService.shared.resetWalletsAndInvites(userId: uid)
                 statusMessage = "✅ Cüzdanlar ve davetler sıfırlandı."
                 // Force refresh
                 walletManager.wallets = [] 
                 walletManager.selectedWallet = nil
             } catch {
                 statusMessage = "Hata: \(error.localizedDescription)"
             }
             isLoading = false
         }
     }
     
     private func nukeUserData() {
         guard let uid = authManager.user?.uid else { return }
         isLoading = true
         statusMessage = "💥 NUKE İŞLEMİ BAŞLATILDI..."
         
         Task {
             do {
                 try await TestDataService.shared.nukeUserData(userId: uid)
                 statusMessage = "✅ Hesap tamamen sıfırlandı."
                 walletManager.wallets = []
                 walletManager.selectedWallet = nil
             } catch {
                 statusMessage = "Hata: \(error.localizedDescription)"
             }
             isLoading = false
         }
     }
     
     private func sendTestNotification() {
         // Mock notification logic
         statusMessage = "🔔 Bildirim gönderildi (Simülasyon)"
         
         guard let uid = authManager.user?.uid else { return }
         Task {
             try? await FirestoreService.shared.sendNotification(
                 toUserId: uid,
                 title: "Test Bildirimi",
                 message: "Bu geliştirici panelinden gönderilen bir test bildirimidir.",
                 type: .system
             )
         }
     }
 }
 
 // MARK: - Console View
 struct ConsoleView: View {
     @ObservedObject var logger = DebugLogger.shared
     
     var body: some View {
         List {
             if logger.logs.isEmpty {
                 Text("Henüz log kaydı yok.")
                     .foregroundColor(.secondary)
             } else {
                 ForEach(logger.logs.reversed()) { log in
                     VStack(alignment: .leading, spacing: 4) {
                         HStack {
                             Text(log.level.rawValue)
                                 .font(.caption2)
                                 .bold()
                                 .padding(4)
                                 .background(logColor(log.level))
                                 .foregroundColor(.white)
                                 .cornerRadius(4)
                             
                             Text(log.timestamp, style: .time)
                                 .font(.caption2)
                                 .foregroundColor(.secondary)
                             
                             Spacer()
                             
                             Text("\(log.file):\(log.line)")
                                 .font(.caption2)
                                 .foregroundColor(.secondary)
                         }
                         
                         Text(log.message)
                             .font(.caption)
                             .multilineTextAlignment(.leading)
                     }
                     .padding(.vertical, 2)
                 }
             }
         }
         .navigationTitle("Live Console")
         .toolbar {
             ToolbarItem(placement: .navigationBarTrailing) {
                 Button("Temizle") {
                     logger.clear()
                 }
             }
         }
     }
     
     func logColor(_ level: LogLevel) -> Color {
         switch level {
         case .info: return .blue
         case .warning: return .orange
         case .error: return .red
         case .debug: return .gray
         }
     }
 }
