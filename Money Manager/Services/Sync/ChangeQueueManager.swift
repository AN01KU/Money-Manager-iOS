//
//  ChangeQueueManager.swift
//  Money Manager
//

import Foundation
import SwiftData

final class ChangeQueueManager {
    static let shared = ChangeQueueManager()
    
    private let apiClient = APIClient.shared
    private var modelContainer: ModelContainer?
    
    private init() {}
    
    func configure(container: ModelContainer) {
        self.modelContainer = container
    }
    
    var pendingCount: Int {
        guard let container = modelContainer else { return 0 }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<PendingChange>()
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
    
    func replayAll(context: ModelContext) async {
        let descriptor = FetchDescriptor<PendingChange>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        guard let changes = try? context.fetch(descriptor) else { return }
        
        for change in changes {
            do {
                try await replayChange(change, context: context)
            } catch {
                if case APIError.unauthorized = error {
                    NotificationCenter.default.post(name: .authSessionExpired, object: nil)
                    break
                }
                
                change.retryCount += 1
                try? context.save()
                break
            }
        }
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
            let _: MessageResponse = try await apiClient.deleteMessage(endpoint)
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
