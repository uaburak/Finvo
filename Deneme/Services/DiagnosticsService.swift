import Foundation
import Firebase
import FirebaseFirestore

struct DiagnosticResult: Identifiable {
    let id = UUID()
    let name: String
    let status: DiagnosticStatus
    let details: String
    let timestamp = Date()
}

enum DiagnosticStatus {
    case passing
    case warning
    case failing
    case running
}

class DiagnosticsService {
    static let shared = DiagnosticsService()
    private let db = Firestore.firestore()
    
    // MARK: - Performance Tests
    
    /// Returns read/write latency in milliseconds
    func measureFirestoreLatency() async -> (writeMs: Double, readMs: Double) {
        let docRef = db.collection("diagnostics").document("latency_test")
        let data = ["timestamp": FieldValue.serverTimestamp(), "temp": UUID().uuidString] as [String : Any]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try await docRef.setData(data)
            let writeDuration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            let readStart = CFAbsoluteTimeGetCurrent()
            _ = try await docRef.getDocument()
            let readDuration = (CFAbsoluteTimeGetCurrent() - readStart) * 1000
            
            // Clean up
            try await docRef.delete()
            
            return (writeDuration, readDuration)
        } catch {
            DebugLogger.shared.log("Latency test failed: \(error.localizedDescription)", level: .error)
            return (-1, -1)
        }
    }
    
    // MARK: - Integrity Checks
    
    /// Checks for transactions referencing non-existent wallets or bad data
    func checkDataIntegrity(walletId: String) async -> [DiagnosticResult] {
        var results: [DiagnosticResult] = []
        
        // 1. Transaction Integrity
        do {
            let snapshot = try await db.collection("wallets").document(walletId).collection("transactions").getDocuments()
            var invalidCatCount = 0
            var futureDateCount = 0
            
            for doc in snapshot.documents {
                let data = doc.data()
                
                // Check Category
                if let cat = data["categoryName"] as? String, cat.isEmpty {
                    invalidCatCount += 1
                }
                
                // Check Date
                if let timestamp = data["date"] as? Timestamp {
                    if timestamp.dateValue() > Date().addingTimeInterval(86400 * 365) { // More than 1 year in future
                        futureDateCount += 1
                    }
                }
            }
            
            if invalidCatCount > 0 {
                results.append(DiagnosticResult(name: "İşlem Kategorileri", status: .warning, details: "\(invalidCatCount) işlemde kategori eksik."))
            } else {
                results.append(DiagnosticResult(name: "İşlem Kategorileri", status: .passing, details: "Tüm işlemler kategorili."))
            }
            
            if futureDateCount > 0 {
                 results.append(DiagnosticResult(name: "İşlem Tarihleri", status: .warning, details: "\(futureDateCount) işlem ileri bir tarihte (1 yıldan fazla)."))
            } else {
                 results.append(DiagnosticResult(name: "İşlem Tarihleri", status: .passing, details: "Tarihler makul görünüyor."))
            }
            
        } catch {
             results.append(DiagnosticResult(name: "Veri Okuma", status: .failing, details: "Cüzdan verisi okunamadı: \(error.localizedDescription)"))
        }
        
        return results
    }
    
    /// Checks for orphan data (Invites for non-existent wallets, etc.)
    func checkOrphanData() async -> [DiagnosticResult] {
        var results: [DiagnosticResult] = []
        
        // Check Invites
        do {
            let invitesSnap = try await db.collection("invites").getDocuments()
            var deadInvites = 0
            
            for doc in invitesSnap.documents {
                if let walletId = doc.data()["walletId"] as? String {
                    let walletDoc = try await db.collection("wallets").document(walletId).getDocument()
                    if !walletDoc.exists {
                         deadInvites += 1
                    }
                }
            }
            
            if deadInvites > 0 {
                results.append(DiagnosticResult(name: "Ölü Davetler", status: .warning, details: "\(deadInvites) davet silinmiş cüzdanlara işaret ediyor."))
            } else {
                results.append(DiagnosticResult(name: "Davet Tutarlılığı", status: .passing, details: "Tüm davetler geçerli cüzdanlara bağlı."))
            }
            
        } catch {
            results.append(DiagnosticResult(name: "Orphan Check Help", status: .failing, details: "Kontrol başarısız: \(error.localizedDescription)"))
        }
        
        return results
    }
}
