//
//  RecurringExpense.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation
import SwiftData

@Model
final class RecurringExpense {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var amount: Double
    var category: String
    var frequency: String
    var notes: String?
    
    var startDate: Date
    var endDate: Date?
    var dayOfWeek: [Int]?
    var dayOfMonth: Int?
    var skipWeekends: Bool
    var skipDates: [Date]?
    
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    var lastGeneratedDate: Date?
    
    init(
        name: String,
        amount: Double,
        category: String,
        frequency: String,
        startDate: Date,
        endDate: Date? = nil,
        dayOfMonth: Int? = nil,
        dayOfWeek: [Int]? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.dayOfMonth = dayOfMonth
        self.dayOfWeek = dayOfWeek
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.skipWeekends = false
        self.skipDates = nil
    }
}
