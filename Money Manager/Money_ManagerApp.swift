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
            PendingSyncItem.self
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
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    modelContext = context
                    SyncService.shared.configure(with: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
