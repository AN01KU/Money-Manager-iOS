//
//  Expense.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    
    var amount: Double
    var category: String
    var date: Date
    var time: Date?
    var expenseDescription: String?
    var notes: String?
    
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    var recurringExpenseId: UUID?
    var isRecurring: Bool
    
    var groupId: UUID?
    var groupName: String?
    
    init(
        amount: Double,
        category: String,
        date: Date,
        time: Date? = nil,
        expenseDescription: String? = nil,
        notes: String? = nil,
        recurringExpenseId: UUID? = nil,
        groupId: UUID? = nil,
        groupName: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.date = date
        self.time = time
        self.expenseDescription = expenseDescription
        self.notes = notes
        self.recurringExpenseId = recurringExpenseId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDeleted = false
        self.isRecurring = recurringExpenseId != nil
        self.groupId = groupId
        self.groupName = groupName
    }
}
