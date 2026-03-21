import SwiftUI
import SwiftData

#if DEBUG
private let useTestData = CommandLine.arguments.contains("--useTestData")
private let skipOnboarding = CommandLine.arguments.contains("--skipOnboarding")
private let resetOnboarding = CommandLine.arguments.contains("--resetOnboarding")
#endif

@main
struct Money_ManagerApp: App {
    let container: ModelContainer
    @State private var authService = AuthService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        #if DEBUG
        if skipOnboarding {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
        if resetOnboarding {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
        #endif
        
        let schema = Schema([
            Expense.self,
            RecurringExpense.self,
            CustomCategory.self,
            MonthlyBudget.self,
            PendingChange.self
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
        
        NetworkMonitor.shared.startMonitoring()
        
        SyncEngine.shared.configure(container: container)
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
                .onAppear {
                    Task {
                        await authService.checkAuthState()
                        if authService.isAuthenticated {
                            await SyncEngine.shared.syncOnLaunch()
                        }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
        .modelContainer(container)
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if authService.isAuthenticated {
                Task {
                    await SyncEngine.shared.syncOnReconnect()
                }
            }
        case .background:
            break
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
