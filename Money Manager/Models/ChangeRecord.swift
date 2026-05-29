//
//  ChangeRecord.swift
//  Money Manager
//
//  Unified record for sync changes. Replaces the trio of
//  PendingChange / FailedChange / OrphanedChange with a single
//  @Model + `status: ChangeStatus` enum. Status-specific timestamps
//  remain as nullable fields so we don't lose information when a
//  record moves through the pending → failed → orphaned lifecycle.
//

import Foundation
import SwiftData

/// Lifecycle status of a `ChangeRecord`.
///
/// - `pending`: queued for replay against the backend.
/// - `failed`: exceeded the retry limit; lives in the dead-letter queue until manual retry or TTL purge.
/// - `orphaned`: rejected by the backend (e.g. expired sync session); kept locally so the user can be notified.
enum ChangeStatus: String, Codable, CaseIterable {
    case pending
    case failed
    case orphaned
}

@Model
final class ChangeRecord {
    @Attribute(.unique) var id: UUID

    // Core fields — identical across all statuses.
    var entityType: String      // EntityType.rawValue
    var entityID: UUID
    var action: String          // ChangeAction.rawValue
    var endpoint: String
    var httpMethod: String      // HTTPMethod.rawValue
    var payload: Data?
    var createdAt: Date

    // Lifecycle.
    // `statusRaw` is persisted as a String so #Predicate comparisons work.
    // Use `status` for all application logic.
    var statusRaw: String
    var status: ChangeStatus {
        get { ChangeStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    var retryCount: Int

    // Status-specific timestamps. Documented as meaningful only in the matching status,
    // but kept nullable across all rows so we don't lose audit information when a row
    // transitions (e.g. failedAt remains visible after a later orphan() call).
    var nextRetryAt: Date?      // pending — earliest time this change may next be retried
    var failedAt: Date?         // failed  — when the record was promoted to the dead-letter queue
    var lastError: String?      // failed  — human-readable reason for the last failure
    var orphanedAt: Date?       // orphaned — when the record was orphaned

    init(
        entityType: EntityType,
        entityID: UUID,
        action: ChangeAction,
        endpoint: String,
        httpMethod: HTTPMethod,
        payload: Data?,
        createdAt: Date = Date(),
        status: ChangeStatus = .pending,
        retryCount: Int = 0,
        nextRetryAt: Date? = nil,
        failedAt: Date? = nil,
        lastError: String? = nil,
        orphanedAt: Date? = nil
    ) {
        self.id = UUID()
        self.entityType = entityType.rawValue
        self.entityID = entityID
        self.action = action.rawValue
        self.endpoint = endpoint
        self.httpMethod = httpMethod.rawValue
        self.payload = payload
        self.createdAt = createdAt
        self.statusRaw = status.rawValue
        self.retryCount = retryCount
        self.nextRetryAt = nextRetryAt
        self.failedAt = failedAt
        self.lastError = lastError
        self.orphanedAt = orphanedAt
    }

    /// Designated initializer used by migration code and tests that need raw-string
    /// fields (e.g. when copying from the old PendingChange/FailedChange/OrphanedChange rows).
    init(
        entityTypeRaw: String,
        entityID: UUID,
        actionRaw: String,
        endpoint: String,
        httpMethodRaw: String,
        payload: Data?,
        createdAt: Date,
        status: ChangeStatus,
        retryCount: Int = 0,
        nextRetryAt: Date? = nil,
        failedAt: Date? = nil,
        lastError: String? = nil,
        orphanedAt: Date? = nil
    ) {
        self.id = UUID()
        self.entityType = entityTypeRaw
        self.entityID = entityID
        self.action = actionRaw
        self.endpoint = endpoint
        self.httpMethod = httpMethodRaw
        self.payload = payload
        self.createdAt = createdAt
        self.statusRaw = status.rawValue
        self.retryCount = retryCount
        self.nextRetryAt = nextRetryAt
        self.failedAt = failedAt
        self.lastError = lastError
        self.orphanedAt = orphanedAt
    }
}

// MARK: - Back-compat factory helpers
//
// Mirror the old PendingChange / FailedChange / OrphanedChange initializer
// signatures so call sites in tests and migration code can construct rows
// without spelling out every default-nil status field.

extension ChangeRecord {
    /// Creates a `.pending` record. Matches the old `PendingChange(entityType:...)` init.
    static func makePending(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        nextRetryAt: Date? = nil
    ) -> ChangeRecord {
        ChangeRecord(
            entityTypeRaw: entityType,
            entityID: entityID,
            actionRaw: action,
            endpoint: endpoint,
            httpMethodRaw: httpMethod,
            payload: payload,
            createdAt: createdAt,
            status: .pending,
            retryCount: retryCount,
            nextRetryAt: nextRetryAt
        )
    }

    /// Creates a `.failed` record. Matches the old `FailedChange(...)` init.
    static func makeFailed(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        createdAt: Date,
        retryCount: Int,
        lastError: String,
        failedAt: Date = Date()
    ) -> ChangeRecord {
        ChangeRecord(
            entityTypeRaw: entityType,
            entityID: entityID,
            actionRaw: action,
            endpoint: endpoint,
            httpMethodRaw: httpMethod,
            payload: payload,
            createdAt: createdAt,
            status: .failed,
            retryCount: retryCount,
            failedAt: failedAt,
            lastError: lastError
        )
    }

    /// Creates an `.orphaned` record. Matches the old `OrphanedChange(...)` init.
    static func makeOrphaned(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        createdAt: Date,
        orphanedAt: Date = Date()
    ) -> ChangeRecord {
        ChangeRecord(
            entityTypeRaw: entityType,
            entityID: entityID,
            actionRaw: action,
            endpoint: endpoint,
            httpMethodRaw: httpMethod,
            payload: payload,
            createdAt: createdAt,
            status: .orphaned,
            orphanedAt: orphanedAt
        )
    }
}

// MARK: - Status transitions
//
// Single-mutation transitions that enforce the invariant: if you set a status,
// the corresponding side-fields are stamped at the same time. Use these instead
// of mutating `status` directly.

extension ChangeRecord {
    /// Schedule the next retry attempt for a pending record.
    func scheduleRetry(at next: Date) {
        nextRetryAt = next
    }

    /// Promote the record to the dead-letter queue.
    func fail(reason: String, at now: Date = Date()) {
        status = .failed
        failedAt = now
        lastError = reason
        nextRetryAt = nil
    }

    /// Mark the record as orphaned (rejected by the backend, kept for user notification).
    func orphan(at now: Date = Date()) {
        status = .orphaned
        orphanedAt = now
        nextRetryAt = nil
    }
}
