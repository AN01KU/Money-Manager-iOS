//
//  Money_ManagerApp.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 25/12/25.
//

import SwiftUI
import SwiftData

@main
struct Money_ManagerApp: App {
    @State private var modelContext: ModelContext?
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Expense.self,
            RecurringExpense.self,
            CustomCategory.self,
            MonthlyBudget.self,
            PendingSyncItem.self,
            CachedUser.self,
            AuthToken.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            KeychainService.shared.setModelContainer(container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    modelContext = context
                    SyncService.shared.configure(with: context)
                    APIService.shared.configure(modelContext: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
