//
//  PullEntityHandler.swift
//  Money Manager
//

import Foundation
import SwiftData

// MARK: - Base Protocol

/// Encapsulates the pull-from-server logic for one entity type.
///
/// `SyncService` holds `[any PullEntityHandler]` and calls each in sequence.
/// The pipeline owns the try/catch: success → `syncCheckpoint`, throw → `recordSyncError`.
protocol PullEntityHandler {
    /// Entity label used for sync-checkpoint logging.
    var entityLabel: String { get }

    /// Fetch remote data and upsert into the local store.
    ///
    /// Throws on network / decoding error. Saving the context is the handler's responsibility.
    func pull(
        api: any APIClientProtocol,
        changeQueue: any ChangeQueueManagerProtocol,
        context: ModelContext
    ) async throws

    /// Number of items in the latest server response (populated after `pull`).
    var lastServerCount: Int { get }
    /// Number of matching local rows before upsert (populated after `pull`).
    var lastLocalCount: Int { get }
}

// MARK: - CollectionPullHandler

/// Marker for entity-collection handlers that support server-authoritative purge.
///
/// Conformers guard purge with pending/failed-queue checks so locally queued
/// creates are not wiped when absent from the server response.
protocol CollectionPullHandler: PullEntityHandler {}

// MARK: - SingletonPullHandler

/// Marker for singleton-entity handlers (e.g. UserBudget) — no purge step.
protocol SingletonPullHandler: PullEntityHandler {}

// MARK: - RecurringTransactionPullHandler

/// Pulls recurring transactions from the server and upserts them locally.
///
/// Replaces `SyncService.upsertRecurring`. Purges local rows absent from the server
/// response unless they have a pending/failed change queued.
final class RecurringTransactionPullHandler: CollectionPullHandler {
    let entityLabel = "recurring"

    private(set) var lastServerCount = 0
    private(set) var lastLocalCount = 0

    func pull(
        api: any APIClientProtocol,
        changeQueue: any ChangeQueueManagerProtocol,
        context: ModelContext
    ) async throws {
        let response: APIListResponse<APIRecurringTransaction> = try await api.get(.syncRecurring)
        let remote = response.data
        lastServerCount = remote.count

        let locals = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        lastLocalCount = locals.count

        let allCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let (keyToUUID, otherUUID) = CategorySyncHelpers.makeKeyToUUID(from: allCategories)
        let resolvedOtherUUID = otherUUID ?? UUID()

        let serverWonIDs = upsert(remote, locals: locals, keyToUUID: keyToUUID, otherUUID: resolvedOtherUUID, context: context)
        changeQueue.removeStaleChanges(for: serverWonIDs, entityType: .recurring, context: context)
        purge(remote, locals: locals, context: context)

        try? context.save()
    }

    // MARK: - Private

    private func isValid(_ api: APIRecurringTransaction) -> Bool {
        guard !api.category.trimmingCharacters(in: .whitespaces).isEmpty else {
            AppLogger.sync.error("Validation failed: recurring \(api.id) has empty category")
            return false
        }
        return true
    }

    private func upsert(
        _ remoteItems: [APIRecurringTransaction],
        locals: [RecurringTransaction],
        keyToUUID: [String: UUID],
        otherUUID: UUID,
        context: ModelContext
    ) -> Set<UUID> {
        let localByID = Dictionary(uniqueKeysWithValues: locals.map { ($0.id, $0) })
        var serverWonIDs = Set<UUID>()

        for remote in remoteItems {
            guard isValid(remote) else { continue }
            let categoryId = CategorySyncHelpers.resolveKey(remote.category, keyToUUID: keyToUUID, otherUUID: otherUUID)
            if let local = localByID[remote.id] {
                if local.isSoftDeleted { continue }
                if remote.updatedAt > local.updatedAt {
                    serverWonIDs.insert(remote.id)
                    local.applyRemote(remote, keyToUUID: keyToUUID, otherUUID: otherUUID)
                }
            } else {
                let item = RecurringTransaction(
                    id: remote.id,
                    name: remote.name,
                    amount: remote.amount,
                    categoryId: categoryId,
                    frequency: RecurringFrequency(rawValue: remote.frequency) ?? .monthly,
                    dayOfMonth: remote.dayOfMonth,
                    daysOfWeek: remote.daysOfWeek,
                    startDate: remote.startDate,
                    endDate: remote.endDate,
                    isActive: remote.isActive,
                    lastAddedDate: remote.lastAddedDate,
                    notes: remote.notes,
                    type: remote.type ?? .expense
                )
                context.insert(item)
            }
        }
        return serverWonIDs
    }

