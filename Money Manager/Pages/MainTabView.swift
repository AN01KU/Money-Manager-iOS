import SwiftUI

enum TabItem: String, CaseIterable {
    case overview
    case groups
    case settings
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .overview
    @State private var tabChanged = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "house.fill", value: .overview) {
                Overview()
            }

            Tab("Groups", systemImage: "person.2.fill", value: .groups) {
                if authService.isAuthenticated {
                    GroupsListView()
                } else {
                    GroupsLockedView()
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView()
            }
        }
        .tint(.teal)
        .sensoryFeedback(.selection, trigger: tabChanged)
        .onChange(of: selectedTab) { _, _ in
            tabChanged = true
        }
        .onChange(of: tabChanged) { _, newValue in
            if newValue { tabChanged = false }
        }
    }
}

// MARK: - Locked State

struct GroupsLockedView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Groups Require Sign In")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Sign in to create groups, split expenses, and settle up with friends.\n\nAny group expenses already on your account will continue to appear in Overview.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Groups")
        }
    }
}

#Preview {
    MainTabView()
}
