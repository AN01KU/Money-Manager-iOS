import SwiftUI

enum TabItem: String, CaseIterable {
    case overview
    case transactions
    case groups
    case settings
}

struct MainTabView: View {
    @Environment(\.authService) private var authService
    @State private var selectedTab: TabItem = .overview
    @State private var tabChanged = 0
    @State private var pendingRoute: AppRoute?
    @State private var pendingCategoryFilter: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "house.fill", value: .overview) {
                Overview(pendingRoute: $pendingRoute, onCategoryTapped: { category in
                    pendingCategoryFilter = category
                    selectedTab = .transactions
                })
            }

            Tab("Transactions", systemImage: "list.bullet", value: .transactions) {
                TransactionsView(categoryFilter: $pendingCategoryFilter, onGroupTapped: { groupID in
                    guard authService.isAuthenticated else { return }
                    selectedTab = .groups
                    pendingRoute = .group(groupID)
                })
            }

            if authService.isAuthenticated {
                Tab("Groups", systemImage: "person.2.fill", value: .groups) {
                    GroupsListView(pendingRoute: $pendingRoute)
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView()
            }
        }
        .tint(.teal)
        .sensoryFeedback(.selection, trigger: tabChanged)
        .onChange(of: selectedTab) { _, _ in
            tabChanged += 1
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated && selectedTab == .groups {
                selectedTab = .overview
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appRouteReceived)) { notification in
            guard let route = notification.object as? AppRoute else { return }
            switch route {
            case .transaction:
                selectedTab = .transactions
            case .group:
                guard authService.isAuthenticated else { return }
                selectedTab = .groups
            }
            pendingRoute = route
        }
    }
}

#Preview {
    MainTabView()
}
