import SwiftUI
import Combine

final class TabManager: ObservableObject {
    @Published var selectedTab: Int = 0
    
    // Tab Indices
    static let dashboard = 0
    static let transactions = 1
    static let analytics = 2
    static let categories = 3
    static let settings = 4
}
