//
//  Transaction.swift
//  Money Manager
//

import Foundation
import SwiftUI
import SwiftData

enum TransactionKind: String, Codable, CaseIterable {
    case expense
    case income
}

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    
    var type: TransactionKind
    var amount: Double
    var category: String
    var date: Date
    var time: Date?
    var transactionDescription: String?
    var notes: String?
    
    var createdAt: Date
    var updatedAt: Date
    @Attribute(originalName: "isDeleted") var isSoftDeleted: Bool
    
    var recurringExpenseId: UUID?
    var groupTransactionId: UUID?
    var groupId: UUID?
    var groupName: String?
    var settlementId: UUID?
    
    /// UUID of the linked CustomCategory.
    var categoryId: UUID?

    init(
        id: UUID = UUID(),
        type: TransactionKind = .expense,
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
        self.isSoftDeleted = false
        self.categoryId = categoryId
    }
}
