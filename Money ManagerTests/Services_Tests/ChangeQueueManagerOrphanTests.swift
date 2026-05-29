import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct ChangeQueueManagerOrphanTests {

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    private func makeManager(container: ModelContainer) -> ChangeQueueManager {
        let mgr = ChangeQueueManager()
        mgr.configure(container: container)
        return mgr
    }

    private func insertPending(
        in context: ModelContext,
        entityType: EntityType = .transaction
    ) {
        let change = ChangeRecord(
            entityType: entityType, entityID: UUID(),
            action: .create, endpoint: "/\(entityType.rawValue)s",
            httpMethod: .post, payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try? context.save()
    }

    // MARK: - orphanAll

    @Test func testOrphanAllMovesPendingToOrphaned() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        insertPending(in: context)
        insertPending(in: context)

        manager.orphanAll(context: context)

        let pending = try context.fetch(makeDescriptor(statusRaw: "pending"))
        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(pending.isEmpty)
        #expect(orphaned.count == 2)
    }

    @Test func testOrphanAllClearsPendingQueue() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        insertPending(in: context)
        insertPending(in: context)
        insertPending(in: context)

        manager.orphanAll(context: context)

        let pending = try context.fetch(makeDescriptor(statusRaw: "pending"))
        #expect(pending.isEmpty)
    }

    @Test func testOrphanAllOnEmptyQueueDoesNothing() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        manager.orphanAll(context: context)

        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(orphaned.isEmpty)
    }

    @Test func testOrphanAllPreservesEntityMetadata() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        let id = UUID()
        manager.enqueue(
            PendingChangeDraft(entityType: .budget, entityID: id,
                               action: .update, endpoint: "/budgets",
                               httpMethod: .put, payload: "{}".data(using: .utf8)),
            context: context
        )

        manager.orphanAll(context: context)

        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(orphaned.count == 1)
        #expect(orphaned.first?.entityType == EntityType.budget.rawValue)
        #expect(orphaned.first?.entityID == id)
        #expect(orphaned.first?.action == ChangeAction.update.rawValue)
        #expect(orphaned.first?.httpMethod == HTTPMethod.put.rawValue)
    }

    // MARK: - purgeExpiredOrphans

    @Test func testPurgeExpiredOrphansRemovesOldEntries() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        let oldOrphan = ChangeRecord(
            entityType: .transaction, entityID: UUID(),
            action: .create, endpoint: "/transactions",
            httpMethod: .post, payload: nil,
            status: .orphaned,
            orphanedAt: Date(timeIntervalSinceNow: -8 * 86400)
        )
        context.insert(oldOrphan)
        try context.save()

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let remaining = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(remaining.isEmpty)
    }

    @Test func testPurgeExpiredOrphansKeepsRecentEntries() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        let recentOrphan = ChangeRecord(
            entityType: .transaction, entityID: UUID(),
            action: .create, endpoint: "/transactions",
            httpMethod: .post, payload: nil,
            status: .orphaned,
            orphanedAt: Date()
        )
        context.insert(recentOrphan)
        try context.save()

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let remaining = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(remaining.count == 1)
    }

    // MARK: - Notification

    @Test func testSyncSessionInvalidOrphansQueueAndPostsNotification() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.syncSessionInvalid(reason: "EXPIRED") }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        for _ in 0..<2 {
            let change = ChangeRecord(
                entityType: .transaction, entityID: UUID(),
                action: .create, endpoint: "/transactions",
                httpMethod: .post, payload: "{}".data(using: .utf8)
            )
            context.insert(change)
        }
        try context.save()

        var notificationFired = false
        let observer = NotificationCenter.default.addObserver(
            forName: .syncSessionOrphaned, object: nil, queue: nil
        ) { _ in notificationFired = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(makeDescriptor(statusRaw: "pending"))
        let orphans = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(pending.isEmpty)
        #expect(orphans.count == 2)
        #expect(notificationFired)
    }
}
