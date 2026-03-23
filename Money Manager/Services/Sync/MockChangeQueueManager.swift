//
//  MockChangeQueueManager.swift
//  Money Manager
//

import Foundation
import SwiftData

#if DEBUG
final class MockChangeQueueManager: ChangeQueueManagerProtocol {
    static let shared = MockChangeQueueManager()
    
    private init() {}
    
    var pendingCount: Int { 0 }
    
    func configure(container: ModelContainer) {}
    
    func enqueue(
        entityType: String,
        entityID: UUID,
        action: String,
        endpoint: String,
        httpMethod: String,
        payload: Data?,
        context: ModelContext
    ) {}
    
    func replayAll(context: ModelContext) async {}
    
    func clearAll(context: ModelContext) {}
}
#endif