    private func purge(
        _ remoteItems: [APIRecurringTransaction],
        locals: [RecurringTransaction],
        context: ModelContext
    ) {
        let failedIDs = Set(
            (try? context.fetch(FetchDescriptor<FailedChange>(
                predicate: #Predicate { $0.entityType == "recurring" }
            )))?.map { $0.entityID } ?? []
        )
        let pendingIDs = Set(
            (try? context.fetch(FetchDescriptor<PendingChange>(
                predicate: #Predicate { $0.entityType == "recurring" }
            )))?.map { $0.entityID } ?? []
        )
        let serverIDs = Set(remoteItems.map { $0.id })

        for local in locals {
            guard !serverIDs.contains(local.id) else { continue }
            guard !pendingIDs.contains(local.id) else { continue }
            guard !failedIDs.contains(local.id) else { continue }
            AppLogger.sync.info("Purging recurring not on server: id=\(local.id) name=\(local.name)")
            context.delete(local)
        }
    }
}

// MARK: - TransactionPullHandler

/// Pulls personal transactions from the server and upserts them locally.
///
/// Replaces `SyncService.upsertTransactions`. Purges server-owned local rows
/// that are absent from the server response and have no pending/failed change.
final class TransactionPullHandler: CollectionPullHandler {
    let entityLabel = "transaction"

    private(set) var lastServerCount = 0
    private(set) var lastLocalCount = 0

    private var fetched: [APITransaction] = []

    func pull(
        api: any APIClientProtocol,
        changeQueue: any ChangeQueueManagerProtocol,
        context: ModelContext
    ) async throws {
        fetched = try await fetchAll(api: api)
        lastServerCount = fetched.count

        let locals = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        lastLocalCount = locals.count

        let allCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let (keyToUUID, otherUUID) = CategorySyncHelpers.makeKeyToUUID(from: allCategories)
        let resolvedOtherUUID = otherUUID ?? UUID()

        let serverWonIDs = upsert(fetched, locals: locals, keyToUUID: keyToUUID, otherUUID: resolvedOtherUUID, context: context)
        changeQueue.removeStaleChanges(for: serverWonIDs, entityType: .transaction, context: context)
        purge(fetched, locals: locals, context: context)

        try? context.save()
    }

    // MARK: - Private

    private func fetchAll(api: any APIClientProtocol) async throws -> [APITransaction] {
        var all: [APITransaction] = []
        var offset = 0
        let limit = 100
        while true {
            let page: APIPaginatedResponse<APITransaction> = try await api.get(.syncTransactions(limit: limit, offset: offset))
            all.append(contentsOf: page.data)
            AppLogger.sync.info("pullTransactions: page offset=\(offset) returned=\(page.data.count) total=\(page.pagination.total)")
            if page.data.count < limit || offset + page.data.count >= page.pagination.total { break }
            offset += limit
        }
        AppLogger.sync.info("pullTransactions: fetched \(all.count) transactions from server")
        return all
    }

    private func isValid(_ api: APITransaction) -> Bool {
        guard !api.category.trimmingCharacters(in: .whitespaces).isEmpty else {
            AppLogger.sync.error("Validation failed: transaction \(api.id) has empty category")
            return false
        }
        return true
    }

