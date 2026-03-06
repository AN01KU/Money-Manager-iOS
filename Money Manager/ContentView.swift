import SwiftUI

let useTestData: Bool = CommandLine.arguments.contains("useTestData")

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}
