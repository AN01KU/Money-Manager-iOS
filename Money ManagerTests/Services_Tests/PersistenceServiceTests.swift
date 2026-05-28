import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct PersistenceServiceTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeService(context: ModelContext) -> PersistenceService {
        MockChangeQueueManager.shared.reset()
        return PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
    }

    // MARK: - save<T> Transaction (migrated from saveTransaction)

    @Test func testSaveTransaction_create_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, categoryId: UUID(), date: Date())
        context.insert(tx)
        try svc.save(tx, action: .create)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .transaction)
        #expect(log[0].action == .create)
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == .post)
        #expect(log[0].entityID == tx.id)
    }

    @Test func testSaveTransaction_update_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, categoryId: UUID(), date: Date())
        context.insert(tx)
        try svc.save(tx, action: .update)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .transaction)
        #expect(log[0].action == .update)
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == .patch)
    }

    @Test func testSaveTransaction_delete_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, categoryId: UUID(), date: Date())
        context.insert(tx)
        try svc.save(tx, action: .delete)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .transaction)
        #expect(log[0].action == .delete)
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == .delete)
        #expect(log[0].payload == nil)
    }

    // MARK: - save<RecurringTransaction>

    @Test func testSaveRecurring_create_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly)
        context.insert(r)
        try svc.save(r, action: .create)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .recurring)
        #expect(log[0].action == .create)
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == .post)
        #expect(log[0].entityID == r.id)
    }

    @Test func testSaveRecurring_update_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly)
        context.insert(r)
        try svc.save(r, action: .update)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .recurring)
        #expect(log[0].action == .update)
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == .patch)
    }

    @Test func testSaveRecurring_delete_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly)
        context.insert(r)
        try svc.save(r, action: .delete)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .recurring)
        #expect(log[0].action == .delete)
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == .delete)
        #expect(log[0].payload == nil)
    }

    // MARK: - save<Category>

    @Test func testSaveCategory_create_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Fitness", icon: "gym", color: "#FF0000")
        context.insert(cat)
        try svc.save(cat, action: .create)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .category)
        #expect(log[0].action == .create)
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == .post)
        #expect(log[0].entityID == cat.id)
    }

    @Test func testSaveCategory_update_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Fitness", icon: "gym", color: "#FF0000")
        context.insert(cat)
        try svc.save(cat, action: .update)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .category)
        #expect(log[0].action == .update)
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == .patch)
    }

    @Test func testSaveCategory_delete_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Fitness", icon: "gym", color: "#FF0000")
        context.insert(cat)
        try svc.save(cat, action: .delete)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .category)
        #expect(log[0].action == .delete)
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == .delete)
        #expect(log[0].payload == nil)
    }

    // MARK: - save<T> (generic)

    @Test func testSaveGeneric_transaction_create_enqueuesCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 150, categoryId: UUID(), date: Date())
        context.insert(tx)
        try svc.save(tx, action: .create)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .transaction)
        #expect(log[0].action == .create)
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == .post)
        #expect(log[0].entityID == tx.id)
        #expect(log[0].payload != nil)
    }

    @Test func testSaveGeneric_transaction_update_enqueuesCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 150, categoryId: UUID(), date: Date())
        context.insert(tx)
        try svc.save(tx, action: .update)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .transaction)
        #expect(log[0].action == .update)
        #expect(log[0].httpMethod == .patch)
        #expect(log[0].payload != nil)
    }

    @Test func testSaveGeneric_transaction_delete_enqueuesNoPayload() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 150, categoryId: UUID(), date: Date())
        context.insert(tx)
        try svc.save(tx, action: .delete)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .transaction)
        #expect(log[0].action == .delete)
        #expect(log[0].httpMethod == .delete)
        #expect(log[0].payload == nil)
    }

    // MARK: - Soft-delete semantics (centralized in PersistenceService)

    @Test func testSaveTransaction_delete_marksSoftDeletedAndBumpsUpdatedAt() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, categoryId: UUID(), date: Date())
        context.insert(tx)
        // Backdate updatedAt so we can assert it advances.
        let oldUpdatedAt = Date(timeIntervalSinceNow: -3600)
        tx.updatedAt = oldUpdatedAt
        #expect(tx.isSoftDeleted == false)

        try svc.save(tx, action: .delete)

        #expect(tx.isSoftDeleted == true)
        #expect(tx.updatedAt > oldUpdatedAt)
    }

    @Test func testSaveRecurring_delete_marksSoftDeletedAndBumpsUpdatedAt() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly)
        context.insert(r)
        let oldUpdatedAt = Date(timeIntervalSinceNow: -3600)
        r.updatedAt = oldUpdatedAt
        #expect(r.isSoftDeleted == false)

        try svc.save(r, action: .delete)

        #expect(r.isSoftDeleted == true)
        #expect(r.updatedAt > oldUpdatedAt)
    }

    @Test func testSaveGeneric_recurringTransaction_create_enqueuesCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Gym", amount: 999, categoryId: UUID(), frequency: .monthly)
        context.insert(r)
        try svc.save(r, action: .create)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .recurring)
        #expect(log[0].action == .create)
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == .post)
        #expect(log[0].entityID == r.id)
        #expect(log[0].payload != nil)
    }

    @Test func testSaveGeneric_category_update_enqueuesCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Shopping", icon: "bag", color: "#00FF00")
        context.insert(cat)
        try svc.save(cat, action: .update)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .category)
        #expect(log[0].action == .update)
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == .patch)
        #expect(log[0].entityID == cat.id)
        #expect(log[0].payload != nil)
    }

    // MARK: - deleteCategory (id-only helper)

    @Test func testDeleteCategory_enqueuesDeleteWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let id = UUID()
        try svc.deleteCategory(id: id)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .category)
        #expect(log[0].action == .delete)
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == .delete)
        #expect(log[0].entityID == id)
    }

    // MARK: - enqueueUserBudget helper (no modelContext.save)

    @Test func testEnqueueUserBudget_enqueuesPutWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let budget = UserBudget(limit: 5000)
        context.insert(budget)
        svc.enqueueUserBudget(budget, context: context)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == .budget)
        #expect(log[0].action == .create)
        #expect(log[0].endpoint == "/me/budget")
        #expect(log[0].httpMethod == .put)
    }
}
