import SwiftUI

struct MainTabView: View {
    @ObservedObject private var apiService = APIService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Overview()
                .tabItem {
                    Label("Overview", systemImage: "house.fill")
                }
                .tag(0)
            
            if apiService.isAuthenticated || useTestData {
                GroupsListView()
                    .tabItem {
                        Label("Groups", systemImage: "person.3.fill")
                    }
                    .tag(1)
            }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(.teal)
    }
}

#Preview {
    MainTabView()
}
