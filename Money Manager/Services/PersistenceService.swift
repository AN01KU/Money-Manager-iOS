//
//  PersistenceService.swift
//  Money Manager
//

import Foundation
import SwiftData

@MainActor
final class PersistenceService {

    var modelContext: ModelContext?
    private let changeQueue: ChangeQueueManagerProtocol

    init(changeQueue: ChangeQueueManagerProtocol = changeQueueManager) {
        self.changeQueue = changeQueue
    }

    // MARK: - Save + Sync

    func saveAndSync(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?
    ) throws {
        guard let modelContext else {
            AppLogger.data.error("saveAndSync: modelContext not set for \(entityType) \(action)")
            return
        }
        try modelContext.save()

        changeQueue.enqueue(
            entityType: entityType,
            entityID: entityID,
            action: action,
            endpoint: endpoint,
            httpMethod: httpMethod,
            payload: payload,
            context: modelContext
        )

        if NetworkMonitor.shared.isConnected {
            Task {
                await changeQueue.replayAll(context: modelContext, isAuthenticated: authService.isAuthenticated)
            }
        }
    }

    // MARK: - Entity-specific helpers

    func saveTransaction(_ transaction: Transaction, action: String) throws {
        let httpMethod: String
        let payload: Data?

        switch action {
        case "create":
            httpMethod = "POST"
            payload = try? AppAPIClient.apiEncoder.encode(transaction.toCreateRequest())
        case "update":
            httpMethod = "PATCH"
            payload = try? AppAPIClient.apiEncoder.encode(transaction.toUpdateRequest())
        case "delete":
            httpMethod = "DELETE"
            payload = nil
        default:
            return
        }

        try saveAndSync(
            entityType: "transaction",
            entityID: transaction.id,
            action: action,
            endpoint: "/transactions",
            httpMethod: httpMethod,
            payload: payload
        )
    }

    func saveRecurring(_ recurring: RecurringTransaction, action: String) throws {
        let httpMethod: String
        let payload: Data?

        switch action {
        case "create":
            httpMethod = "POST"
            payload = try? AppAPIClient.apiEncoder.encode(recurring.toCreateRequest())
        case "update":
            httpMethod = "PATCH"
            payload = try? AppAPIClient.apiEncoder.encode(recurring.toUpdateRequest())
        case "delete":
            httpMethod = "DELETE"
            payload = nil
        default:
            return
        }

        try saveAndSync(
            entityType: "recurring",
            entityID: recurring.id,
            action: action,
            endpoint: "/recurring-transactions",
            httpMethod: httpMethod,
            payload: payload
        )
    }
    
    func saveCategory(_ category: Category, action: String) throws {
        let httpMethod: String
        let payload: Data?

        switch action {
        case "create":
            httpMethod = "POST"
            payload = try? AppAPIClient.apiEncoder.encode(category.toCreateRequest())
        case "update":
            httpMethod = "PATCH"
            payload = try? AppAPIClient.apiEncoder.encode(category.toUpdateRequest())
        case "delete":
            httpMethod = "DELETE"
            payload = nil
        default:
            return
        }

        try saveAndSync(
            entityType: "category",
            entityID: category.id,
            action: action,
            endpoint: "/categories",
            httpMethod: httpMethod,
            payload: payload
        )
    }

    func save() throws {
        try modelContext?.save()
    }

    // MARK: - Enqueue-only helpers (no modelContext.save — caller already inserted the entity)

    /// Encodes and enqueues a create change without triggering a replay.
    /// Used by bootstrap to batch-enqueue all local data before a single replayAll.
    func enqueueCreate(_ transaction: Transaction, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(transaction.toCreateRequest()) else { return }
        changeQueue.enqueue(
            entityType: "transaction", entityID: transaction.id, action: "create",
            endpoint: "/transactions", httpMethod: "POST", payload: payload, context: context
        )
    }

    func enqueueCreate(_ recurring: RecurringTransaction, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(recurring.toCreateRequest()) else { return }
        changeQueue.enqueue(
            entityType: "recurring", entityID: recurring.id, action: "create",
            endpoint: "/recurring-transactions", httpMethod: "POST", payload: payload, context: context
        )
    }

    func enqueueCreate(_ budget: MonthlyBudget, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(budget.toCreateRequest()) else { return }
        changeQueue.enqueue(
            entityType: "budget", entityID: budget.id, action: "create",
            endpoint: "/budgets", httpMethod: "POST", payload: payload, context: context
        )
    }

    func enqueueCreate(_ category: Category, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(category.toCreateRequest()) else { return }
        changeQueue.enqueue(
            entityType: "category", entityID: category.id, action: "create",
            endpoint: "/categories", httpMethod: "POST", payload: payload, context: context
        )
    }

    /// Enqueues a DELETE for a category row that has already been removed from the context.
    func deleteCategory(id: UUID) throws {
        try saveAndSync(
            entityType: "category", entityID: id, action: "delete",
            endpoint: "/categories", httpMethod: "DELETE", payload: nil
        )
    }
}
