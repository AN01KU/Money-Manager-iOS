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

        #expect(mock.postCalls.isEmpty)
        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.count == 1)
    }

    // MARK: - Backoff window skips items not yet due

    @Test func testReplayAllSkipsItemsInBackoffWindow() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = ChangeQueueManager()
        manager.configure(container: container)

        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        change.nextRetryAt = Date(timeIntervalSinceNow: 3600)
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(pending.count == 1)
    }

    // MARK: - Max retry limit → dead letter

    @Test func testReplayAllMovesExhaustedChangeToDeadLetter() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = ChangeQueueManager()
        manager.configure(container: container)

        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        change.retryCount = ChangeQueueManager.maxRetryCount
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty)
        #expect(failed.count == 1)
    }

    // MARK: - 404 on UPDATE → purge local entity + remove pending (issue #32)

    @Test func testReplayAll404OnUpdateTransactionPurgesLocalEntityAndRemovesPending() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPatchHandler = { _, _ in throw APIError.notFound }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let txId = UUID()
        let tx = Transaction(id: txId, amount: 20, category: "Food", date: Date())
        context.insert(tx)

        let change = PendingChange(
            entityType: "transaction", entityID: txId,
            action: "update", endpoint: "/transactions",
            httpMethod: "PATCH", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty, "pending change should be removed")
        #expect(txns.isEmpty, "local transaction should be purged")
        #expect(failed.isEmpty, "should NOT dead-letter a 404 on update")
    }

    @Test func testReplayAll404OnUpdateRecurringPurgesLocalEntityAndRemovesPending() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPatchHandler = { _, _ in throw APIError.notFound }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let recId = UUID()
        let rec = RecurringTransaction(
            id: recId, name: "Netflix", amount: 15, category: "Entertainment",
            frequency: .monthly, startDate: Date()
        )
        context.insert(rec)

        let change = PendingChange(
            entityType: "recurring", entityID: recId,
            action: "update", endpoint: "/recurring-transactions",
            httpMethod: "PATCH", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty)
        #expect(recurring.isEmpty)
        #expect(failed.isEmpty)
    }

    @Test func testReplayAll404OnUpdateCategoryPurgesLocalEntityAndRemovesPending() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPatchHandler = { _, _ in throw APIError.notFound }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let catId = UUID()
        let cat = Money_Manager.Category(id: catId, name: "Travel", icon: "airplane", color: "#FF0000")
        context.insert(cat)

        let change = PendingChange(
            entityType: "category", entityID: catId,
            action: "update", endpoint: "/categories",
            httpMethod: "PATCH", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let categories = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty)
        #expect(categories.isEmpty)
        #expect(failed.isEmpty)
    }

    @Test func testReplayAll404OnCreateStillDeadLetters() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.notFound }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let change = PendingChange(
            entityType: "transaction", entityID: UUID(),
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        change.retryCount = ChangeQueueManager.maxRetryCount - 1
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        // After one more failure (hitting max), moves to dead-letter — NOT purged
        #expect(pending.isEmpty)
        #expect(failed.count == 1, "404 on create should dead-letter, not purge entity")
    }

    // MARK: - ID_OWNED_BY_ANOTHER_USER / GROUP → purge entity + discard (issue #39)

    @Test func testReplayAllIdOwnedByAnotherUserOnCreatePurgesEntityAndDiscardsChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.idOwnedByAnotherUser }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let txId = UUID()
        let tx = Transaction(id: txId, amount: 50, category: "Food", date: Date())
        context.insert(tx)

        let change = PendingChange(
            entityType: "transaction", entityID: txId,
            action: "create", endpoint: "/transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty, "pending change should be discarded")
        #expect(txns.isEmpty, "local entity should be purged")
        #expect(failed.isEmpty, "should NOT dead-letter — purge and discard immediately")
    }

    @Test func testReplayAllIdOwnedByAnotherUserOnUpdatePurgesEntityAndDiscardsChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPatchHandler = { _, _ in throw APIError.idOwnedByAnotherUser }
        let manager = ChangeQueueManager(apiClient: mock)
        manager.configure(container: container)

        let txId = UUID()
        let tx = Transaction(id: txId, amount: 50, category: "Food", date: Date())
        context.insert(tx)

        let change = PendingChange(
            entityType: "transaction", entityID: txId,
            action: "update", endpoint: "/transactions",
            httpMethod: "PATCH", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty)
        #expect(txns.isEmpty)
        #expect(failed.isEmpty)
    }

    @Test func testReplayAllIdOwnedByAnotherGroupOnCreatePurgesEntityAndDiscardsChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPostHandler = { _, _ in throw APIError.idOwnedByAnotherGroup }
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
            action: "create", endpoint: "/recurring-transactions",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty)
        #expect(recurring.isEmpty)
        #expect(failed.isEmpty)
    }

    @Test func testReplayAllIdOwnedByAnotherGroupOnUpdatePurgesEntityAndDiscardsChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let mock = MockAPIClient()
        mock.rawPatchHandler = { _, _ in throw APIError.idOwnedByAnotherGroup }
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
            action: "update", endpoint: "/recurring-transactions",
            httpMethod: "PATCH", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        let failed = try context.fetch(FetchDescriptor<FailedChange>())
        #expect(pending.isEmpty)
        #expect(recurring.isEmpty)
        #expect(failed.isEmpty)
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
