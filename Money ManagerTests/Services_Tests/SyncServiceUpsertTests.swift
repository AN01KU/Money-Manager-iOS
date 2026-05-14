import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for SyncService upsert logic — transactions, recurring, budgets, and categories.
/// Uses MockAPIClient + MockAuthService so no network or Keychain access is needed.
@MainActor
struct SyncServiceUpsertTests {

    // MARK: - Helpers

    private func makeAuth() -> MockAuthService {
        MockAuthService.shared
    }

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    /// Returns a SyncService.shared configured with in-memory container and mock auth.
    /// Sets the apiClient to the provided mock.
    private func makeSyncService(
        container: ModelContainer,
        mock: MockAPIClient
    ) -> SyncService {
        let svc = SyncService.shared
        svc.configure(container: container, authService: makeAuth())
        svc.apiClient = mock
        return svc
    }

    private func apiTransaction(
        id: UUID = UUID(),
        category: String = "Food",
        amount: Double = 10,
        updatedAt: Date = Date()
    ) -> APITransaction {
        APITransaction(
            id: id, userId: UUID(), type: "expense",
            amount: amount, category: category,
            date: Date(), time: nil,
            description: nil, notes: nil,
            createdAt: Date(), updatedAt: updatedAt,
            isDeleted: false,
            recurringExpenseId: nil, groupTransactionId: nil,
            groupId: nil, groupName: nil, settlementId: nil
        )
    }

    private func apiRecurring(
        id: UUID = UUID(),
        category: String = "Bills",
        updatedAt: Date = Date()
    ) -> APIRecurringTransaction {
        APIRecurringTransaction(
            id: id, userId: UUID(),
            name: "Monthly Bill", amount: 50,
            category: category, frequency: "monthly",
            dayOfMonth: 1, daysOfWeek: nil,
            startDate: Date(), endDate: nil,
            isActive: true, lastAddedDate: nil,
            nextOccurrence: nil, notes: nil,
            createdAt: Date(), updatedAt: updatedAt,
            type: "expense"
        )
    }

    private func apiCategory(
        id: UUID = UUID(),
        key: String = "custom-key",
        name: String = "Custom",
        icon: String = "star",
        color: String = "#FF0000",
        isPredefined: Bool = false,
        predefinedKey: String? = nil,
        isHidden: Bool = false,
        updatedAt: Date = Date()
    ) -> APICategory {
        APICategory(
            id: id, userId: UUID(),
            key: key,
            name: name, icon: icon, color: color,
            isHidden: isHidden,
            isPredefined: isPredefined,
            predefinedKey: predefinedKey,
            createdAt: Date(), updatedAt: updatedAt
        )
    }

    /// Builds a mock that returns the given typed objects for GET calls.
    private func mockReturningSync(
        transactions: [APITransaction] = [],
        recurring: [APIRecurringTransaction] = [],
        userBudget: APIUserBudget? = nil,
        categories: [APICategory] = []
    ) -> MockAPIClient {
        let mock = MockAPIClient()
        mock.getHandler = { endpoint in
            switch endpoint {
            case .syncCategories:
                return APIListResponse(data: categories)
            case .getBudget:
                return userBudget ?? APIUserBudget(limit: nil)
            case .syncRecurring:
                return APIListResponse(data: recurring)
            case .syncTransactions:
                return APIPaginatedResponse(
                    data: transactions,
                    pagination: .init(limit: 100, offset: 0, total: transactions.count)
                )
            default:
                throw MockAPIClient.MockError.notConfigured
            }
        }
        // ChangeQueueManager also needs rawPost/deleteMessage for replayAll — stub as success
        mock.rawPostHandler = { _, _ in EmptyResponse() }
        mock.deleteMessageHandler = { _ in APIMessageResponse(message: "ok") }
        return mock
    }

    // MARK: - upsertTransactions: new transaction from server

    @Test func testFullSyncInsertsNewTransactionFromServer() async throws {
        let container = try makeContainer()
        let txn = apiTransaction(category: "Food", amount: 42)
        let mock = mockReturningSync(transactions: [txn])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let context = ModelContext(container)
        let local = try context.fetch(FetchDescriptor<Transaction>())
        #expect(local.count == 1)
        #expect(local.first?.amount == 42)
        #expect(local.first?.category == "Food")
    }

    // MARK: - upsertTransactions: updates existing transaction when server is newer

    @Test func testFullSyncUpdatesTransactionWhenServerIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let txId = UUID()
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        // Insert an older local version
        let localTx = Transaction(id: txId, amount: 10, category: "Food", date: Date())
        localTx.updatedAt = old
        context.insert(localTx)
        try context.save()

