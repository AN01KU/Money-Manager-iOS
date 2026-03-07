import SwiftUI
import SwiftData

@main
struct Money_ManagerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            CustomCategory.self,
            MonthlyBudget.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
