//
//  PendingSyncItem.swift
//  Money Manager
//
//  Model for tracking pending sync operations
//

import Foundation
import SwiftData

@Model
final class PendingSyncItem {
    var id: UUID
    var itemType: String
    var itemId: UUID
    var action: String
    var payload: Data
    var createdAt: Date
    var retryCount: Int
    var lastError: String?
    
    enum ItemType: String {
        case personalExpense = "personal_expense"
        case sharedExpense = "shared_expense"
        case budget = "budget"
        case category = "category"
    }
    
    enum Action: String {
        case create = "create"
        case update = "update"
        case delete = "delete"
    }
    
    init(
        itemType: ItemType,
        itemId: UUID,
        action: Action,
        payload: Data
    ) {
        self.id = UUID()
        self.itemType = itemType.rawValue
        self.itemId = itemId
        self.action = action.rawValue
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
        self.lastError = nil
    }
}
