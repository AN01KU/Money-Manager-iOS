//
//  MonthlyBudget.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation
import SwiftData

@Model
final class MonthlyBudget {
    @Attribute(.unique) var id: UUID
    
    var year: Int
    var month: Int
    var limit: Double
    
    var createdAt: Date
    var updatedAt: Date
    
    init(year: Int, month: Int, limit: Double) {
        self.id = UUID()
        self.year = year
        self.month = month
        self.limit = limit
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
