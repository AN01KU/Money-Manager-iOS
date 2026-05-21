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
        let entityType: EntityType
        let entityID: UUID
        let action: ChangeAction
        let endpoint: String
        let httpMethod: HTTPMethod
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
        entityType: EntityType,
        entityID: UUID,
        action: ChangeAction,
        endpoint: String,
        httpMethod: HTTPMethod,
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

    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: EntityType, context: ModelContext) {}
}
#endif
