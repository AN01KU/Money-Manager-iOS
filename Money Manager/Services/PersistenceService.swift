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
        guard let modelContext else { return }
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
            payload = try? APIClient.apiEncoder.encode(transaction.toCreateRequest())
        case "update":
            httpMethod = "PATCH"
            payload = try? APIClient.apiEncoder.encode(transaction.toUpdateRequest())
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
            payload = try? APIClient.apiEncoder.encode(recurring.toCreateRequest())
        case "update":
            httpMethod = "PUT"
            payload = try? APIClient.apiEncoder.encode(recurring.toUpdateRequest())
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

    func saveCategory(_ category: CustomCategory, action: String) throws {
        let httpMethod: String
        let payload: Data?

        switch action {
        case "create":
            httpMethod = "POST"
            payload = try? APIClient.apiEncoder.encode(category.toCreateRequest())
        case "update":
            httpMethod = "PUT"
            payload = try? APIClient.apiEncoder.encode(category.toUpdateRequest())
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
}
