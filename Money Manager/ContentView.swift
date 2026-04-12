import SwiftUI

struct ContentView: View {
    @Environment(\.authService) private var authService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSessionExpiredAlert = false
    @State private var showLoginSheet = false
    @State private var showOrphanedRecordsAlert = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .alert("Session Expired", isPresented: $showSessionExpiredAlert) {
            Button("Log In Again") { showLoginSheet = true }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("Your session has expired. Please log in again to continue syncing.")
        }
        .alert("Records Not Synced", isPresented: $showOrphanedRecordsAlert) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("Some records from a previous session couldn't be synced and have been set aside. They will be removed after 7 days.")
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView(isDismissable: true)
        }
        .onChange(of: authService.authState) { _, newState in
            if case .expired = newState {
                showSessionExpiredAlert = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncSessionOrphaned)) { _ in
            showOrphanedRecordsAlert = true
        }
    }
}

#Preview {
    ContentView()
}
