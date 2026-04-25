//
//  ChangeQueueManager.swift
//  Money Manager
//

import Foundation
import SwiftData

final class ChangeQueueManager: ChangeQueueManagerProtocol {
    static let shared = ChangeQueueManager()

    static let maxRetryCount = 5
    /// Base delay in seconds — actual delay is `baseRetryDelay * 2^retryCount + jitter`
    private static let baseRetryDelay: TimeInterval = 2.0

    private var apiClient: any APIClientProtocol
    private var modelContainer: ModelContainer?
    private var isReplaying = false

    init(apiClient: any APIClientProtocol = AppAPIClient.shared) {
        self.apiClient = apiClient
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

    func enqueue(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        context: ModelContext
    ) {
        let existingDescriptor = FetchDescriptor<PendingChange>(
            predicate: #Predicate { change in
                change.entityID == entityID && change.entityType == entityType
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        if let existingChanges = try? context.fetch(existingDescriptor),
           let existing = existingChanges.first {
            switch (existing.action, action) {
            case ("create", "update"):
                existing.payload = payload
                existing.retryCount = 0
            case ("create", "delete"):
                context.delete(existing)
            case ("update", "update"):
                existing.payload = payload
                existing.retryCount = 0
            case ("update", "delete"):
                existing.action = "delete"
                existing.endpoint = endpoint
                existing.httpMethod = httpMethod
                existing.payload = nil
                existing.retryCount = 0
            default:
                let change = PendingChange(
                    entityType: entityType,
                    entityID: entityID,
                    action: action,
                    endpoint: endpoint,
                    httpMethod: httpMethod,
                    payload: payload
                )
                context.insert(change)
            }
        } else {
            let change = PendingChange(
                entityType: entityType,
                entityID: entityID,
                action: action,
                endpoint: endpoint,
                httpMethod: httpMethod,
                payload: payload
            )
            context.insert(change)
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
            if change.retryCount >= ChangeQueueManager.maxRetryCount {
                moveToDeadLetter(change, lastError: "Exceeded max retry count (\(ChangeQueueManager.maxRetryCount))", context: context)
                continue
            }

            do {
                try await replayChange(change, context: context)
            } catch {
                if case APIError.unauthorized = error {
                    NotificationCenter.default.post(name: .authSessionExpired, object: nil)
                    return
                }

                if case APIError.syncSessionInvalid = error {
                    orphanAll(context: context)
                    NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
                    return
                }

                // A 404 on a delete means the entity never reached the server — treat as success
                if case APIError.notFound = error, change.action == "delete" {
                    AppLogger.sync.warning("[ReplayDebug] 404 on delete for \(change.entityType)=\(change.entityID) — entity never on server, cleaning up locally")
                    hardDeleteEntity(entityType: change.entityType, entityID: change.entityID, context: context)
                    context.delete(change)
                    try? context.save()
                    continue
                }

                // A 409 on a create means the entity already exists on the server — treat as success
                if case APIError.conflict = error, change.action == "create" {
                    AppLogger.sync.warning("[ReplayDebug] 409 on create for \(change.entityType)=\(change.entityID) — entity already on server, discarding pending change")
                    context.delete(change)
                    try? context.save()
                    continue
                }

                let errorDetail: String
                if let apiError = error as? APIError, case .httpError(let code, let msg) = apiError {
                    errorDetail = "HTTP \(code): \(msg ?? "(no body)")"
                } else {
                    errorDetail = error.localizedDescription
                }

                change.retryCount += 1
                AppLogger.sync.warning("replayAll: retry \(change.retryCount)/\(ChangeQueueManager.maxRetryCount) for entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action) error=\(errorDetail)")

                if change.retryCount >= ChangeQueueManager.maxRetryCount {
                    AppLogger.sync.error("replayAll: dead-lettering entityType=\(change.entityType) entityID=\(change.entityID) action=\(change.action) after \(change.retryCount) retries — final error: \(errorDetail)")
                    moveToDeadLetter(change, lastError: errorDetail, context: context)
                } else {
                    change.nextRetryAt = Self.backoffDate(forRetry: change.retryCount)
                    try? context.save()
                }
            }
        }
    }

    /// Returns the next retry date using exponential backoff with random jitter.
    /// Delays: ~2s, ~4s, ~8s, ~16s, ~32s for retries 1–5.
    private static func backoffDate(forRetry retryCount: Int) -> Date {
        let exponent = min(retryCount, 10)
        let base = baseRetryDelay * pow(2.0, Double(exponent))
        let jitter = Double.random(in: 0..<base * 0.2)
        return Date(timeIntervalSinceNow: base + jitter)
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

        switch change.httpMethod {
        case "POST":
            guard let payload = change.payload else { return }
            let _: EmptyResponse = try await apiClient.post(.raw(endpoint), rawBody: payload)
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

    /// Hard-deletes the local SwiftData record after a successful backend DELETE.
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
                AppLogger.sync.debug("[TxnDebug] hardDeleteEntity: hard-deleting txn=\(entityID) category=\(item.category) amount=\(item.amount)")
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