    private func upsert(
        _ remoteItems: [APITransaction],
        locals: [Transaction],
        keyToUUID: [String: UUID],
        otherUUID: UUID,
        context: ModelContext
    ) -> Set<UUID> {
        let localByID = Dictionary(uniqueKeysWithValues: locals.map { ($0.id, $0) })
        var serverWonIDs = Set<UUID>()

        for remote in remoteItems {
            guard isValid(remote) else { continue }
            let categoryId = CategorySyncHelpers.resolveKey(remote.category, keyToUUID: keyToUUID, otherUUID: otherUUID)
            if let local = localByID[remote.id] {
                if local.groupName == nil, let name = remote.groupName { local.groupName = name }
                if local.groupId == nil, let id = remote.groupId { local.groupId = id }
                if remote.updatedAt > local.updatedAt {
                    serverWonIDs.insert(remote.id)
                    local.applyRemote(remote, keyToUUID: keyToUUID, otherUUID: otherUUID)
                }
            } else {
                let tx = Transaction(
                    id: remote.id,
                    type: remote.type,
                    amount: remote.amount,
                    categoryId: categoryId,
                    date: remote.date,
                    time: remote.time,
                    transactionDescription: remote.description,
                    notes: remote.notes,
                    recurringExpenseId: remote.recurringExpenseId,
                    groupTransactionId: remote.groupTransactionId,
                    settlementId: remote.settlementId
                )
                tx.groupId = remote.groupId
                tx.groupName = remote.groupName
                context.insert(tx)
            }
        }
        return serverWonIDs
    }

    private func purge(
        _ remoteItems: [APITransaction],
        locals: [Transaction],
        context: ModelContext
    ) {
        let failedIDs = Set(
            (try? context.fetch(FetchDescriptor<FailedChange>(
                predicate: #Predicate { $0.entityType == "transaction" }
            )))?.map { $0.entityID } ?? []
        )
        let pendingIDs = Set(
            (try? context.fetch(FetchDescriptor<PendingChange>(
                predicate: #Predicate { $0.entityType == "transaction" }
            )))?.map { $0.entityID } ?? []
        )
        let serverIDs = Set(remoteItems.map { $0.id })

        for local in locals {
            guard !serverIDs.contains(local.id) else { continue }
            guard !pendingIDs.contains(local.id) else { continue }
            guard !failedIDs.contains(local.id) else { continue }
            let isServerOwned = local.settlementId != nil
                || local.groupTransactionId != nil
                || local.recurringExpenseId != nil
            guard isServerOwned else { continue }
            AppLogger.sync.info("Purging server-owned transaction not returned by server: id=\(local.id) amount=\(local.amount) date=\(local.date) recurringId=\(local.recurringExpenseId?.uuidString ?? "nil") settlementId=\(local.settlementId?.uuidString ?? "nil") groupTxId=\(local.groupTransactionId?.uuidString ?? "nil")")
            context.delete(local)
        }
    }
}

// MARK: - PredefinedCategoryPullHandler

/// Pulls server-seeded predefined categories and upserts them locally.
///
/// Replaces `SyncService.pullPredefinedCategories` + `bootstrapPredefinedCategories` +
/// `upsertPredefinedCategories`. No purge of user-owned rows; only removes
/// server-predefined rows that the admin has permanently deleted.
final class PredefinedCategoryPullHandler: SingletonPullHandler {
    let entityLabel = "predefined-category"

    private(set) var lastServerCount = 0
    private(set) var lastLocalCount = 0

    func pull(
        api: any APIClientProtocol,
        changeQueue: any ChangeQueueManagerProtocol,
        context: ModelContext
    ) async throws {
        let response: APIListResponse<APIPredefinedCategory> = try await api.get(.predefinedCategories)
        let remote = response.data
        lastServerCount = remote.count

        let allLocals = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let predefinedLocals = allLocals.filter { $0.isServerPredefined }
        lastLocalCount = predefinedLocals.count

        upsert(remote, locals: allLocals, context: context)

        try? context.save()
    }

