import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for ChangeQueueManager.replayAll — specifically the paths that previously
/// required live HTTP. Uses MockAPIClient for full isolation.
@MainActor
struct ChangeQueueManagerReplayTests {

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    private func successMock() -> MockAPIClient {
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in EmptyResponse() }
        mock.rawPutHandler = { _, _ in EmptyResponse() }
        mock.rawPatchHandler = { _, _ in EmptyResponse() }
        mock.deleteMessageHandler = { _ in APIMessageResponse(message: "ok") }
        return mock
    }

    // MARK: - POST create succeeds → change removed

    @Test func testReplayAllPostSucceededRemovesPendingChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = successMock()
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let payload = "{}".data(using: .utf8)
        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: payload
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.isEmpty)
        #expect(mock.postCalls.count == 1)
    }

    // MARK: - PUT update succeeds → change removed

    @Test func testReplayAllPutSucceededRemovesPendingChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = successMock()
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let payload = "{}".data(using: .utf8)
        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "update", endpoint: "/transactions",
            httpMethod: "PUT", payload: payload
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.isEmpty)
        #expect(mock.putCalls.count == 1)
    }

    // MARK: - PATCH update succeeds → change removed

    @Test func testReplayAllPatchSucceededRemovesPendingChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = successMock()
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let payload = "{}".data(using: .utf8)
        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "update", endpoint: "/transactions",
            httpMethod: "PATCH", payload: payload
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.isEmpty)
        #expect(mock.patchCalls.count == 1)
    }

    // MARK: - DELETE succeeds → hard-deletes local transaction

    @Test func testReplayAllDeleteSucceededHardDeletesLocalTransaction() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = successMock()
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let txId = UUID()
        let tx = Transaction(id: txId, amount: 10, category: "Food", date: Date())
        context.insert(tx)

        let change = PendingChange(
            entityType: "transaction", entityID: txId,
            action: "delete", endpoint: "/transactions",
            httpMethod: "DELETE", payload: nil
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        #expect(remaining.isEmpty)
        #expect(txns.isEmpty)
        #expect(mock.deleteMessageCalls.count == 1)
    }

    // MARK: - DELETE succeeds → hard-deletes local recurring transaction

    @Test func testReplayAllDeleteSucceededHardDeletesLocalRecurring() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = successMock()
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let recId = UUID()
        let rec = RecurringTransaction(
            id: recId, name: "Sub", amount: 9, category: "Bills",
            frequency: .monthly, startDate: Date()
        )
        context.insert(rec)

        let change = PendingChange(
            entityType: "recurring", entityID: recId,
            action: "delete", endpoint: "/recurring-transactions",
            httpMethod: "DELETE", payload: nil
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(pending.isEmpty)
        #expect(recurring.isEmpty)
    }

    // MARK: - Failure increments retryCount

    @Test func testReplayAllFailureIncrementsRetryCount() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.serverError }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        change.retryCount = 0
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.retryCount == 1)
    }

    // MARK: - 404 on DELETE → hard-delete local + remove pending

    @Test func testReplayAll404OnDeleteCleansUpLocally() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.deleteMessageHandler = { _ in throw APIError.notFound }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let txId = UUID()
        let tx = Transaction(id: txId, amount: 5, category: "Misc", date: Date())
        context.insert(tx)

        let change = PendingChange(
            entityType: "transaction", entityID: txId,
            action: "delete", endpoint: "/transactions",
            httpMethod: "DELETE", payload: nil
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        #expect(pending.isEmpty)
        #expect(txns.isEmpty)
    }

    // MARK: - 409 on CREATE → discard pending change (entity already on server)

    @Test func testReplayAll409OnCreateDiscardsPendingChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.conflict }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.isEmpty)
    }

    // MARK: - Unauthorized → posts authSessionExpired notification

    @Test func testReplayAllUnauthorizedPostsNotification() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.unauthorized }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        var notificationFired = false
        let observer = NotificationCenter.default.addObserver(
            forName: .authSessionExpired, object: nil, queue: nil
        ) { _ in notificationFired = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        await manager.replayAll(context: context, isAuthenticated: true)

        #expect(notificationFired)
    }

    // MARK: - Not authenticated → skips replay entirely

    @Test func testReplayAllSkipsWhenNotAuthenticated() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: false)

        // Nothing sent
        #expect(mock.postCalls.isEmpty)
        // Change still in queue
        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.count == 1)
    }

    // MARK: - SyncSession invalid → orphans queue and posts notification

    @Test func testReplayAllSyncSessionInvalidOrphansQueue() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.syncSessionInvalid(reason: "EXPIRED") }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        for _ in 0..<2 {
            let change = PendingChange(
                entityType: "transaction", entityID: UUID(),
                action: "create", endpoint: "/transactions",
                httpMethod: "POST", payload: "{}".data(using: .utf8)
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

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let orphans = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(pending.isEmpty)
        #expect(orphans.count == 2)
        #expect(notificationFired)
    }
}
