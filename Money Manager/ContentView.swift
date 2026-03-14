import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        #if DEBUG
        if CommandLine.arguments.contains("skipOnboarding") {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        #endif
    }
    
    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
 
