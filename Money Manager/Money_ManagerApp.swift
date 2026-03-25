import SwiftUI
import SwiftData

#if DEBUG
private let processInfo = ProcessInfo.processInfo
private let useTestData = processInfo.useTestData
private let skipOnboarding = processInfo.skipOnboarding
private let resetOnboarding = processInfo.resetOnboarding
private let useMockServices = processInfo.useMockServices
#endif

// MARK:  GLOBAL Services
private var serviceFactory = ServiceFactory(useMockServices)
let authService: AuthServiceProtocol = serviceFactory.authService
let syncService: SyncServiceProtocol = serviceFactory.syncService
let changeQueueManager = serviceFactory.changeQueueManager

@main
struct Money_ManagerApp: App {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        #if DEBUG
        if skipOnboarding {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(true, forKey: "hasSeenLogin")
        }
        if resetOnboarding {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(false, forKey: "hasSeenLogin")
        }
        #endif
        
        let schema = Schema([
            Expense.self,
            RecurringExpense.self,
            CustomCategory.self,
            MonthlyBudget.self,
            PendingChange.self,
            AuthToken.self,
            SplitGroupModel.self,
            GroupMemberModel.self,
            GroupExpenseModel.self,
            GroupBalanceModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            SessionStore.shared.configure(container: container)

            RecurringExpenseService.generatePendingExpenses(context: container.mainContext)
            CategorySeeder.seedIfNeeded(context: container.mainContext)
            
            #if DEBUG
            if useTestData {
                Self.injectTestData(context: container.mainContext)
            }
            #endif
            
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        NetworkMonitor.shared.startMonitoring()
        
        syncService.configure(container: container)
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
                            await syncService.syncOnLaunch()
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
            if authService.hasCheckedAuth && authService.isAuthenticated {
                Task {
                    await syncService.syncOnReconnect()
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
