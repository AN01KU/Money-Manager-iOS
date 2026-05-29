//
//  OrphanedChange.swift
//  Money Manager
//

import Foundation
import SwiftData

/// A pending sync change that was rejected by the server due to a sync session
/// mismatch or expiry. Kept locally so the user can be notified rather than
/// silently losing their offline data. Auto-purged after 7 days.
@Model
final class OrphanedChange {
    @Attribute(.unique) var id: UUID

    var entityType: String
    var entityID: UUID
    var action: String
    var endpoint: String
    var httpMethod: String
    var payload: Data?
    var createdAt: Date
    var orphanedAt: Date

    init(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        createdAt: Date
    ) {
        self.id = UUID()
        self.entityType = entityType
        self.entityID = entityID
        self.action = action
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.payload = payload
        self.createdAt = createdAt
        self.orphanedAt = Date()
    }
}

extension OrphanedChange {
    convenience init(
        entityType: EntityType,
        entityID: UUID,
        action: ChangeAction,
        endpoint: String,
        httpMethod: HTTPMethod,
        payload: Data?,
        createdAt: Date
    ) {
        self.init(
            entityType: entityType.rawValue,
            entityID: entityID,
            action: action.rawValue,
            endpoint: endpoint,
            httpMethod: httpMethod.rawValue,
            payload: payload,
            createdAt: createdAt
        )
    }
}
