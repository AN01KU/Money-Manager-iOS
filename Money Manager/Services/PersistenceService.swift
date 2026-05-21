//
//  PersistenceService.swift
//  Money Manager
//

import Foundation
import SwiftData

@MainActor
final class PersistenceService {

    let modelContext: ModelContext
    private let changeQueue: ChangeQueueManagerProtocol
    private let authService: AuthServiceProtocol
    private let networkMonitor: any NetworkMonitorProtocol

    init(
        modelContext: ModelContext,
        authService: AuthServiceProtocol,
        networkMonitor: any NetworkMonitorProtocol,
        changeQueue: ChangeQueueManagerProtocol
    ) {
        self.modelContext = modelContext
        self.authService = authService
        self.networkMonitor = networkMonitor
        self.changeQueue = changeQueue
    }

    // MARK: - Save + Sync

    func saveAndSync(
        entityType: EntityType,
        entityID: UUID,
        action: ChangeAction,
        endpoint: String,
        httpMethod: HTTPMethod,
        payload: Data?
    ) throws {
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

        if networkMonitor.isConnected {
            Task {
                await changeQueue.replayAll(context: modelContext, isAuthenticated: authService.isAuthenticated)
            }
        }
    }

    // MARK: - Entity-specific helpers

    func saveTransaction(_ transaction: Transaction, action: ChangeAction) throws {
        let httpMethod: HTTPMethod
        let payload: Data?

        switch action {
        case .create:
            httpMethod = .post
            payload = try? AppAPIClient.apiEncoder.encode(transaction.toCreateRequest())
        case .update:
            httpMethod = .patch
            payload = try? AppAPIClient.apiEncoder.encode(transaction.toUpdateRequest())
        case .delete:
            httpMethod = .delete
            payload = nil
        }

        try saveAndSync(
            entityType: .transaction,
            entityID: transaction.id,
            action: action,
            endpoint: "/transactions",
            httpMethod: httpMethod,
            payload: payload
        )
    }

    func saveRecurring(_ recurring: RecurringTransaction, action: ChangeAction) throws {
        let httpMethod: HTTPMethod
        let payload: Data?

        switch action {
        case .create:
            httpMethod = .post
            payload = try? AppAPIClient.apiEncoder.encode(recurring.toCreateRequest())
        case .update:
            httpMethod = .patch
            payload = try? AppAPIClient.apiEncoder.encode(recurring.toUpdateRequest())
        case .delete:
            httpMethod = .delete
            payload = nil
        }

        try saveAndSync(
            entityType: .recurring,
            entityID: recurring.id,
            action: action,
            endpoint: "/recurring-transactions",
            httpMethod: httpMethod,
            payload: payload
        )
    }

    func saveCategory(_ category: Category, action: ChangeAction) throws {
        let httpMethod: HTTPMethod
        let payload: Data?

        switch action {
        case .create:
            httpMethod = .post
            payload = try? AppAPIClient.apiEncoder.encode(category.toCreateRequest())
        case .update:
            httpMethod = .patch
            payload = try? AppAPIClient.apiEncoder.encode(category.toUpdateRequest())
        case .delete:
            httpMethod = .delete
            payload = nil
        }

        try saveAndSync(
            entityType: .category,
            entityID: category.id,
            action: action,
            endpoint: "/categories",
            httpMethod: httpMethod,
            payload: payload
        )
    }

    // MARK: - Generic save<T>

    /// Saves any LocalSyncableEntity and enqueues the corresponding change record.
    /// Old entity-specific save methods coexist; call sites migrate in subsequent issues.
    func save<T: LocalSyncableEntity & PersistentModel>(_ entity: T, action: ChangeAction) throws {
        let httpMethod: HTTPMethod
        let payload: Data?

        switch action {
        case .create:
            httpMethod = .post
            payload = try? entity.createRequestPayload()
        case .update:
            httpMethod = .patch
            payload = try? entity.updateRequestPayload()
        case .delete:
            httpMethod = .delete
            payload = nil
        }

        try saveAndSync(
            entityType: T.entityType,
            entityID: entity.id,
            action: action,
            endpoint: T.endpoint,
            httpMethod: httpMethod,
            payload: payload
        )
    }

    func save() throws {
        try modelContext.save()
    }

    // MARK: - Enqueue-only helpers (no modelContext.save — caller already inserted the entity)

    /// Encodes and enqueues a create change without triggering a replay.
    /// Used by bootstrap to batch-enqueue all local data before a single replayAll.
    func enqueueCreate(_ transaction: Transaction, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(transaction.toCreateRequest()) else { return }
        changeQueue.enqueue(
            entityType: .transaction, entityID: transaction.id, action: .create,
            endpoint: "/transactions", httpMethod: .post, payload: payload, context: context
        )
    }

    func enqueueCreate(_ recurring: RecurringTransaction, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(recurring.toCreateRequest()) else { return }
        changeQueue.enqueue(
            entityType: .recurring, entityID: recurring.id, action: .create,
            endpoint: "/recurring-transactions", httpMethod: .post, payload: payload, context: context
        )
    }

    func enqueueUserBudget(_ budget: UserBudget, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(APISetBudgetRequest(limit: budget.limit)) else { return }
        changeQueue.enqueue(
            entityType: .budget, entityID: budget.id, action: .create,
            endpoint: "/me/budget", httpMethod: .put, payload: payload, context: context
        )
    }

    func enqueueCreate(_ category: Category, context: ModelContext) {
        guard let payload = try? AppAPIClient.apiEncoder.encode(category.toCreateRequest()) else { return }
        changeQueue.enqueue(
            entityType: .category, entityID: category.id, action: .create,
            endpoint: "/categories", httpMethod: .post, payload: payload, context: context
        )
    }

    /// Enqueues a DELETE for a category row that has already been removed from the context.
    func deleteCategory(id: UUID) throws {
        try saveAndSync(
            entityType: .category, entityID: id, action: .delete,
            endpoint: "/categories", httpMethod: .delete, payload: nil
        )
    }
}

// MARK: - Debug/Preview helpers

#if DEBUG
extension PersistenceService {
    /// A shared in-memory PersistenceService for use in SwiftUI previews, tests,
    /// and VM default-argument values. Never used in production builds.
    @MainActor static let testing: PersistenceService = {
        let schema = Schema([
            Transaction.self, RecurringTransaction.self, MonthlyBudget.self, UserBudget.self, Category.self,
            PendingChange.self, FailedChange.self, OrphanedChange.self,
            SplitGroupModel.self, GroupMemberModel.self, GroupTransactionModel.self, GroupBalanceModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return PersistenceService(
            modelContext: container.mainContext,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
    }()
}
#endif
