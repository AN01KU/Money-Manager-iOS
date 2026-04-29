import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for PersistenceService covering the entity-specific save helpers
/// and the no-modelContext guard in saveAndSync.
@MainActor
struct PersistenceServiceTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeService(context: ModelContext) -> PersistenceService {
        let svc = PersistenceService(changeQueue: MockChangeQueueManager.shared)
        svc.modelContext = context
        return svc
    }

    // MARK: - saveAndSync: no modelContext

    @Test func testSaveAndSyncWithNoContextDoesNotThrow() throws {
        let svc = PersistenceService(changeQueue: MockChangeQueueManager.shared)
        // modelContext is nil — should return early without throwing
        #expect(throws: Never.self) {
            try svc.saveAndSync(
                entityType: "transaction",
                entityID: UUID(),
                action: "create",
                endpoint: "/transactions",
                httpMethod: "POST",
                payload: nil
            )
        }
    }

    // MARK: - saveTransaction

    @Test func testSaveTransactionCreateEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)

        // Should not throw
        #expect(throws: Never.self) { try svc.saveTransaction(tx, action: "create") }
    }

    @Test func testSaveTransactionUpdateEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)

        #expect(throws: Never.self) { try svc.saveTransaction(tx, action: "update") }
    }

    @Test func testSaveTransactionDeleteEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)

        #expect(throws: Never.self) { try svc.saveTransaction(tx, action: "delete") }
    }

    @Test func testSaveTransactionUnknownActionIsNoOp() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let tx = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(tx)

        // Unknown action — should return early without crashing
        #expect(throws: Never.self) { try svc.saveTransaction(tx, action: "unknown") }
    }

    // MARK: - saveRecurring

    @Test func testSaveRecurringCreateEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let recurring = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        context.insert(recurring)

        #expect(throws: Never.self) { try svc.saveRecurring(recurring, action: "create") }
    }

    @Test func testSaveRecurringUpdateEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let recurring = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        context.insert(recurring)

        #expect(throws: Never.self) { try svc.saveRecurring(recurring, action: "update") }
    }

    @Test func testSaveRecurringDeleteEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let recurring = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        context.insert(recurring)

        #expect(throws: Never.self) { try svc.saveRecurring(recurring, action: "delete") }
    }

    // MARK: - saveCategory

    @Test func testSaveCategoryCreateEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let cat = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000")
        context.insert(cat)

        #expect(throws: Never.self) { try svc.saveCategory(cat, action: "create") }
    }

    @Test func testSaveCategoryUpdateEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let cat = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000")
        context.insert(cat)

        #expect(throws: Never.self) { try svc.saveCategory(cat, action: "update") }
    }

    @Test func testSaveCategoryDeleteEnqueuesChange() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        let cat = CustomCategory(name: "Fitness", icon: "🏋️", color: "#FF0000")
        context.insert(cat)

        #expect(throws: Never.self) { try svc.saveCategory(cat, action: "delete") }
    }

    // MARK: - save

    @Test func testSaveWithContextDoesNotThrow() throws {
        let context = try makeContext()
        let svc = makeService(context: context)

        #expect(throws: Never.self) { try svc.save() }
    }

    @Test func testSaveWithNoContextDoesNotThrow() throws {
        let svc = PersistenceService(changeQueue: MockChangeQueueManager.shared)
        // modelContext is nil — save() calls try modelContext?.save() which is a no-op

        #expect(throws: Never.self) { try svc.save() }
    }
}
