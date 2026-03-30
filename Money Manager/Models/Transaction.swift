//
//  Transaction.swift
//  Money Manager
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    
    var type: String          // "expense" or "income"
    var amount: Double
    var category: String
    var date: Date
    var time: Date?
    var transactionDescription: String?
    var notes: String?
    
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    var recurringExpenseId: UUID?
    var groupTransactionId: UUID?
    var groupId: UUID?
    var groupName: String?
    var settlementId: UUID?
    
    /// UUID of the linked CustomCategory. Nil for transactions created before this field was added.
    var categoryId: UUID?
    
    init(
        id: UUID = UUID(),
        type: String = "expense",
        amount: Double,
        category: String,
        date: Date,
        time: Date? = nil,
        transactionDescription: String? = nil,
        notes: String? = nil,
        recurringExpenseId: UUID? = nil,
        groupTransactionId: UUID? = nil,
        settlementId: UUID? = nil,
        categoryId: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.category = category
        self.date = date
        self.time = time
        self.transactionDescription = transactionDescription
        self.notes = notes
        self.recurringExpenseId = recurringExpenseId
        self.groupTransactionId = groupTransactionId
        self.settlementId = settlementId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDeleted = false
        self.categoryId = categoryId
    }
}

struct TransactionDisplayItem: Identifiable {
    let id: UUID
    let category: PredefinedCategory
    let description: String
    let amount: Double
    let date: Date
    let isRecurring: Bool

    init(id: UUID = UUID(), category: PredefinedCategory, description: String, amount: Double, date: Date, isRecurring: Bool = false) {
        self.id = id
        self.category = category
        self.description = description
        self.amount = amount
        self.date = date
        self.isRecurring = isRecurring
    }
}
