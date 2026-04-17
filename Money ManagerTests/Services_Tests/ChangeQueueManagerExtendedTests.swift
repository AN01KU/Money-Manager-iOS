import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for ChangeQueueManager paths not covered by ChangeQueueManagerTests:
/// orphanAll, purgeExpiredOrphans, failedCount, pendingCount with no container,
/// enqueue update→update merges payload, and replayAll moving expired items to dead-letter.
@MainActor
struct ChangeQueueManagerExtendedTests {

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    private func makeManager(container: ModelContainer) -> ChangeQueueManager {
        let mgr = ChangeQueueManager()
        mgr.configure(container: container)
        return mgr
    }

    private func enqueue(
        _ manager: ChangeQueueManager,
        in context: ModelContext,
        entityType: String = "transaction",
        action: String = "create"
    ) -> UUID {
        let id = UUID()
        manager.enqueue(
            entityType: entityType,
            entityID: id,
            action: action,
            endpoint: "/transactions",
            httpMethod: action == "delete" ? "DELETE" : "POST",
            payload: action == "delete" ? nil : "{}".data(using: .utf8),
            context: context
        )
        return id
    }

    // MARK: - pendingCount / failedCount without container

    @Test func testPendingCountReturnsZeroWithoutContainer() {
        let manager = ChangeQueueManager()
        #expect(manager.pendingCount == 0)
    }

    @Test func testFailedCountReturnsZeroWithoutContainer() {
        let manager = ChangeQueueManager()
        #expect(manager.failedCount == 0)
    }

    @Test func testFailedCountReflectsDeadLetterAfterMaxRetries() async throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)

        // Insert a PendingChange already at max retry count
        let id = UUID()
        manager.enqueue(
            entityType: "transaction",
            entityID: id,
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: "{}".data(using: .utf8),
            context: context
        )

        // Manually set retryCount to max so replayAll moves it to dead-letter
        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        pending.first?.retryCount = ChangeQueueManager.maxRetryCount
        try context.save()

        // replayAll — the item has exceeded max retries → should move to FailedChange
        await manager.replayAll(context: context, isAuthenticated: true)

        #expect(manager.failedCount == 1)
        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.isEmpty)
    }

    // MARK: - orphanAll

    @Test func testOrphanAllMovesPendingToOrphaned() throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)

        _ = enqueue(manager, in: context)
        _ = enqueue(manager, in: context)

        // Verify items are actually in the context before orphaning
        let beforeOrphan = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(beforeOrphan.count == 2)

        manager.orphanAll(context: context)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(pending.isEmpty)
        #expect(orphaned.count == 2)
    }

    @Test func testOrphanAllOnEmptyQueueDoesNothing() throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)

        // No enqueued changes — orphanAll should be a no-op
        manager.orphanAll(context: context)

        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(orphaned.isEmpty)
    }

    @Test func testOrphanAllPreservesEntityMetadata() throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)

        let id = UUID()
        manager.enqueue(
            entityType: "budget",
            entityID: id,
            action: "update",
            endpoint: "/budgets",
            httpMethod: "PUT",
            payload: "{}".data(using: .utf8),
            context: context
        )

        manager.orphanAll(context: context)

        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(orphaned.count == 1)
        #expect(orphaned.first?.entityType == "budget")
        #expect(orphaned.first?.entityID == id)
        #expect(orphaned.first?.action == "update")
        #expect(orphaned.first?.httpMethod == "PUT")
    }

    // MARK: - purgeExpiredOrphans

    @Test func testPurgeExpiredOrphansRemovesOldEntries() throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)

        // Insert an orphan with an old orphanedAt date
        let oldOrphan = OrphanedChange(
            entityType: "transaction",
            entityID: UUID(),
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: nil,
            createdAt: Date(timeIntervalSinceNow: -30 * 86400)
        )
        // Manually backdate orphanedAt
        oldOrphan.orphanedAt = Date(timeIntervalSinceNow: -8 * 86400)
        context.insert(oldOrphan)
        try context.save()

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let remaining = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(remaining.isEmpty)
    }

    @Test func testPurgeExpiredOrphansKeepsRecentEntries() throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)

        // Recent orphan — should survive
        let recentOrphan = OrphanedChange(
            entityType: "transaction",
            entityID: UUID(),
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: nil,
            createdAt: Date()
        )
        context.insert(recentOrphan)
        try context.save()

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let remaining = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(remaining.count == 1)
    }

    // MARK: - enqueue: update → update merges payload

    @Test func testEnqueueUpdateThenUpdateMergesPayload() throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)
        let id = UUID()

        manager.enqueue(
            entityType: "budget",
            entityID: id,
            action: "update",
            endpoint: "/budgets",
            httpMethod: "PUT",
            payload: #"{"limit":"1000"}"#.data(using: .utf8),
            context: context
        )
        manager.enqueue(
            entityType: "budget",
            entityID: id,
            action: "update",
            endpoint: "/budgets",
            httpMethod: "PUT",
            payload: #"{"limit":"2000"}"#.data(using: .utf8),
            context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 1)
        #expect(all.first?.action == "update")
        let payloadString = all.first?.payload.flatMap { String(data: $0, encoding: .utf8) }
        #expect(payloadString == #"{"limit":"2000"}"#)
        #expect(all.first?.retryCount == 0)
    }

    // MARK: - replayAll: backoff window skips items not yet due

    @Test func testReplayAllSkipsItemsInBackoffWindow() async throws {
        let container = try makeContainer()
        let manager = makeManager(container: container)
        let context = ModelContext(container)

        _ = enqueue(manager, in: context)

        // Put the item into a future backoff window so replayAll skips it
        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        pending.first?.nextRetryAt = Date(timeIntervalSinceNow: 60)
        pending.first?.retryCount = 1
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        // Item should still be pending (not moved to dead-letter, not deleted)
        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.count == 1)
        #expect(manager.failedCount == 0)
    }
}
