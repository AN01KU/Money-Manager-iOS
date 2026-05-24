import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Unit tests for `TransactionPullHandler` — verifies decode, LWW apply, insert, and purge
/// logic independently of `SyncService`. Each test constructs the handler directly.
@MainActor
struct TransactionPullHandlerTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer { try makeTestContainer() }

    private func makeChangeQueue() -> MockChangeQueueManager { MockChangeQueueManager.shared }

    private func makeAPIClient(transactions: [APITransaction]) -> MockAPIClient {
        let mock = MockAPIClient()
        mock.getHandler = { _ in
            APIPaginatedResponse(
                data: transactions,
                pagination: .init(limit: 100, offset: 0, total: transactions.count)
            )
        }
        return mock
    }

    private func apiTransaction(
        id: UUID = UUID(),
        category: String = "Food",
        amount: Double = 10,
        updatedAt: Date = Date(),
        recurringExpenseId: UUID? = nil,
        groupTransactionId: UUID? = nil,
        settlementId: UUID? = nil
    ) -> APITransaction {
        APITransaction(
            id: id, userId: UUID(), type: .expense,
            amount: amount, category: category,
            date: Date(), time: nil,
            description: nil, notes: nil,
            createdAt: Date(), updatedAt: updatedAt,
            isDeleted: false,
            recurringExpenseId: recurringExpenseId,
            groupTransactionId: groupTransactionId,
            groupId: nil, groupName: nil,
            settlementId: settlementId
        )
    }

    // MARK: - Insert new transaction from server

    @Test func testPullInsertsNewTransactionFromServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = TransactionPullHandler()
        let mock = makeAPIClient(transactions: [apiTransaction(amount: 55)])

        try await handler.pull(api: mock, changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Transaction>())
        #expect(local.count == 1)
        #expect(local.first?.amount == 55)
    }

    // MARK: - LWW: server wins when newer

    @Test func testPullAppliesServerUpdateWhenNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let txId = UUID()
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        let local = Transaction(id: txId, amount: 10, category: "Food", date: Date())
        local.updatedAt = old
        context.insert(local)
        try context.save()

        let remote = apiTransaction(id: txId, amount: 99, updatedAt: newer)
        let handler = TransactionPullHandler()
        try await handler.pull(api: makeAPIClient(transactions: [remote]), changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<Transaction>())
        #expect(all.count == 1)
        #expect(all.first?.amount == 99)
    }

    // MARK: - LWW: local wins when newer

    @Test func testPullKeepsLocalWhenLocalIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let txId = UUID()
        let newer = Date(timeIntervalSinceNow: -10)
        let older = Date(timeIntervalSinceNow: -3600)

        let local = Transaction(id: txId, amount: 42, category: "Food", date: Date())
        local.updatedAt = newer
        context.insert(local)
        try context.save()

        let remote = apiTransaction(id: txId, amount: 1, updatedAt: older)
        let handler = TransactionPullHandler()
        try await handler.pull(api: makeAPIClient(transactions: [remote]), changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<Transaction>())
        #expect(all.count == 1)
        #expect(all.first?.amount == 42)  // local value kept
    }

    // MARK: - Validation: skip transaction with empty category

    @Test func testPullSkipsTransactionWithEmptyCategory() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = TransactionPullHandler()
        let invalid = apiTransaction(category: "   ")
        try await handler.pull(api: makeAPIClient(transactions: [invalid]), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Transaction>())
        #expect(local.isEmpty)
    }

    // MARK: - Purge: server-owned transaction missing from server

    @Test func testPullPurgesServerOwnedTransactionNotOnServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tx = Transaction(id: UUID(), amount: 5, category: "Sub", date: Date())
        tx.recurringExpenseId = UUID()  // marks as server-owned
        context.insert(tx)
        try context.save()

        let handler = TransactionPullHandler()
        try await handler.pull(api: makeAPIClient(transactions: []), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Transaction>())
        #expect(local.isEmpty)
    }

    // MARK: - Purge: personal offline transaction is kept

    @Test func testPullKeepsPersonalOfflineTransactionNotOnServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        // No recurringExpenseId / groupTransactionId / settlementId — plain personal txn
        let tx = Transaction(id: UUID(), amount: 20, category: "Coffee", date: Date())
        context.insert(tx)
        try context.save()

        let handler = TransactionPullHandler()
        try await handler.pull(api: makeAPIClient(transactions: []), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Transaction>())
        #expect(local.count == 1)  // kept — personal offline transaction
    }

    // MARK: - lastServerCount / lastLocalCount populated after pull

    @Test func testPullSetsServerAndLocalCounts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(Transaction(id: UUID(), amount: 1, category: "A", date: Date()))
        context.insert(Transaction(id: UUID(), amount: 2, category: "B", date: Date()))
        try context.save()

        let remote = [apiTransaction(amount: 10), apiTransaction(amount: 20), apiTransaction(amount: 30)]
        let handler = TransactionPullHandler()
        try await handler.pull(api: makeAPIClient(transactions: remote), changeQueue: makeChangeQueue(), context: context)

        #expect(handler.lastServerCount == 3)
        #expect(handler.lastLocalCount == 2)  // snapshot taken before upsert
    }

    // MARK: - Pipeline integration: pull pipeline calls handler and checkpoints

    @Test func testPipelineCallsHandlerAndCheckpoints() async throws {
        let container = try makeContainer()
        let mock = MockAPIClient()
        mock.getHandler = { endpoint in
            switch endpoint {
            case .predefinedCategories:  return APIListResponse<APIPredefinedCategory>(data: [])
            case .syncCategories:        return APIListResponse<APICategory>(data: [])
            case .getBudget:             return APIUserBudget(limit: nil)
            case .syncRecurring:         return APIListResponse<APIRecurringTransaction>(data: [])
            case .syncTransactions:
                return APIPaginatedResponse<APITransaction>(
                    data: [self.apiTransaction(amount: 77)],
                    pagination: .init(limit: 100, offset: 0, total: 1)
                )
            default: throw MockAPIClient.MockError.notConfigured
            }
        }
        let svc = SyncService(
            api: mock,
            changeQueue: ChangeQueueManager(),
            networkMonitor: MockNetworkMonitor(isConnected: true),
            authService: MockAuthService.shared,
            container: container
        )

        await svc.fullSync()

        let context = ModelContext(container)
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        #expect(txns.count == 1)
        #expect(txns.first?.amount == 77)
    }
}
