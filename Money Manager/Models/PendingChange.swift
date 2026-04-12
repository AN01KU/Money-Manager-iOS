//
//  PendingChange.swift
//  Money Manager
//

import Foundation
import SwiftData

@Model
final class PendingChange {
    @Attribute(.unique) var id: UUID
    
    var entityType: String
    var entityID: UUID
    var action: String
    var endpoint: String
    var httpMethod: String
    var payload: Data?
    var createdAt: Date
    var retryCount: Int
    /// Earliest time this change can next be retried. Nil means retry immediately.
    var nextRetryAt: Date?

    init(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityID = entityID
        self.action = action
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
        self.nextRetryAt = nil
    }
}
