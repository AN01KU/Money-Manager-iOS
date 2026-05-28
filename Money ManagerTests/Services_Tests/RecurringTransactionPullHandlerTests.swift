import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Unit tests for `RecurringTransactionPullHandler` — verifies insert, LWW, validation,
/// soft-delete skip, purge, and count tracking independently of `SyncService`.
@MainActor
struct RecurringTransactionPullHandlerTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer { try makeTestContainer() }

    private func makeChangeQueue() -> MockChangeQueueManager { MockChangeQueueManager.shared }

    private func makeAPIClient(recurring: [APIRecurringTransaction]) -> MockAPIClient {
        let mock = MockAPIClient()
        mock.getHandler = { _ in APIListResponse(data: recurring) }
        return mock
    }

    private func apiRecurring(
        id: UUID = UUID(),
        name: String = "Netflix",
        amount: Double = 15,
        category: String = "Entertainment",
        frequency: String = "monthly",
        updatedAt: Date = Date()
    ) -> APIRecurringTransaction {
        APIRecurringTransaction(
            id: id, userId: UUID(),
            name: name, amount: amount, category: category,
            frequency: frequency,
            dayOfMonth: nil, daysOfWeek: nil,
            startDate: Date(), endDate: nil,
            isActive: true, lastAddedDate: nil, nextOccurrence: nil,
            notes: nil, createdAt: Date(), updatedAt: updatedAt,
            type: .expense
        )
    }

    // MARK: - Insert new recurring from server

    @Test func testPullInsertsNewRecurringFromServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = RecurringTransactionPullHandler()

        try await handler.pull(api: makeAPIClient(recurring: [apiRecurring(amount: 25)]),
                               changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(local.count == 1)
        #expect(local.first?.amount == 25)
    }

    // MARK: - LWW: server wins when newer

    @Test func testPullAppliesServerUpdateWhenNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let rid = UUID()
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        let local = RecurringTransaction(id: rid, name: "Spotify", amount: 10, categoryId: UUID(),
                                         frequency: .monthly, startDate: Date())
        local.updatedAt = old
        context.insert(local)
        try context.save()

        let remote = apiRecurring(id: rid, name: "Spotify Pro", amount: 20, updatedAt: newer)
        let handler = RecurringTransactionPullHandler()
        try await handler.pull(api: makeAPIClient(recurring: [remote]),
                               changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(all.count == 1)
        #expect(all.first?.amount == 20)
        #expect(all.first?.name == "Spotify Pro")
    }

    // MARK: - LWW: local wins when newer

    @Test func testPullKeepsLocalWhenLocalIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let rid = UUID()
        let newer = Date(timeIntervalSinceNow: -10)
        let older = Date(timeIntervalSinceNow: -3600)

        let local = RecurringTransaction(id: rid, name: "Gym", amount: 50, categoryId: UUID(),
                                         frequency: .monthly, startDate: Date())
        local.updatedAt = newer
        context.insert(local)
        try context.save()

        let remote = apiRecurring(id: rid, amount: 1, updatedAt: older)
        let handler = RecurringTransactionPullHandler()
        try await handler.pull(api: makeAPIClient(recurring: [remote]),
                               changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(all.count == 1)
        #expect(all.first?.amount == 50)
    }

    // MARK: - Validation: skip recurring with empty category

    @Test func testPullSkipsRecurringWithEmptyCategory() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = RecurringTransactionPullHandler()
        let invalid = apiRecurring(category: "")

        try await handler.pull(api: makeAPIClient(recurring: [invalid]),
                               changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(local.isEmpty)
    }

    // MARK: - Soft-deleted local row is not updated

    @Test func testPullSkipsSoftDeletedLocalRow() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let rid = UUID()
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        let local = RecurringTransaction(id: rid, name: "Old Sub", amount: 5, categoryId: UUID(),
                                         frequency: .monthly, startDate: Date(), isSoftDeleted: true)
        local.updatedAt = old
        context.insert(local)
        try context.save()

        let remote = apiRecurring(id: rid, amount: 99, updatedAt: newer)
        let handler = RecurringTransactionPullHandler()
        try await handler.pull(api: makeAPIClient(recurring: [remote]),
                               changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(all.count == 1)
        #expect(all.first?.amount == 5)  // soft-deleted row untouched
    }

    // MARK: - Purge: local row absent from server is deleted

    @Test func testPullPurgesLocalRecurringNotOnServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let local = RecurringTransaction(id: UUID(), name: "Stale", amount: 5, categoryId: UUID(),
                                         frequency: .monthly, startDate: Date())
        context.insert(local)
        try context.save()

        let handler = RecurringTransactionPullHandler()
        try await handler.pull(api: makeAPIClient(recurring: []),
                               changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(all.isEmpty)
    }

    // MARK: - Purge: local row with pending change is kept

    @Test func testPullKeepsRecurringWithPendingChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let rid = UUID()

        let local = RecurringTransaction(id: rid, name: "Pending Sub", amount: 8, categoryId: UUID(),
                                         frequency: .monthly, startDate: Date())
        context.insert(local)

        let pending = PendingChange(entityType: "recurring", entityID: rid, action: "create",
                                    endpoint: "/recurring-transactions", httpMethod: "POST", payload: Data())
        context.insert(pending)
        try context.save()

        let handler = RecurringTransactionPullHandler()
        try await handler.pull(api: makeAPIClient(recurring: []),
                               changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(all.count == 1)
    }

    // MARK: - lastServerCount / lastLocalCount populated after pull

    @Test func testPullSetsServerAndLocalCounts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(RecurringTransaction(id: UUID(), name: "A", amount: 1, categoryId: UUID(),
                                             frequency: .monthly, startDate: Date()))
        try context.save()

        let remote = [apiRecurring(amount: 10), apiRecurring(amount: 20)]
        let handler = RecurringTransactionPullHandler()
        try await handler.pull(api: makeAPIClient(recurring: remote),
                               changeQueue: makeChangeQueue(), context: context)

        #expect(handler.lastServerCount == 2)
        #expect(handler.lastLocalCount == 1)
    }
}
