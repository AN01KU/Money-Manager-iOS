import SwiftUI
import SwiftData

#if DEBUG
private let useTestData = CommandLine.arguments.contains("useTestData")
#endif

@main
struct Money_ManagerApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Expense.self,
            RecurringExpense.self,
            CustomCategory.self,
            MonthlyBudget.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            CategorySeeder.seedIfNeeded(context: container.mainContext)
            RecurringExpenseService.generatePendingExpenses(context: container.mainContext)
            
            #if DEBUG
            if useTestData {
                Self.injectTestData(context: container.mainContext)
            }
            #endif
            
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    #if DEBUG
    private static func injectTestData(context: ModelContext) {
        try? context.delete(model: Expense.self)
        try? context.delete(model: MonthlyBudget.self)
        
        for expense in TestData.generatePersonalExpenses() {
            context.insert(expense)
        }
        for budget in TestData.generateBudgets() {
            context.insert(budget)
        }
        
        try? context.save()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