        let serverTx = apiTransaction(id: txId, category: "Food", amount: 99, updatedAt: newer)
        let mock = mockReturningSync(transactions: [serverTx])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let all = try context.fetch(FetchDescriptor<Transaction>())
        #expect(all.count == 1)
        #expect(all.first?.amount == 99)
    }

    // MARK: - upsertTransactions: skips transaction with empty category

    @Test func testFullSyncSkipsTransactionWithEmptyCategory() async throws {
        let container = try makeContainer()
        let invalid = apiTransaction(category: "  ")
        let mock = mockReturningSync(transactions: [invalid])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let context = ModelContext(container)
        let local = try context.fetch(FetchDescriptor<Transaction>())
        #expect(local.isEmpty)
    }

    // MARK: - upsertTransactions: purges server-owned transaction not returned by server

    @Test func testFullSyncPurgesServerOwnedTransactionMissingFromServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        // Local recurring-linked transaction not in server response
        let tx = Transaction(id: UUID(), amount: 5, category: "Sub", date: Date())
        tx.recurringExpenseId = UUID() // makes it server-owned
        context.insert(tx)
        try context.save()

        // Server returns empty list (transaction is gone)
        let mock = mockReturningSync(transactions: [])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let local = try context.fetch(FetchDescriptor<Transaction>())
        #expect(local.isEmpty)
    }

    // MARK: - upsertRecurring: inserts new recurring from server

    @Test func testFullSyncInsertsNewRecurringFromServer() async throws {
        let container = try makeContainer()
        let rec = apiRecurring(category: "Bills")
        let mock = mockReturningSync(recurring: [rec])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let context = ModelContext(container)
        let local = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(local.count == 1)
        #expect(local.first?.category == "Bills")
    }

    // MARK: - upsertRecurring: updates existing recurring when server is newer

    @Test func testFullSyncUpdatesRecurringWhenServerIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let recId = UUID()
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        let localRec = RecurringTransaction(
            id: recId, name: "OldName", amount: 5, category: "Bills",
            frequency: .monthly, startDate: Date()
        )
        localRec.updatedAt = old
        context.insert(localRec)
        try context.save()

        let serverRec = apiRecurring(id: recId, category: "Bills", updatedAt: newer)
        let mock = mockReturningSync(recurring: [serverRec])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let all = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(all.count == 1)
        #expect(all.first?.amount == 50)
    }

    // MARK: - upsertRecurring: skips recurring with empty category

    @Test func testFullSyncSkipsRecurringWithEmptyCategory() async throws {
        let container = try makeContainer()
        let invalid = apiRecurring(category: "")
        let mock = mockReturningSync(recurring: [invalid])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let context = ModelContext(container)
        let local = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(local.isEmpty)
    }

    // MARK: - upsertUserBudget: inserts scalar budget from server

    @Test func testFullSyncInsertsNewBudgetFromServer() async throws {
        let container = try makeContainer()
        let mock = mockReturningSync(userBudget: APIUserBudget(limit: 5000))
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let context = ModelContext(container)
        let local = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(local.count == 1)
        #expect(local.first?.limit == 5000)
    }

    // MARK: - upsertUserBudget: overwrites local scalar when server responds

    @Test func testFullSyncUpdatesBudgetWhenServerIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(UserBudget(limit: 300))
        try context.save()

        let mock = mockReturningSync(userBudget: APIUserBudget(limit: 800))
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 800)
    }

    // MARK: - upsertCategories: inserts new custom category from server

    @Test func testFullSyncInsertsNewCategoryFromServer() async throws {
        let container = try makeContainer()
        let cat = apiCategory(name: "Travel", icon: "airplane", color: "#00FF00")
        let mock = mockReturningSync(categories: [cat])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let context = ModelContext(container)
        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.count == 1)
        #expect(local.first?.name == "Travel")
    }

    // MARK: - upsertCategories: skips category with empty name

    @Test func testFullSyncSkipsCategoryWithEmptyName() async throws {
        let container = try makeContainer()
        let invalid = apiCategory(name: "  ")
        let mock = mockReturningSync(categories: [invalid])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let context = ModelContext(container)
        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.isEmpty)
    }

    // MARK: - upsertCategories: updates existing custom category when server is newer

    @Test func testFullSyncUpdatesCategoryWhenServerIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let catId = UUID()
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        let localCat = Category(id: catId, name: "OldName", icon: "star", color: "#FF0000")
        localCat.updatedAt = old
        context.insert(localCat)
        try context.save()

        let serverCat = apiCategory(id: catId, name: "NewName", icon: "leaf", color: "#00FF00", updatedAt: newer)
        let mock = mockReturningSync(categories: [serverCat])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let all = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(all.count == 1)
        #expect(all.first?.name == "NewName")
    }

    // MARK: - upsertCategories: purges custom category not returned by server

    @Test func testFullSyncPurgesCategoryNotOnServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let stale = Category(name: "Stale", icon: "trash", color: "#888888")
        stale.isPredefined = false
        context.insert(stale)
        try context.save()

        // Server returns empty
        let mock = mockReturningSync(categories: [])
        let svc = makeSyncService(container: container, mock: mock)

        await svc.fullSync()

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.isEmpty)
    }

    // MARK: - clearAllUserData removes all local data

    @Test func testClearAllUserDataRemovesEverything() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(Transaction(amount: 5, category: "Food", date: Date()))
        context.insert(RecurringTransaction(name: "Sub", amount: 10, category: "Bills", frequency: .monthly, startDate: Date()))
        context.insert(MonthlyBudget(year: 2025, month: 1, limit: 500))
        context.insert(UserBudget(limit: 5000))
        context.insert(Category(name: "Travel", icon: "star", color: "#000"))
        try context.save()

        let svc = makeSyncService(container: container, mock: MockAPIClient())
        svc.clearAllUserData()

        #expect(try context.fetch(FetchDescriptor<Transaction>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RecurringTransaction>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MonthlyBudget>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<UserBudget>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Money_Manager.Category>()).isEmpty)
    }
}
