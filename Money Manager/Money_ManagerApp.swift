import SwiftUI
import SwiftData

@main
struct Money_ManagerApp: App {
    let container: ModelContainer
    let storeRecoveryFailed: Bool
    let services: AppServices
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        let skipOnboarding = processInfo.skipOnboarding
        let resetOnboarding = processInfo.resetOnboarding
        let isScreenshotMode = processInfo.isScreenshotMode
        let useTestData = processInfo.useTestData

        if skipOnboarding || isScreenshotMode {
            UserDefaults.standard.set(true, forKey: UserDefaults.Keys.hasCompletedOnboarding.rawValue)
            UserDefaults.standard.set(true, forKey: UserDefaults.Keys.hasSeenLogin.rawValue)
        }
        if resetOnboarding {
            UserDefaults.standard.set(false, forKey: UserDefaults.Keys.hasCompletedOnboarding.rawValue)
            UserDefaults.standard.set(false, forKey: UserDefaults.Keys.hasSeenLogin.rawValue)
        }
        #endif

        let schema = Schema(SchemaV3.models)

        let resolvedContainer: ModelContainer
        if let recovered = Self.makeContainer(schema: schema, migrationPlan: AppMigrationPlan.self) {
            resolvedContainer = recovered
            storeRecoveryFailed = false
        } else {
            // Both normal init and store recovery failed — use an in-memory store
            // so the app doesn't crash. The alert will be shown in body.
            resolvedContainer = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            storeRecoveryFailed = true
        }
        container = resolvedContainer

        #if DEBUG
        let isUITestMode = CommandLine.arguments.contains("-uiTestMode")
        if isUITestMode {
            services = AppServices.uiTestMocks()
        } else {
            services = AppServices.live(container: resolvedContainer)
        }
        #else
        services = AppServices.live(container: resolvedContainer)
        #endif

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
    }

    /// Attempts to create the ModelContainer, recovering by deleting the on-disk store on failure.
    /// Returns nil only if both attempts fail.
    private static func makeContainer(
        schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil
    ) -> ModelContainer? {
        let config = ModelConfiguration(schema: schema)
        do {
            if let plan = migrationPlan {
                return try ModelContainer(for: schema, migrationPlan: plan, configurations: [config])
            } else {
                return try ModelContainer(for: schema, configurations: [config])
            }
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
            if let plan = migrationPlan {
                return try ModelContainer(for: schema, migrationPlan: plan, configurations: [config])
            } else {
                return try ModelContainer(for: schema, configurations: [config])
            }
        } catch {
            AppLogger.sync.error("ModelContainer recovery also failed: \(error)")
            return nil
        }
    }

    #if DEBUG
    private static func injectTestData(context: ModelContext) {
        try? context.delete(model: Transaction.self)
        try? context.delete(model: RecurringTransaction.self)
        try? context.delete(model: Category.self)

        for transaction in TestData.generatePersonalTransactions() {
            context.insert(transaction)
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
                .environment(\.authService, services.authService)
                .environment(\.syncService, services.syncService)
                .environment(\.changeQueueManager, services.changeQueueManager)
                .environment(\.persistence, services.persistence)
                .environment(\.budgetRepository, services.budgetRepository)
                .environment(\.networkMonitor, services.networkMonitor)
                .environment(\.groupService, services.groupService)
                .alert("Storage Error", isPresented: .constant(storeRecoveryFailed)) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The app's local database could not be opened or recovered. Your data may not be available. Please restart the app or contact support if this persists.")
                }
                .onAppear {
                    Task {
                        #if DEBUG
                        if ProcessInfo.processInfo.isScreenshotMode,
                           let token = ProcessInfo.processInfo.environment["SCREENSHOT_TOKEN"],
                           !token.isEmpty {
                            // Store in UserDefaults so APIClient can read it without keychain
                            // (keychain writes fail under CODE_SIGNING_ALLOWED=NO in UI tests).
                            UserDefaults.standard.set(token, forKey: UserDefaults.Keys.screenshotTokenOverride.rawValue)
                            // Each run uses a fresh throwaway user — wipe any leftover local
                            // SwiftData from the previous run so we don't see stale/duplicate data.
                            services.syncService.clearAllUserData()
                            await services.authService.checkAuthState()
                            await services.syncService.fullSync()
                            return
                        }
                        #endif
                        await services.syncService.bootstrapPredefinedCategories()
                        await services.authService.checkAuthState()
                        if services.authService.isAuthenticated {
                            await services.syncService.syncOnLaunch()
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
            if services.authService.hasCheckedAuth && services.authService.isAuthenticated {
                Task {
                    await services.syncService.syncOnReconnect()
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
