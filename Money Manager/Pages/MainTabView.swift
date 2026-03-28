import SwiftUI

enum TabItem: String, CaseIterable {
    case overview
    case groups
    case settings
}

struct MainTabView: View {
    @State private var selectedTab: TabItem = .overview
    @State private var tabChanged = false
    @State private var pendingRoute: AppRoute?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "house.fill", value: .overview) {
                Overview(pendingRoute: $pendingRoute)
            }

            Tab("Groups", systemImage: "person.2.fill", value: .groups) {
                if authService.isAuthenticated {
                    GroupsListView(pendingRoute: $pendingRoute)
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
        .onReceive(NotificationCenter.default.publisher(for: .appRouteReceived)) { notification in
            guard let route = notification.object as? AppRoute else { return }
            switch route {
            case .transaction:
                selectedTab = .overview
            case .group:
                selectedTab = .groups
            }
            pendingRoute = route
        }
    }
}

#Preview {
    MainTabView()
}
