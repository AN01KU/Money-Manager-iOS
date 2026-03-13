import SwiftUI

enum TabItem: String, CaseIterable {
    case overview
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

#Preview {
    MainTabView()
}
