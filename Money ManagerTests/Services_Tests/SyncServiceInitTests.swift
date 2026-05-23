import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Verifies that SyncService accepts constructor-injected dependencies
/// and wires them at init time.
@MainActor
struct SyncServiceInitTests {

    @Test("SyncService.shared is accessible in DEBUG builds")
    func sharedIsAccessible() {
        let svc = SyncService.shared
        #expect(svc.isSyncing == false)
    }

    @Test("SyncService injects changeQueue and calls configure during init")
    func injectedQueueReceivesConfigureDuringInit() throws {
        let queue = SpyChangeQueueManager()
        let container = try makeTestContainer()
        let _ = SyncService(
            api: MockAPIClient(),
            changeQueue: queue,
            networkMonitor: MockNetworkMonitor(isConnected: false),
            authService: MockAuthService.shared,
            container: container
        )
        #expect(queue.configureCallCount == 1)
    }

    @Test("SyncService constructed with injected dependencies starts not syncing")
    func constructedServiceStartsIdle() throws {
        let container = try makeTestContainer()
        let svc = SyncService(
            api: MockAPIClient(),
            changeQueue: SpyChangeQueueManager(),
            networkMonitor: MockNetworkMonitor(isConnected: false),
            authService: MockAuthService.shared,
            container: container
        )
        #expect(svc.isSyncing == false)
    }
}

// MARK: - Spy

private final class SpyChangeQueueManager: ChangeQueueManagerProtocol {
    var pendingCount: Int { 0 }
    var failedCount: Int { 0 }
    var configureCallCount = 0

    func configure(container: ModelContainer) { configureCallCount += 1 }
    func enqueue(entityType: EntityType, entityID: UUID, action: ChangeAction, endpoint: String, httpMethod: HTTPMethod, payload: Data?, context: ModelContext) {}
    func replayAll(context: ModelContext, isAuthenticated: Bool) async {}
    func clearAll(context: ModelContext) {}
    func orphanAll(context: ModelContext) {}
    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext) {}
    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: EntityType, context: ModelContext) {}
}