    // MARK: - Private

    private func upsert(
        _ remoteItems: [APIPredefinedCategory],
        locals: [Category],
        context: ModelContext
    ) {
        // Build lookup by key, deduplicating stale rows
        var localByKey = [String: Category]()
        for cat in locals where cat.isServerPredefined && !cat.key.isEmpty {
            if let existing = localByKey[cat.key] {
                AppLogger.sync.warning("[PredefinedCategoryPullHandler] duplicate row for key=\(cat.key), purging older")
                context.delete(existing.updatedAt < cat.updatedAt ? existing : cat)
                localByKey[cat.key] = existing.updatedAt >= cat.updatedAt ? existing : cat
            } else {
                localByKey[cat.key] = cat
            }
        }

        let serverKeys = Set(remoteItems.map { $0.key })

        for remote in remoteItems {
            let paletteHex = PredefinedCategory.allCases
                .first { $0.serverKey == remote.key }?.paletteHex ?? remote.color
            if let local = localByKey[remote.key] {
                let remoteUpdatedAt = remote.updatedAt ?? local.updatedAt
                if remoteUpdatedAt > local.updatedAt {
                    local.name = remote.name
                    local.icon = remote.icon
                    local.isHidden = remote.isHidden ?? false
                    local.updatedAt = remoteUpdatedAt
                }
                local.color = paletteHex
            } else {
                let category = Category(
                    id: remote.id,
                    key: remote.key,
                    name: remote.name,
                    icon: remote.icon,
                    color: paletteHex,
                    isPredefined: true,
                    isServerPredefined: true
                )
                category.isHidden = remote.isHidden ?? false
                category.updatedAt = remote.updatedAt ?? Date()
                context.insert(category)
            }
        }

        // Remove rows the admin permanently deleted
        for local in locals where local.isServerPredefined {
            if !serverKeys.contains(local.key) {
                context.delete(local)
            }
        }
    }
}

// MARK: - UserBudgetPullHandler

/// Pulls the per-user budget limit from the server and upserts it locally.
///
/// Replaces `SyncService.pullBudgets` + `upsertUserBudget`. Skips the server
/// value when a pending budget change is queued (LWW-safe offline path).
final class UserBudgetPullHandler: SingletonPullHandler {
    let entityLabel = "budget"

    private(set) var lastServerCount = 0
    private(set) var lastLocalCount = 0

    func pull(
        api: any APIClientProtocol,
        changeQueue: any ChangeQueueManagerProtocol,
        context: ModelContext
    ) async throws {
        let remote: APIUserBudget = try await api.get(.getBudget)
        lastServerCount = 1

        let locals = (try? context.fetch(FetchDescriptor<UserBudget>())) ?? []
        lastLocalCount = locals.count

        let hasPending = (try? context.fetch(
            FetchDescriptor<PendingChange>(predicate: #Predicate { $0.entityType == "budget" })
        ))?.isEmpty == false

        if hasPending {
            AppLogger.sync.debug("[UserBudgetPullHandler] pending budget change queued — skipping server overwrite")
            return
        }

        if let local = locals.first {
            local.limit = remote.limit
        } else {
            context.insert(UserBudget(limit: remote.limit))
        }

        changeQueue.removeStaleChanges(for: [UserBudget.sentinelID], entityType: .budget, context: context)
        try? context.save()
        AppLogger.sync.debug("[UserBudgetPullHandler] limit=\(remote.limit.map { "\($0)" } ?? "nil")")
    }
}

// MARK: - CategoryPullHandler

/// Pulls user-owned categories from the server and upserts them locally.
///
/// Replaces `SyncService.upsertCategories`. Purges local custom categories absent
/// from the server response unless they have a pending change queued.
/// Never touches server-predefined rows (those are managed separately).
final class CategoryPullHandler: CollectionPullHandler {
    let entityLabel = "category"

