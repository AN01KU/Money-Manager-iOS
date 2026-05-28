//
//  LocalSyncableEntity.swift
//  Money Manager
//

import Foundation

/// A local SwiftData model that can be synced with the backend.
///
/// Conformers supply the metadata needed by `PersistenceService.save<T>` to
/// enqueue the right change record without any entity-specific switch statements.
protocol LocalSyncableEntity {
    /// The queue entity type used when logging a pending change.
    static var entityType: EntityType { get }

    /// The entity's stable local identifier.
    var id: UUID { get }

    /// The base REST endpoint path (e.g. "/transactions").
    static var endpoint: String { get }

    /// JSON-encoded body for a POST (create) request.
    @MainActor func createRequestPayload() throws -> Data

    /// JSON-encoded body for a PATCH (update) request.
    @MainActor func updateRequestPayload() throws -> Data
}

/// A local entity that uses soft-delete (tombstone) semantics rather than hard delete.
///
/// `PersistenceService.save(_, action: .delete)` flips `isSoftDeleted` and bumps
/// `updatedAt` automatically for conformers, so call sites never have to.
protocol SoftDeletableEntity: AnyObject {
    var isSoftDeleted: Bool { get set }
    var updatedAt: Date { get set }
}
