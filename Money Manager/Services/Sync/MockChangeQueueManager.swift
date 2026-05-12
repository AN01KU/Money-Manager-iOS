//
//  MockChangeQueueManager.swift
//  Money Manager
//

import Foundation
import SwiftData

#if DEBUG
final class MockChangeQueueManager: ChangeQueueManagerProtocol {
    static let shared = MockChangeQueueManager()

    struct EnqueueCall {
        let entityType: String
        let entityID: UUID
        let action: String
        let endpoint: String
        let httpMethod: String
        let payload: Data?
    }

    private init() {}

    var pendingCount: Int { 0 }
    var failedCount: Int { 0 }

    private(set) var enqueueCallLog: [EnqueueCall] = []
    private(set) var replayAllCallCount: Int = 0
    private(set) var orphanAllCallCount: Int = 0

    func reset() {
        enqueueCallLog = []
        replayAllCallCount = 0
        orphanAllCallCount = 0
    }

    func configure(container: ModelContainer) {}

    func enqueue(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        context: ModelContext
    ) {
        enqueueCallLog.append(EnqueueCall(
            entityType: entityType,
            entityID: entityID,
            action: action,
            endpoint: endpoint,
            httpMethod: httpMethod,
            payload: payload
        ))
    }

    func replayAll(context: ModelContext, isAuthenticated: Bool) async {
        replayAllCallCount += 1
    }

    func clearAll(context: ModelContext) {}

    func orphanAll(context: ModelContext) {
        orphanAllCallCount += 1
    }

    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext) {}

    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: String, context: ModelContext) {}
}
#endif
