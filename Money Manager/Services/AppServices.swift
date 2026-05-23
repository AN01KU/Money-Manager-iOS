//
//  AppServices.swift
//  Money Manager
//

import Foundation
import SwiftData

/// A plain struct holding all constructed service instances.
/// Replaces `ServiceFactory`; that file still exists for now and will be removed in #123.
struct AppServices {
    let authService: AuthServiceProtocol
    let syncService: SyncServiceProtocol
    let changeQueueManager: ChangeQueueManagerProtocol
    let persistence: PersistenceService
    let groupService: GroupServiceProtocol
    let networkMonitor: any NetworkMonitorProtocol
}

// MARK: - Factories

extension AppServices {
    /// Constructs fully-wired live services for production use.
    @MainActor
    static func live(container: ModelContainer) -> AppServices {
        let networkMonitor = NetworkMonitor.shared
        networkMonitor.startMonitoring()

        let changeQueue = ChangeQueueManager(apiClient: AppAPIClient.shared)
        let authService = AuthService.shared
        let groupService = GroupService.shared
        let syncService = SyncService(
            api: AppAPIClient.shared,
            changeQueue: changeQueue,
            networkMonitor: networkMonitor,
            authService: authService,
            container: container,
            groupService: groupService
        )
        let persistence = PersistenceService(
            modelContext: container.mainContext,
            authService: authService,
            networkMonitor: networkMonitor,
            changeQueue: changeQueue
        )
        return AppServices(
            authService: authService,
            syncService: syncService,
            changeQueueManager: changeQueue,
            persistence: persistence,
            groupService: groupService,
            networkMonitor: networkMonitor
        )
    }

    #if DEBUG
    /// Constructs mock services for UI tests, driven by a scenario flag passed via
    /// `CommandLine.arguments` (e.g. `-uiTestMode`).
    @MainActor
    static func uiTestMocks(scenario: String? = nil) -> AppServices {
        let container = try! makeInMemoryContainer()
        let networkMonitor = MockNetworkMonitor()
        let changeQueue = MockChangeQueueManager.shared
        let persistence = PersistenceService(
            modelContext: container.mainContext,
            authService: MockAuthService.shared,
            networkMonitor: networkMonitor,
            changeQueue: changeQueue
        )
        return AppServices(
            authService: MockAuthService.shared,
            syncService: MockSyncService.shared,
            changeQueueManager: changeQueue,
            persistence: persistence,
            groupService: MockGroupService.shared,
            networkMonitor: networkMonitor
        )
    }

    /// Constructs lightweight mock services for SwiftUI previews.
    @MainActor
    static var preview: AppServices {
        let networkMonitor = MockNetworkMonitor()
        let changeQueue = MockChangeQueueManager.shared
        let persistence = PersistenceService.testing
        return AppServices(
            authService: MockAuthService.shared,
            syncService: MockSyncService.shared,
            changeQueueManager: changeQueue,
            persistence: persistence,
            groupService: MockGroupService.shared,
            networkMonitor: networkMonitor
        )
    }

    private static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Transaction.self, RecurringTransaction.self, MonthlyBudget.self, UserBudget.self, Category.self,
            PendingChange.self, FailedChange.self, OrphanedChange.self,
            SplitGroupModel.self, GroupMemberModel.self, GroupTransactionModel.self, GroupBalanceModel.self
        ])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
    #endif
}
