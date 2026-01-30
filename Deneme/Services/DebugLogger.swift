import Foundation
import Combine

enum LogLevel: String {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
    case debug = "DEBUG"
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let level: LogLevel
    let message: String
    let file: String
    let line: Int
}

class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    @Published var logs: [LogEntry] = []
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let entry = LogEntry(level: level, message: message, file: fileName, line: line)
        
        DispatchQueue.main.async {
            self.logs.append(entry)
            // Keep last 1000 logs to avoid memory issues
            if self.logs.count > 1000 {
                self.logs.removeFirst()
            }
        }
        
        // Also print to standard console
        print("[\(level.rawValue)] \(fileName):\(line) - \(message)")
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}
