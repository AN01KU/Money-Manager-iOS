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
    func replayAll(context: ModelContext) async
    func clearAll(context: ModelContext)
}
