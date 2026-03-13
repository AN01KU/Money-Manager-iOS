import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Overview", systemImage: "house.fill", value: 0) {
                Overview()
            }
            
            Tab("Settings", systemImage: "gearshape.fill", value: 1) {
                SettingsView()
            }
        }
        .tint(.teal)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.selection()
        }
    }
}

#Preview {
    MainTabView()
}
