//
//  MockChangeQueueManager.swift
//  Money Manager
//

import Foundation
import SwiftData

#if DEBUG
@MainActor
final class MockChangeQueueManager: ChangeQueueManagerProtocol {
    static let shared = MockChangeQueueManager()

    private init() {}

    var pendingCount: Int { 0 }
    var failedCount: Int { 0 }

    private(set) var enqueueCallLog: [PendingChangeDraft] = []
    private(set) var replayAllCallCount: Int = 0
    private(set) var orphanAllCallCount: Int = 0

    func reset() {
        enqueueCallLog = []
        replayAllCallCount = 0
        orphanAllCallCount = 0
    }

    func configure(container: ModelContainer) {}

    func enqueue(_ draft: PendingChangeDraft, context: ModelContext) {
        enqueueCallLog.append(draft)
    }

    func replayAll(context: ModelContext, isAuthenticated: Bool) async {
        replayAllCallCount += 1
    }

    func clearAll(context: ModelContext) {}

    func orphanAll(context: ModelContext) {
        orphanAllCallCount += 1
    }

    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext) {}

    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: EntityType, context: ModelContext) {}
}
#endif
