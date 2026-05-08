import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Verifies that SyncService accepts an injected ChangeQueueManagerProtocol,
/// breaking the global-variable initialization cycle that caused launch crashes.
@MainActor
struct SyncServiceInitTests {

    @Test("SyncService.shared uses ChangeQueueManager.shared by default")
    func sharedUsesDefaultChangeQueue() {
        // SyncService.shared must be accessible without crashing — the crash
        // happened because the stored property initializer referenced the global
        // `changeQueueManager` while `syncService` was still initializing.
        let svc = SyncService.shared
        #expect(svc.isSyncing == false)
    }

    @Test("SyncService can be constructed with a mock ChangeQueueManager")
    func constructWithMockChangeQueue() {
        let mock = SpyChangeQueueManager()
        let svc = SyncService(changeQueue: mock)
        #expect(svc.isSyncing == false)
    }

    @Test("SyncService injected queue is used during configure")
    func injectedQueueReceivesConfigure() throws {
        let mock = SpyChangeQueueManager()
        let svc = SyncService(changeQueue: mock)
        let container = try makeTestContainer()
        svc.configure(container: container, authService: MockAuthService.shared)
        #expect(mock.configureCallCount == 1)
    }
}

// MARK: - Spy

private final class SpyChangeQueueManager: ChangeQueueManagerProtocol {
    var pendingCount: Int { 0 }
    var failedCount: Int { 0 }
    var configureCallCount = 0

    func configure(container: ModelContainer) { configureCallCount += 1 }
    func enqueue(entityType: String, entityID: UUID, action: String, endpoint: String, httpMethod: String, payload: Data?, context: ModelContext) {}
    func replayAll(context: ModelContext, isAuthenticated: Bool) async {}
    func clearAll(context: ModelContext) {}
    func orphanAll(context: ModelContext) {}
    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext) {}
    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: String, context: ModelContext) {}
}
