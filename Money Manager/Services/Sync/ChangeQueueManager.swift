//
//  ChangeQueueManager.swift
//  Money Manager
//

import Foundation
import SwiftData

@MainActor
final class ChangeQueueManager: ChangeQueueManagerProtocol {
    static let shared = ChangeQueueManager()

    private var apiClient: any APIClientProtocol
    private var modelContainer: ModelContainer?
    private var isReplaying = false
    let retryScheduler: RetryScheduler

    static var maxRetryCount: Int { shared.retryScheduler.maxRetryCount }

    init(apiClient: any APIClientProtocol = AppAPIClient.shared, retryScheduler: RetryScheduler = RetryScheduler()) {
        self.apiClient = apiClient
        self.retryScheduler = retryScheduler
    }

    func configure(container: ModelContainer) {
        self.modelContainer = container
    }

    // MARK: - Counts

    var pendingCount: Int { countRecords(status: .pending) }
    var failedCount: Int { countRecords(status: .failed) }

    private func countRecords(status: ChangeStatus) -> Int {
        guard let container = modelContainer else { return 0 }
        let context = ModelContext(container)
        let raw = status.rawValue
        let descriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { $0.statusRaw == raw }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Typed fetch helpers

    /// Returns all pending changes for the given entity (in createdAt order).
    func pendingChanges(forEntity entityType: EntityType, entityID: UUID) -> [ChangeRecord] {
        fetch(status: .pending, entityType: entityType, entityID: entityID)
    }

    /// Returns all pending changes for the given entity type, regardless of entityID.
    func pendingChanges(forEntity entityType: EntityType) -> [ChangeRecord] {
        fetch(status: .pending, entityType: entityType)
    }

    /// Returns all failed changes for the given entity type.
    func failedChanges(forEntity entityType: EntityType) -> [ChangeRecord] {
        fetch(status: .failed, entityType: entityType)
    }

    /// Returns all orphaned changes for the given entity type.
    func orphanedChanges(forEntity entityType: EntityType) -> [ChangeRecord] {
        fetch(status: .orphaned, entityType: entityType)
    }

    private func fetch(status: ChangeStatus, entityType: EntityType, entityID: UUID? = nil) -> [ChangeRecord] {
        guard let container = modelContainer else { return [] }
        let context = ModelContext(container)
        return fetch(status: status, entityType: entityType, entityID: entityID, context: context)
    }

    private func fetch(status: ChangeStatus, entityType: EntityType, entityID: UUID? = nil, context: ModelContext) -> [ChangeRecord] {
        let statusRaw = status.rawValue
        let typeRaw = entityType.rawValue
        let descriptor: FetchDescriptor<ChangeRecord>
        if let entityID {
            descriptor = FetchDescriptor<ChangeRecord>(
                predicate: #Predicate { $0.statusRaw == statusRaw && $0.entityType == typeRaw && $0.entityID == entityID },
                sortBy: [SortDescriptor(\.createdAt)]
            )
        } else {
            descriptor = FetchDescriptor<ChangeRecord>(
                predicate: #Predicate { $0.statusRaw == statusRaw && $0.entityType == typeRaw },
                sortBy: [SortDescriptor(\.createdAt)]
            )
        }
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Enqueue

    func enqueue(_ draft: PendingChangeDraft, context: ModelContext) {
        let existing = pendingChanges(
            forEntity: draft.entityType,
            entityID: draft.entityID,
            context: context
        )

        if let existing = existing.first {
            switch (existing.action, draft.action.rawValue) {
            case ("create", "update"):
                existing.payload = draft.payload
                existing.retryCount = 0
            case ("create", "delete"):
                context.delete(existing)
            case ("update", "update"):
                existing.payload = draft.payload
                existing.retryCount = 0
            case ("update", "delete"):
                existing.action = "delete"
                existing.endpoint = draft.endpoint
                existing.httpMethod = draft.httpMethod.rawValue
                existing.payload = nil
                existing.retryCount = 0
            default:
                context.insert(makeRecord(from: draft))
            }
        } else {
            context.insert(makeRecord(from: draft))
        }

        try? context.save()
    }

    private func makeRecord(from draft: PendingChangeDraft) -> ChangeRecord {
        ChangeRecord(
            entityType: draft.entityType,
            entityID: draft.entityID,
            action: draft.action,
            endpoint: draft.endpoint,
            httpMethod: draft.httpMethod,
            payload: draft.payload
        )
    }

    /// Context-bound version of the pending fetch helper, used during enqueue when we
    /// already have an open ModelContext (avoids spawning a second context).
    private func pendingChanges(forEntity entityType: EntityType, entityID: UUID, context: ModelContext) -> [ChangeRecord] {
        fetch(status: .pending, entityType: entityType, entityID: entityID, context: context)
    }

    // MARK: - Replay

    func replayAll(context: ModelContext, isAuthenticated: Bool) async {
        guard isAuthenticated else { return }
        guard !isReplaying else {
            AppLogger.sync.info("replayAll: already in progress — skipping concurrent call")
            return
        }
        isReplaying = true
        defer { isReplaying = false }

        purgeExpiredFailedChanges(context: context)

        let pendingRaw = ChangeStatus.pending.rawValue
        let pendingDescriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { $0.statusRaw == pendingRaw },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let changes = try? context.fetch(pendingDescriptor) else { return }
        let now = Date()

        for change in changes {
            // Skip items still in their backoff window
            if let nextRetry = change.nextRetryAt, nextRetry > now {
                continue
            }

            // Items that already hit the limit get moved to the dead letter queue
            if change.retryCount >= retryScheduler.maxRetryCount {
                moveToDeadLetter(change, lastError: "Exceeded max retry count (\(retryScheduler.maxRetryCount))", context: context)
                continue
            }

            do {
                try await replayChange(change, context: context)
            } catch {
                guard let apiError = error as? APIError else {
                    retryOrDeadLetter(change, error: error.localizedDescription, context: context)
                    continue
                }

                AppLogger.sync.warning("[ReplayDebug] \(apiError) for \(change.entityType)=\(change.entityID) action=\(change.action)")
                let action = ChangeAction(rawValue: change.action) ?? .update
                let entityType = EntityType(rawValue: change.entityType) ?? .transaction
                switch ReplayErrorPolicy.decide(action: action, entityType: entityType, error: apiError) {
                case .sessionExpired:
                    NotificationCenter.default.post(name: .authSessionExpired, object: nil)
                    return
                case .orphanAll:
                    orphanAll(context: context)
                    NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
                    return
                case .stop:
                    return
                case .discardChange:
                    discardChange(change, context: context)
                case .discardChangeAndEntity:
                    discardChangeAndEntity(change, context: context)
                case .deadLetter(let reason):
                    moveToDeadLetter(change, lastError: reason, context: context)
                case .retryLater(let reason):
                    retryOrDeadLetter(change, error: reason, context: context)
                }
            }
        }
    }

    /// Removes the pending change and saves. Use when the server conflict is resolved
    /// without touching the local entity (e.g. STALE_WRITE, duplicate create).
    private func discardChange(_ change: ChangeRecord, context: ModelContext) {
        context.delete(change)
        try? context.save()
    }

    /// Removes both the local entity and the pending change. Use when the local row
    /// is stale or invalid and should be replaced by the next server pull
    /// (e.g. OVERRIDE_ALREADY_EXISTS, PREDEFINED_NOT_FOUND, 404 on delete).
    private func discardChangeAndEntity(_ change: ChangeRecord, context: ModelContext) {
        hardDeleteEntity(entityType: change.entityType, entityID: change.entityID, context: context)
        context.delete(change)
        try? context.save()
    }

    /// Increments retry count and schedules backoff, or dead-letters if the limit is reached.
    private func retryOrDeadLetter(_ change: ChangeRecord, error: String, context: ModelContext) {
        change.retryCount += 1
        AppLogger.sync.warning("replayAll: retry \(change.retryCount)/\(self.retryScheduler.maxRetryCount) for entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action) error=\(error)")
        if let nextRetry = retryScheduler.nextRetryDate(after: change.retryCount) {
            change.scheduleRetry(at: nextRetry)
            try? context.save()
        } else {
            AppLogger.sync.error("replayAll: dead-lettering entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action) after \(change.retryCount) retries — final error: \(error)")
            moveToDeadLetter(change, lastError: error, context: context)
        }
    }

    private func purgeExpiredFailedChanges(context: ModelContext) {
        let ttl: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        let cutoff = Date(timeIntervalSinceNow: -ttl)
        let failedRaw = ChangeStatus.failed.rawValue
        let distantFuture = Date.distantFuture
        let descriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { record in
                record.statusRaw == failedRaw && record.failedAt != nil && (record.failedAt ?? distantFuture) < cutoff
            }
        )
        guard let expired = try? context.fetch(descriptor), !expired.isEmpty else { return }
        AppLogger.sync.info("Purging \(expired.count) failed ChangeRecord rows older than 30 days")
        expired.forEach { context.delete($0) }
        try? context.save()
    }

    /// Promotes a pending record to the dead-letter (failed) queue with a single mutation.
    private func moveToDeadLetter(_ change: ChangeRecord, lastError: String, context: ModelContext) {
        change.fail(reason: lastError)
        try? context.save()
    }

    private func replayChange(_ change: ChangeRecord, context: ModelContext) async throws {
        let endpoint: String
        switch change.action {
        case "create":
            endpoint = change.endpoint
        case "update", "delete":
            endpoint = "\(change.endpoint)/\(change.entityID)"
        default:
            return
        }

        AppLogger.sync.debug("[ReplayDebug] replayChange: entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action) method=\(change.httpMethod) endpoint=\(endpoint)")
        if let p = change.payload, let s = String(data: p, encoding: .utf8) { AppLogger.sync.debug("[ReplayDebug] payload: \(s)") }
        switch change.httpMethod {
        case "POST":
            guard let payload = change.payload else { return }
            if change.entityType == "category" {
                // Decode the response so we can fix up the local row's ID when the
                // server assigns a deterministic virtual UUID (predefined override).
                let created: APICategory = try await apiClient.post(.raw(endpoint), rawBody: payload)
                applyCreatedCategory(created, localID: change.entityID, context: context)
            } else {
                let _: EmptyResponse = try await apiClient.post(.raw(endpoint), rawBody: payload)
            }
        case "PUT":
            guard let payload = change.payload else { return }
            let _: EmptyResponse = try await apiClient.put(.raw(endpoint), rawBody: payload)
        case "PATCH":
            guard let payload = change.payload else { return }
            let _: EmptyResponse = try await apiClient.patch(.raw(endpoint), rawBody: payload)
        case "DELETE":
            let _: APIMessageResponse = try await apiClient.deleteMessage(.raw(endpoint))
        default:
            AppLogger.sync.warning("[ReplayDebug] unhandled httpMethod=\(change.httpMethod) for entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action)")
            return
        }

        AppLogger.sync.debug("[ReplayDebug] replayChange succeeded: entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action)")

        if change.action == "delete" {
            hardDeleteEntity(entityType: change.entityType, entityID: change.entityID, context: context)
        }
        context.delete(change)
        try? context.save()
    }

    /// Updates the local Category row to match what the server actually stored.
    /// Critical for predefined overrides where the server assigns a deterministic
    /// virtual UUID that differs from the local UUID we created optimistically.
    private func applyCreatedCategory(_ api: APICategory, localID: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.id == localID }
        )
        guard let rows = try? context.fetch(descriptor), let local = rows.first else {
            AppLogger.sync.warning("[applyCreatedCategory] local Category row \(localID) not found — skipping ID fix-up")
            return
        }
        if local.id != api.id {
            AppLogger.sync.debug("[applyCreatedCategory] fixing local id \(local.id) → server id \(api.id) for key=\(api.key)")
            local.id = api.id
        }
        local.applyRemote(api)
        try? context.save()
    }

    /// Hard-deletes the local SwiftData record after a successful backend DELETE,
    /// or when a stale local row needs to be removed (e.g. OVERRIDE_ALREADY_EXISTS).
    private func hardDeleteEntity(entityType: String, entityID: UUID, context: ModelContext) {
        switch entityType {
        case "recurring":
            let descriptor = FetchDescriptor<RecurringTransaction>(
                predicate: #Predicate { $0.id == entityID }
            )
            if let record = try? context.fetch(descriptor), let item = record.first {
                context.delete(item)
            }
        case "transaction":
            let descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.id == entityID }
            )
            if let record = try? context.fetch(descriptor), let item = record.first {
                context.delete(item)
            }
        case "category":
            let descriptor = FetchDescriptor<Category>(
                predicate: #Predicate { $0.id == entityID }
            )
            if let record = try? context.fetch(descriptor), let item = record.first {
                context.delete(item)
            }
        default:
            break
        }
    }

    func clearAll(context: ModelContext) {
        let pendingRaw = ChangeStatus.pending.rawValue
        let descriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { $0.statusRaw == pendingRaw }
        )
        if let changes = try? context.fetch(descriptor) {
            for change in changes {
                context.delete(change)
            }
            try? context.save()
        }
    }

    func orphanAll(context: ModelContext) {
        let pendingRaw = ChangeStatus.pending.rawValue
        let descriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { $0.statusRaw == pendingRaw }
        )
        guard let changes = try? context.fetch(descriptor), !changes.isEmpty else { return }

        for change in changes {
            change.orphan()
        }
        try? context.save()
    }

    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: EntityType, context: ModelContext) {
        guard !entityIDs.isEmpty else { return }
        let pendingRaw = ChangeStatus.pending.rawValue
        let typeRaw = entityType.rawValue
        let descriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { $0.statusRaw == pendingRaw && $0.entityType == typeRaw }
        )
        guard let changes = try? context.fetch(descriptor) else { return }
        var removed = 0
        for change in changes where entityIDs.contains(change.entityID) {
            AppLogger.sync.warning("Conflict: server wins for \(entityType.rawValue)=\(change.entityID) — removing stale pending change")
            context.delete(change)
            removed += 1
        }
        if removed > 0 { try? context.save() }
    }

    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext) {
        let cutoff = Date(timeIntervalSinceNow: -Double(days) * 86400)
        let orphanedRaw = ChangeStatus.orphaned.rawValue
        let distantFuture = Date.distantFuture
        let descriptor = FetchDescriptor<ChangeRecord>(
            predicate: #Predicate { record in
                record.statusRaw == orphanedRaw && record.orphanedAt != nil && (record.orphanedAt ?? distantFuture) < cutoff
            }
        )
        guard let expired = try? context.fetch(descriptor), !expired.isEmpty else { return }
        for orphan in expired {
            context.delete(orphan)
        }
        try? context.save()
    }
}
