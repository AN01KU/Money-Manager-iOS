import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Unit tests for `UserBudgetPullHandler` — verifies insert, overwrite, pending-guard,
/// and count tracking independently of `SyncService`.
@MainActor
struct UserBudgetPullHandlerTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer { try makeTestContainer() }

    private func makeChangeQueue() -> MockChangeQueueManager { MockChangeQueueManager.shared }

    private func makeAPIClient(limit: Double?) -> MockAPIClient {
        let mock = MockAPIClient()
        mock.getHandler = { _ in APIUserBudget(limit: limit) }
        return mock
    }

    // MARK: - Insert new budget when none exists

    @Test func testPullInsertsBudgetWhenNoneExists() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = UserBudgetPullHandler()

        try await handler.pull(api: makeAPIClient(limit: 3000), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(local.count == 1)
        #expect(local.first?.limit == 3000)
    }

    // MARK: - Overwrites existing budget with server value

    @Test func testPullOverwritesExistingBudgetWithServerValue() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(UserBudget(limit: 500))
        try context.save()

        let handler = UserBudgetPullHandler()
        try await handler.pull(api: makeAPIClient(limit: 8000), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(local.count == 1)
        #expect(local.first?.limit == 8000)
    }

    // MARK: - Inserts nil limit from server

    @Test func testPullInsertsNilLimitFromServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = UserBudgetPullHandler()

        try await handler.pull(api: makeAPIClient(limit: nil), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(local.count == 1)
        #expect(local.first?.limit == nil)
    }

    // MARK: - Pending-guard: skips server value when pending budget change queued

    @Test func testPullSkipsServerValueWhenPendingBudgetChangeExists() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(UserBudget(limit: 1234))
        let pending = PendingChange(
            entityType: "budget",
            entityID: UserBudget.sentinelID,
            action: "update",
            endpoint: "/me/budget",
            httpMethod: "PUT",
            payload: Data()
        )
        context.insert(pending)
        try context.save()

        let handler = UserBudgetPullHandler()
        try await handler.pull(api: makeAPIClient(limit: 9999), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(local.count == 1)
        // Local value preserved — server value skipped
        #expect(local.first?.limit == 1234)
    }

    // MARK: - lastServerCount / lastLocalCount populated after pull

    @Test func testPullSetsServerAndLocalCounts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(UserBudget(limit: 100))
        try context.save()

        let handler = UserBudgetPullHandler()
        try await handler.pull(api: makeAPIClient(limit: 200), changeQueue: makeChangeQueue(), context: context)

        #expect(handler.lastServerCount == 1)
        #expect(handler.lastLocalCount == 1)
    }

    // MARK: - No local budget, nil server limit: inserts row with nil limit

    @Test func testPullCreatesRowWithNilLimitWhenNoBudgetExists() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = UserBudgetPullHandler()

        try await handler.pull(api: makeAPIClient(limit: nil), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(local.count == 1)
        #expect(local.first?.limit == nil)
    }
}
