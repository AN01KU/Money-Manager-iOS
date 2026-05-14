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
        let svc = PersistenceService(changeQueue: MockChangeQueueManager.shared)
        svc.modelContext = context
        return svc
    }
    // MARK: - saveAndSync: no modelContext

    @Test func testSaveAndSyncWithNoContextDoesNotEnqueue() throws {
        MockChangeQueueManager.shared.reset()
        let svc = PersistenceService(changeQueue: MockChangeQueueManager.shared)
        try svc.saveAndSync(
            entityType: "transaction",
            entityID: UUID(),
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: nil
        )
        #expect(MockChangeQueueManager.shared.enqueueCallLog.isEmpty)
    }

    // MARK: - saveTransaction

    @Test func testSaveTransaction_create_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)
        try svc.saveTransaction(tx, action: "create")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "transaction")
        #expect(log[0].action == "create")
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == "POST")
        #expect(log[0].entityID == tx.id)
    }

    @Test func testSaveTransaction_update_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)
        try svc.saveTransaction(tx, action: "update")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "transaction")
        #expect(log[0].action == "update")
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == "PATCH")
    }

    @Test func testSaveTransaction_delete_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)
        try svc.saveTransaction(tx, action: "delete")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "transaction")
        #expect(log[0].action == "delete")
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == "DELETE")
        #expect(log[0].payload == nil)
    }

    @Test func testSaveTransaction_unknownAction_doesNotEnqueue() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)
        try svc.saveTransaction(tx, action: "unknown")
        #expect(MockChangeQueueManager.shared.enqueueCallLog.isEmpty)
    }

    // MARK: - saveRecurring

    @Test func testSaveRecurring_create_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        context.insert(r)
        try svc.saveRecurring(r, action: "create")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "recurring")
        #expect(log[0].action == "create")
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == "POST")
        #expect(log[0].entityID == r.id)
    }

    @Test func testSaveRecurring_update_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        context.insert(r)
        try svc.saveRecurring(r, action: "update")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "recurring")
        #expect(log[0].action == "update")
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == "PATCH")
    }

    @Test func testSaveRecurring_delete_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        context.insert(r)
        try svc.saveRecurring(r, action: "delete")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "recurring")
        #expect(log[0].action == "delete")
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == "DELETE")
        #expect(log[0].payload == nil)
    }

    // MARK: - saveCategory

    @Test func testSaveCategory_create_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Fitness", icon: "gym", color: "#FF0000")
        context.insert(cat)
        try svc.saveCategory(cat, action: "create")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "category")
        #expect(log[0].action == "create")
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == "POST")
        #expect(log[0].entityID == cat.id)
    }

    @Test func testSaveCategory_update_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Fitness", icon: "gym", color: "#FF0000")
        context.insert(cat)
        try svc.saveCategory(cat, action: "update")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "category")
        #expect(log[0].action == "update")
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == "PATCH")
    }

    @Test func testSaveCategory_delete_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Fitness", icon: "gym", color: "#FF0000")
        context.insert(cat)
        try svc.saveCategory(cat, action: "delete")
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "category")
        #expect(log[0].action == "delete")
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == "DELETE")
        #expect(log[0].payload == nil)
    }

    // MARK: - deleteCategory (id-only helper)

    @Test func testDeleteCategory_enqueuesDeleteWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let id = UUID()
        try svc.deleteCategory(id: id)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "category")
        #expect(log[0].action == "delete")
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == "DELETE")
        #expect(log[0].entityID == id)
    }

    // MARK: - enqueueCreate helpers (no modelContext.save)

    @Test func testEnqueueCreate_transaction_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let tx = Transaction(amount: 250, category: "Travel", date: Date())
        context.insert(tx)
        svc.enqueueCreate(tx, context: context)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "transaction")
        #expect(log[0].action == "create")
        #expect(log[0].endpoint == "/transactions")
        #expect(log[0].httpMethod == "POST")
        #expect(log[0].entityID == tx.id)
    }

    @Test func testEnqueueCreate_recurring_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let r = RecurringTransaction(name: "Spotify", amount: 199, category: "Music", frequency: .monthly)
        context.insert(r)
        svc.enqueueCreate(r, context: context)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "recurring")
        #expect(log[0].action == "create")
        #expect(log[0].endpoint == "/recurring-transactions")
        #expect(log[0].httpMethod == "POST")
    }

    @Test func testEnqueueUserBudget_enqueuesPutWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let budget = UserBudget(limit: 5000)
        context.insert(budget)
        svc.enqueueUserBudget(budget, context: context)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "budget")
        #expect(log[0].action == "create")
        #expect(log[0].endpoint == "/me/budget")
        #expect(log[0].httpMethod == "PUT")
    }

    @Test func testEnqueueCreate_category_enqueuesWithCorrectContract() throws {
        let context = try makeContext()
        let svc = makeService(context: context)
        let cat = Category(name: "Health", icon: "heart", color: "#FF0000")
        context.insert(cat)
        svc.enqueueCreate(cat, context: context)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log[0].entityType == "category")
        #expect(log[0].action == "create")
        #expect(log[0].endpoint == "/categories")
        #expect(log[0].httpMethod == "POST")
    }
}
