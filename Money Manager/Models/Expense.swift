//
//  Expense.swift
//  Money Manager
//
//  Renamed to Transaction model. Kept as Expense.swift to avoid Xcode project file churn —
//  the class inside is now Transaction.
//

import Foundation
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
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDeleted = false
        self.categoryId = categoryId
    }
}
