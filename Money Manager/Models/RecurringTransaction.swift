//
//  RecurringTransaction.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation
import SwiftData

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
}

@Model
final class RecurringTransaction {
    @Attribute(.unique) var id: UUID

    var name: String
    var amount: Double
    var category: String

    var frequency: RecurringFrequency
    var dayOfMonth: Int?
    var daysOfWeek: [Int]?

    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var lastAddedDate: Date?

    var notes: String?

    /// UUID of the linked CustomCategory.
    var categoryId: UUID?

    var type: TransactionKind

    @Attribute(originalName: "isDeleted") var isSoftDeleted: Bool

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        category: String,
        frequency: RecurringFrequency,
        dayOfMonth: Int? = nil,
        daysOfWeek: [Int]? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        lastAddedDate: Date? = nil,
        notes: String? = nil,
        categoryId: UUID? = nil,
        type: TransactionKind = .expense,
        isSoftDeleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.frequency = frequency
        self.dayOfMonth = dayOfMonth
        self.daysOfWeek = daysOfWeek
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.lastAddedDate = lastAddedDate
        self.notes = notes
        self.categoryId = categoryId
        self.type = type
        self.isSoftDeleted = isSoftDeleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
