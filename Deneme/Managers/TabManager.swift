import SwiftUI
import Combine

final class TabManager: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingTransactionFilter: TransactionType?
    
    // Tab Indices
    static let dashboard = 0
    static let analytics = 1
    static let categories = 2
    static let settings = 3
}
