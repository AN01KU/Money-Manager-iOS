import Foundation
import SwiftData

/// A sync change that exceeded the maximum retry limit. Stored for inspection and manual retry.
@Model
final class FailedChange {
    @Attribute(.unique) var id: UUID

    var entityType: String
    var entityID: UUID
    var action: String
    var endpoint: String
    var httpMethod: String
    var payload: Data?
    var createdAt: Date
    var failedAt: Date
    var retryCount: Int
    /// Human-readable description of the last error that caused failure.
    var lastError: String

    init(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        createdAt: Date,
        retryCount: Int,
        lastError: String
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityID = entityID
        self.action = action
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.payload = payload
        self.createdAt = createdAt
        self.failedAt = Date()
        self.retryCount = retryCount
        self.lastError = lastError
    }
}
