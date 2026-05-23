//
//  ChangeQueueManagerProtocol.swift
//  Money Manager
//

import Foundation
import SwiftData

@MainActor
protocol ChangeQueueManagerProtocol: AnyObject {
    var pendingCount: Int { get }
    var failedCount: Int { get }

    func configure(container: ModelContainer)
    func enqueue(_ draft: PendingChangeDraft, context: ModelContext)
    func replayAll(context: ModelContext, isAuthenticated: Bool) async
    func clearAll(context: ModelContext)
    /// Moves all pending changes to the orphaned store (soft-discard).
    func orphanAll(context: ModelContext)
    /// Deletes orphaned records older than the given number of days.
    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext)
    /// Removes pending changes for entities where the server version won the conflict.
    /// Called by SyncService after applying a remote update so the queue stays clean.
    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: EntityType, context: ModelContext)
}
