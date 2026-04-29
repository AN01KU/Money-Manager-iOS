import SwiftUI
import SwiftData

#if DEBUG
private let processInfo = ProcessInfo.processInfo
private let useTestData = processInfo.useTestData
private let skipOnboarding = processInfo.skipOnboarding
private let resetOnboarding = processInfo.resetOnboarding
private let isScreenshotMode = processInfo.isScreenshotMode
private let useMockServices = isScreenshotMode ? false : processInfo.useMockServices
private var serviceFactory = ServiceFactory(useMockServices)
#else
private var serviceFactory = ServiceFactory()
#endif

// MARK:  GLOBAL Services
let authService: AuthServiceProtocol = serviceFactory.authService
let syncService: SyncServiceProtocol = serviceFactory.syncService
let changeQueueManager = serviceFactory.changeQueueManager

@main
struct Money_ManagerApp: App {
    let container: ModelContainer
    let storeRecoveryFailed: Bool
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        if skipOnboarding || isScreenshotMode {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(true, forKey: "hasSeenLogin")
        }
        if resetOnboarding {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(false, forKey: "hasSeenLogin")
        }
        #endif

        let schema = Schema([
            Transaction.self,
            RecurringTransaction.self,
            CustomCategory.self,
            MonthlyBudget.self,
            PendingChange.self,
            FailedChange.self,
            OrphanedChange.self,
            SplitGroupModel.self,
            GroupMemberModel.self,
            GroupTransactionModel.self,
            GroupBalanceModel.self
        ])

        let resolvedContainer: ModelContainer
        if let recovered = Self.makeContainer(schema: schema) {
            resolvedContainer = recovered
            storeRecoveryFailed = false
        } else {
            // Both normal init and store recovery failed — use an in-memory store
            // so the app doesn't crash. The alert will be shown in body.
            resolvedContainer = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            storeRecoveryFailed = true
        }
        container = resolvedContainer

        SessionStore.shared.configure(container: container)

        // Only generate recurring transactions locally when not logged in.
        // When authenticated, the backend generates them on GET /transactions.
        if !SessionStore.shared.isLoggedIn {
            RecurringTransactionService.generatePendingTransactions(context: container.mainContext)
        }

        #if DEBUG
        if useTestData {
            Self.injectTestData(context: container.mainContext)
        }
        #endif

        NetworkMonitor.shared.startMonitoring()

        syncService.configure(container: container, authService: authService)
    }

    /// Attempts to create the ModelContainer, recovering by deleting the on-disk store on failure.
    /// Returns nil only if both attempts fail.
    private static func makeContainer(schema: Schema) -> ModelContainer? {
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            AppLogger.sync.error("ModelContainer init failed: \(error) — attempting store recovery")
        }

        // Delete the store file and retry once
        let storeURL = config.url
        let related = [storeURL,
                       storeURL.appendingPathExtension("shm"),
                       storeURL.appendingPathExtension("wal")]
        for url in related {
            try? FileManager.default.removeItem(at: url)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            AppLogger.sync.error("ModelContainer recovery also failed: \(error)")
            return nil
        }
    }
    
    #if DEBUG
    private static func injectTestData(context: ModelContext) {
        try? context.delete(model: Transaction.self)
        try? context.delete(model: MonthlyBudget.self)
        try? context.delete(model: RecurringTransaction.self)

        for transaction in TestData.generatePersonalTransactions() {
            context.insert(transaction)
        }
        for budget in TestData.generateBudgets() {
            context.insert(budget)
        }
        for recurring in TestData.generateRecurringTransactions() {
            context.insert(recurring)
        }

        try? context.save()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.authService, authService)
                .environment(\.syncService, syncService)
                .environment(\.changeQueueManager, changeQueueManager)
                .alert("Storage Error", isPresented: .constant(storeRecoveryFailed)) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The app's local database could not be opened or recovered. Your data may not be available. Please restart the app or contact support if this persists.")
                }
                .onAppear {
                    Task {
                        #if DEBUG
                        if isScreenshotMode,
                           let token = ProcessInfo.processInfo.environment["SCREENSHOT_TOKEN"],
                           !token.isEmpty {
                            // Store in UserDefaults so APIClient can read it without keychain
                            // (keychain writes fail under CODE_SIGNING_ALLOWED=NO in UI tests).
                            UserDefaults.standard.set(token, forKey: "screenshot_token_override")
                            // Each run uses a fresh throwaway user — wipe any leftover local
                            // SwiftData from the previous run so we don't see stale/duplicate data.
                            SyncService.shared.clearAllUserData()
                            await authService.checkAuthState()
                            await syncService.fullSync()
                            return
                        }
                        #endif
                        await authService.checkAuthState()
                        if authService.isAuthenticated {
                            await syncService.syncOnLaunch()
                        }
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onOpenURL { url in
                    guard let route = AppRoute(url: url) else { return }
                    NotificationCenter.default.post(name: .appRouteReceived, object: route)
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
