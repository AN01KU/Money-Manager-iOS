import SwiftUI
import SwiftData

@main
struct Money_ManagerApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Expense.self,
            CustomCategory.self,
            MonthlyBudget.self
        ])
        
        let isUITesting = CommandLine.arguments.contains("--uitesting")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
        )

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            if isUITesting {
                Self.injectTestData(context: container.mainContext)
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private static func injectTestData(context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        
        let testExpenses = [
            Expense(amount: 450, category: "Food & Dining", date: today, expenseDescription: "Lunch at cafe"),
            Expense(amount: 120, category: "Food & Dining", date: today, expenseDescription: "Morning coffee"),
            Expense(amount: 2000, category: "Transport", date: calendar.date(byAdding: .day, value: -1, to: today)!, expenseDescription: "Fuel"),
            Expense(amount: 1200, category: "Shopping", date: calendar.date(byAdding: .day, value: -2, to: today)!, expenseDescription: "New shirt"),
            Expense(amount: 999, category: "Utilities", date: calendar.date(byAdding: .day, value: -5, to: today)!, expenseDescription: "Phone bill"),
            Expense(amount: 649, category: "Entertainment", date: calendar.date(byAdding: .day, value: -3, to: today)!, expenseDescription: "Netflix"),
        ]
        
        for expense in testExpenses {
            context.insert(expense)
        }
        
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let budget = MonthlyBudget(year: year, month: month, limit: 50000)
        context.insert(budget)
        
        try? context.save()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
