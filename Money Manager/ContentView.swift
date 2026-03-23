import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !authService.hasCheckedAuth {
                SplashView()
            } else if !authService.isAuthenticated {
                LoginView()
            } else if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.teal)
        }
    }
}

#Preview {
    ContentView()
}
