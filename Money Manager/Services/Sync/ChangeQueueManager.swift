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

    private let apiClient = APIClient.shared
    private var modelContainer: ModelContainer?

    init() {}

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

                change.retryCount += 1

                if change.retryCount >= ChangeQueueManager.maxRetryCount {
                    moveToDeadLetter(change, lastError: error.localizedDescription, context: context)
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

        switch change.httpMethod {
        case "POST":
            guard let payload = change.payload else { return }
            let _: EmptyResponse = try await apiClient.post(endpoint, rawBody: payload)
        case "PUT":
            guard let payload = change.payload else { return }
            let _: EmptyResponse = try await apiClient.put(endpoint, rawBody: payload)
        case "DELETE":
            let _: APIMessageResponse = try await apiClient.deleteMessage(endpoint)
        default:
            return
        }

        context.delete(change)
        try? context.save()
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
}

private struct EmptyResponse: Decodable {}
