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

    var pendingCount: Int {
        guard let container = modelContainer else { return 0 }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<PendingChange>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    var failedCount: Int {
        guard let container = modelContainer else { return 0 }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<FailedChange>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    func enqueue(_ draft: PendingChangeDraft, context: ModelContext) {
        let entityTypeRaw = draft.entityType.rawValue
        let entityID = draft.entityID
        let existingDescriptor = FetchDescriptor<PendingChange>(
            predicate: #Predicate { change in
                change.entityID == entityID && change.entityType == entityTypeRaw
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        if let existingChanges = try? context.fetch(existingDescriptor),
           let existing = existingChanges.first {
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
                context.insert(PendingChange(
                    entityType: draft.entityType.rawValue,
                    entityID: draft.entityID,
                    action: draft.action.rawValue,
                    endpoint: draft.endpoint,
                    httpMethod: draft.httpMethod.rawValue,
                    payload: draft.payload
                ))
            }
        } else {
            context.insert(PendingChange(
                entityType: draft.entityType.rawValue,
                entityID: draft.entityID,
                action: draft.action.rawValue,
                endpoint: draft.endpoint,
                httpMethod: draft.httpMethod.rawValue,
                payload: draft.payload
            ))
        }

        try? context.save()
    }

    func replayAll(context: ModelContext, isAuthenticated: Bool) async {
        guard isAuthenticated else { return }
        guard !isReplaying else {
            AppLogger.sync.info("replayAll: already in progress — skipping concurrent call")
            return
        }
        isReplaying = true
        defer { isReplaying = false }

        purgeExpiredFailedChanges(context: context)

        let descriptor = FetchDescriptor<PendingChange>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        guard let changes = try? context.fetch(descriptor) else { return }
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

                switch apiError {
                case .unauthorized:
                    NotificationCenter.default.post(name: .authSessionExpired, object: nil)
                    return

                case .syncSessionInvalid:
                    // Entire session is invalid — orphan the queue and stop.
                    orphanAll(context: context)
                    NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
                    return

                case .transientError:
                    // 502 server blip — leave the change queued, retry on next sync trigger.
                    AppLogger.sync.warning("[ReplayDebug] 502 transient error for \(change.entityType)=\(change.entityID) — backing off, will retry")
                    return

                case .staleWrite:
                    // Server has a newer version — discard our pending write; next pull wins.
                    AppLogger.sync.warning("[ReplayDebug] STALE_WRITE for \(change.entityType)=\(change.entityID) — discarding stale pending change, server version wins")
                    discardChange(change, context: context)

                case .notFound where change.action == "delete":
                    // 404 on a delete — entity never reached the server, clean up locally.
                    AppLogger.sync.warning("[ReplayDebug] 404 on delete for \(change.entityType)=\(change.entityID) — entity never on server, cleaning up locally")
                    discardChangeAndEntity(change, context: context)

                case .notFound where change.action == "update":
                    // 404 on an update — entity was deleted on another device; purge local row.
                    AppLogger.sync.warning("[ReplayDebug] 404 on update for \(change.entityType)=\(change.entityID) — entity gone from server, purging local row")
                    discardChangeAndEntity(change, context: context)

                case .overrideAlreadyExists where change.action == "create" && change.entityType == "category":
                    // Server already has this predefined override — drop stale local row;
                    // next pullCategories will bring down the canonical server version.
                    AppLogger.sync.warning("[ReplayDebug] OVERRIDE_ALREADY_EXISTS for category=\(change.entityID) — deleting stale local row; pullCategories will sync the server override")
                    discardChangeAndEntity(change, context: context)

                case .predefinedNotFound where change.action == "create" && change.entityType == "category":
                    // Predefined category removed by admin — discard local override entirely.
                    AppLogger.sync.warning("[ReplayDebug] PREDEFINED_NOT_FOUND for category=\(change.entityID) — predefined removed by admin, discarding local override")
                    discardChangeAndEntity(change, context: context)

                case .invalidField(let field):
                    // Permanent client-side validation error — dead-letter immediately, no retry.
                    AppLogger.sync.error("[ReplayDebug] invalid \(field) for \(change.entityType)=\(change.entityID) — dead-lettering immediately")
                    moveToDeadLetter(change, lastError: "Invalid \(field)", context: context)

                case .mixedCurrencySettlement, .mixedCurrencyGroupTx, .addMemberFailed:
                    // Permanent client-side validation failure — retrying cannot help.
                    // Dead-letter immediately without incrementing retry count.
                    AppLogger.sync.error("[ReplayDebug] \(apiError) for \(change.entityType)=\(change.entityID) action=\(change.action) — permanent 400, dead-lettering immediately")
                    moveToDeadLetter(change, lastError: apiError.errorDescription ?? "Permanent 400", context: context)

                case .idOwnedByAnotherUser, .idOwnedByAnotherGroup:
                    // UUID collision — this entity belongs to another user/group and is
                    // unrecoverable from the client's perspective. Purge the local row
                    // and drop the pending change regardless of action.
                    AppLogger.sync.error("[ReplayDebug] \(apiError) for \(change.entityType)=\(change.entityID) action=\(change.action) — purging local entity and discarding change")
                    discardChangeAndEntity(change, context: context)

                case .conflict where change.action == "create":
                    // 409 on a create — entity already exists on server, treat as success.
                    AppLogger.sync.warning("[ReplayDebug] 409 on create for \(change.entityType)=\(change.entityID) — entity already on server, discarding pending change")
                    discardChange(change, context: context)

                default:
                    let detail: String
                    if case .httpError(let code, let msg) = apiError {
                        detail = "HTTP \(code): \(msg ?? "(no body)")"
                    } else {
                        detail = apiError.localizedDescription
                    }
                    retryOrDeadLetter(change, error: detail, context: context)
                }
            }
        }
    }

    /// Removes the pending change and saves. Use when the server conflict is resolved
    /// without touching the local entity (e.g. STALE_WRITE, duplicate create).
    private func discardChange(_ change: PendingChange, context: ModelContext) {
        context.delete(change)
        try? context.save()
    }

    /// Removes both the local entity and the pending change. Use when the local row
    /// is stale or invalid and should be replaced by the next server pull
    /// (e.g. OVERRIDE_ALREADY_EXISTS, PREDEFINED_NOT_FOUND, 404 on delete).
    private func discardChangeAndEntity(_ change: PendingChange, context: ModelContext) {
        hardDeleteEntity(entityType: change.entityType, entityID: change.entityID, context: context)
        context.delete(change)
        try? context.save()
    }

    /// Increments retry count and schedules backoff, or dead-letters if the limit is reached.
    private func retryOrDeadLetter(_ change: PendingChange, error: String, context: ModelContext) {
        change.retryCount += 1
        AppLogger.sync.warning("replayAll: retry \(change.retryCount)/\(self.retryScheduler.maxRetryCount) for entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action) error=\(error)")
        if let nextRetry = retryScheduler.nextRetryDate(after: change.retryCount) {
            change.nextRetryAt = nextRetry
            try? context.save()
        } else {
            AppLogger.sync.error("replayAll: dead-lettering entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action) after \(change.retryCount) retries — final error: \(error)")
            moveToDeadLetter(change, lastError: error, context: context)
        }
    }

    private func purgeExpiredFailedChanges(context: ModelContext) {
        let ttl: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        let cutoff = Date(timeIntervalSinceNow: -ttl)
        let descriptor = FetchDescriptor<FailedChange>(
            predicate: #Predicate { $0.failedAt < cutoff }
        )
        guard let expired = try? context.fetch(descriptor), !expired.isEmpty else { return }
        AppLogger.sync.info("Purging \(expired.count) FailedChange records older than 30 days")
        expired.forEach { context.delete($0) }
        try? context.save()
    }

    private func moveToDeadLetter(_ change: PendingChange, lastError: String, context: ModelContext) {
        let failed = FailedChange(
            entityType: change.entityType,
            entityID: change.entityID,
            action: change.action,
            endpoint: change.endpoint,
            httpMethod: change.httpMethod,
            payload: change.payload,
            createdAt: change.createdAt,
            retryCount: change.retryCount,
            lastError: lastError
        )
        context.insert(failed)
        context.delete(change)
        try? context.save()
    }

    private func replayChange(_ change: PendingChange, context: ModelContext) async throws {
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
        let descriptor = FetchDescriptor<PendingChange>()
        if let changes = try? context.fetch(descriptor) {
            for change in changes {
                context.delete(change)
            }
            try? context.save()
        }
    }

    func orphanAll(context: ModelContext) {
        let descriptor = FetchDescriptor<PendingChange>()
        guard let changes = try? context.fetch(descriptor), !changes.isEmpty else { return }

        for change in changes {
            let orphan = OrphanedChange(
                entityType: change.entityType,
                entityID: change.entityID,
                action: change.action,
                endpoint: change.endpoint,
                httpMethod: change.httpMethod,
                payload: change.payload,
                createdAt: change.createdAt
            )
            context.insert(orphan)
            context.delete(change)
        }
        try? context.save()
    }

    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: EntityType, context: ModelContext) {
        guard !entityIDs.isEmpty else { return }
        let raw = entityType.rawValue
        let descriptor = FetchDescriptor<PendingChange>(
            predicate: #Predicate { $0.entityType == raw }
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
        let descriptor = FetchDescriptor<OrphanedChange>(
            predicate: #Predicate { $0.orphanedAt < cutoff }
        )
        guard let expired = try? context.fetch(descriptor), !expired.isEmpty else { return }
        for orphan in expired {
            context.delete(orphan)
        }
        try? context.save()
    }
}

