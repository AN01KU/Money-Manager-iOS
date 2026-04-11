//
//  ChangeQueueManagerProtocol.swift
//  Money Manager
//

import Foundation
import SwiftData

protocol ChangeQueueManagerProtocol: AnyObject {
    var pendingCount: Int { get }
    var failedCount: Int { get }

    func configure(container: ModelContainer)
    func enqueue(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        context: ModelContext
    )
    func replayAll(context: ModelContext, isAuthenticated: Bool) async
    func clearAll(context: ModelContext)
    /// Moves all pending changes to the orphaned store (soft-discard).
    func orphanAll(context: ModelContext)
    /// Deletes orphaned records older than the given number of days.
    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext)
}
