import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("isOnboardingSeen") var isOnboardingSeen: Bool = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.isProfileComplete {
                    MainTabView()
                } else {
                    ProfileCreationView()
                }
            } else {
                if isOnboardingSeen {
                    LoginView()
                } else {
                    OnboardingView()
                }
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