    private(set) var lastServerCount = 0
    private(set) var lastLocalCount = 0

    func pull(
        api: any APIClientProtocol,
        changeQueue: any ChangeQueueManagerProtocol,
        context: ModelContext
    ) async throws {
        let response: APIListResponse<APICategory> = try await api.get(.syncCategories)
        let remote = response.data
        lastServerCount = remote.count

        let locals = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        lastLocalCount = locals.filter { !$0.isServerPredefined }.count

        let serverWonIDs = upsert(remote, locals: locals, context: context)
        changeQueue.removeStaleChanges(for: serverWonIDs, entityType: .category, context: context)
        purge(remote, locals: locals, context: context)

        try? context.save()
    }

    // MARK: - Private

    private func isValid(_ api: APICategory) -> Bool {
        guard !api.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            AppLogger.sync.error("Validation failed: category \(api.id) has empty name")
            return false
        }
        return true
    }

    private func upsert(
        _ remoteItems: [APICategory],
        locals: [Category],
        context: ModelContext
    ) -> Set<UUID> {
        let localByID = Dictionary(uniqueKeysWithValues: locals.map { ($0.id, $0) })
        var localByPredServerKey = [String: Category]()
        for cat in locals where cat.isPredefined && !cat.key.isEmpty {
            localByPredServerKey[cat.key] = cat
        }

        var serverWonIDs = Set<UUID>()

        for remote in remoteItems {
            guard isValid(remote) else { continue }

            let normalizedPredefinedKey = remote.predefinedKey
                .flatMap { PredefinedCategory.normalizeKey($0) }
                ?? remote.predefinedKey

            let remoteIsHidden = remote.isHidden ?? false
            let remoteIsPredefined = remote.isPredefined ?? false

            if let local = localByID[remote.id] {
                if remote.updatedAt > local.updatedAt {
                    serverWonIDs.insert(remote.id)
                    local.key = remote.key
                    local.name = remote.name
                    local.icon = remote.icon
                    local.color = remote.color
                    local.isHidden = remoteIsHidden
                    local.isPredefined = remoteIsPredefined
                    local.predefinedKey = normalizedPredefinedKey
                    local.updatedAt = remote.updatedAt
                }
            } else if remoteIsPredefined, let local = localByPredServerKey[remote.key] {
                serverWonIDs.insert(local.id)
                local.id = remote.id
                local.key = remote.key
                local.name = remote.name
                local.icon = remote.icon
                local.color = remote.color
                local.isHidden = remoteIsHidden
                local.isPredefined = remoteIsPredefined
                local.predefinedKey = normalizedPredefinedKey
                local.updatedAt = remote.updatedAt
            } else {
                let category = Category(
                    id: remote.id,
                    key: remote.key,
                    name: remote.name,
                    icon: remote.icon,
                    color: remote.color,
                    isPredefined: remoteIsPredefined,
                    predefinedKey: normalizedPredefinedKey
                )
                category.isHidden = remoteIsHidden
                category.updatedAt = remote.updatedAt
                context.insert(category)
            }
        }
        return serverWonIDs
    }

    private func purge(
        _ remoteItems: [APICategory],
        locals: [Category],
        context: ModelContext
    ) {
        let pendingIDs = Set(
            (try? context.fetch(FetchDescriptor<PendingChange>(
                predicate: #Predicate { $0.entityType == "category" }
            )))?.map { $0.entityID } ?? []
        )
        let serverIDs = Set(remoteItems.map { $0.id })

        for local in locals {
            guard !local.isPredefined, !local.isServerPredefined else { continue }
            guard !serverIDs.contains(local.id) else { continue }
            guard !pendingIDs.contains(local.id) else { continue }
            AppLogger.sync.debug("Purging custom category not on server: \(local.id) name=\(local.name)")
            context.delete(local)
        }
    }
}
