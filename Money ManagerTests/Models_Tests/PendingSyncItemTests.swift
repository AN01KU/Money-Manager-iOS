import Foundation
import SwiftData
import Testing
@testable import Money_Manager

struct PendingSyncItemModelTests {
    
    @Test
    func testPendingSyncItemDefaultsRetryCountToZero() {
        let payload = "test".data(using: .utf8)!
        let item = PendingSyncItem(
            itemType: .personalExpense,
            itemId: UUID(),
            action: .create,
            payload: payload
        )
        
        #expect(item.retryCount == 0)
    }
    
    @Test
    func testPendingSyncItemDefaultsLastErrorToNil() {
        let payload = "test".data(using: .utf8)!
        let item = PendingSyncItem(
            itemType: .budget,
            itemId: UUID(),
            action: .update,
            payload: payload
        )
        
        #expect(item.lastError == nil)
    }
    
    @Test
    func testPendingSyncItemStoresAllItemTypes() {
        let payload = "test".data(using: .utf8)!
        let itemId = UUID()
        
        let item = PendingSyncItem(
            itemType: .sharedExpense,
            itemId: itemId,
            action: .delete,
            payload: payload
        )
        
        #expect(item.itemType == "shared_expense")
        #expect(item.itemId == itemId)
        #expect(item.action == "delete")
    }
    
    @Test
    func testPendingSyncItemStoresPayloadCorrectly() {
        let testString = "{\"amount\": 500, \"category\": \"Food\"}"
        let payload = testString.data(using: .utf8)!
        
        let item = PendingSyncItem(
            itemType: .personalExpense,
            itemId: UUID(),
            action: .create,
            payload: payload
        )
        
        #expect(item.payload == payload)
    }
    
    @Test
    func testPendingSyncItemActionEnumValues() {
        let payload = "test".data(using: .utf8)!
        
        let createItem = PendingSyncItem(itemType: .category, itemId: UUID(), action: .create, payload: payload)
        let updateItem = PendingSyncItem(itemType: .category, itemId: UUID(), action: .update, payload: payload)
        let deleteItem = PendingSyncItem(itemType: .category, itemId: UUID(), action: .delete, payload: payload)
        
        #expect(createItem.action == "create")
        #expect(updateItem.action == "update")
        #expect(deleteItem.action == "delete")
    }
    
    @Test
    func testPendingSyncItemItemTypeEnumValues() {
        let payload = "test".data(using: .utf8)!
        
        let expenseItem = PendingSyncItem(itemType: .personalExpense, itemId: UUID(), action: .create, payload: payload)
        let sharedItem = PendingSyncItem(itemType: .sharedExpense, itemId: UUID(), action: .create, payload: payload)
        let budgetItem = PendingSyncItem(itemType: .budget, itemId: UUID(), action: .create, payload: payload)
        let categoryItem = PendingSyncItem(itemType: .category, itemId: UUID(), action: .create, payload: payload)
        
        #expect(expenseItem.itemType == "personal_expense")
        #expect(sharedItem.itemType == "shared_expense")
        #expect(budgetItem.itemType == "budget")
        #expect(categoryItem.itemType == "category")
    }
}
