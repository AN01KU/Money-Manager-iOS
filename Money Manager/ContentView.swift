import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenLogin") private var hasSeenLogin = false

    var body: some View {
        Group {
            if !authService.hasCheckedAuth {
                SplashView()
            } else if !hasSeenLogin && !authService.isAuthenticated {
                // Show login only on the very first launch, skippable
                LoginView(onSkip: { hasSeenLogin = true })
                    .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                        if isAuthenticated { hasSeenLogin = true }
                    }
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
