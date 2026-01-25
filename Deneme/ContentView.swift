import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.isProfileComplete {
                    MainTabView()
                } else {
                    ProfileCreationView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.default, value: authManager.isAuthenticated)
        .animation(.default, value: authManager.isProfileComplete)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
}
