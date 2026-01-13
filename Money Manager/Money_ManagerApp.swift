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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Expense.self, RecurringExpense.self, CustomCategory.self, MonthlyBudget.self])
    }
}
