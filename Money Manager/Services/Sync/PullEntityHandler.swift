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

        let serverWonIDs = upsert(remote, locals: locals, context: context)
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
        context: ModelContext
    ) -> Set<UUID> {
        let localByID = Dictionary(uniqueKeysWithValues: locals.map { ($0.id, $0) })
        var serverWonIDs = Set<UUID>()

        for remote in remoteItems {
            guard isValid(remote) else { continue }
            if let local = localByID[remote.id] {
                if local.isSoftDeleted { continue }
                if remote.updatedAt > local.updatedAt {
                    serverWonIDs.insert(remote.id)
                    local.applyRemote(remote)
                }
            } else {
                let item = RecurringTransaction(
                    id: remote.id,
                    name: remote.name,
                    amount: remote.amount,
                    category: remote.category,
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

        let serverWonIDs = upsert(fetched, locals: locals, context: context)
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
        context: ModelContext
    ) -> Set<UUID> {
        let localByID = Dictionary(uniqueKeysWithValues: locals.map { ($0.id, $0) })
        var serverWonIDs = Set<UUID>()

        for remote in remoteItems {
            guard isValid(remote) else { continue }
            if let local = localByID[remote.id] {
                if local.groupName == nil, let name = remote.groupName { local.groupName = name }
                if local.groupId == nil, let id = remote.groupId { local.groupId = id }
                if remote.updatedAt > local.updatedAt {
                    serverWonIDs.insert(remote.id)
                    local.applyRemote(remote)
                }
            } else {
                let tx = Transaction(
                    id: remote.id,
                    type: remote.type,
                    amount: remote.amount,
                    category: remote.category,
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
            AppLogger.sync.info("Purging server-owned transaction not returned by server: id=\(local.id) amount=\(local.amount) category=\(local.category) date=\(local.date) recurringId=\(local.recurringExpenseId?.uuidString ?? "nil") settlementId=\(local.settlementId?.uuidString ?? "nil") groupTxId=\(local.groupTransactionId?.uuidString ?? "nil")")
            context.delete(local)
        }
    }
}
