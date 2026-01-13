//
//  Transaction.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation

struct Transaction: Identifiable {
    let id: UUID
    let category: Category
    let description: String
    let amount: Double
    let date: Date
    let isRecurring: Bool
    
    init(id: UUID = UUID(), category: Category, description: String, amount: Double, date: Date, isRecurring: Bool = false) {
        self.id = id
        self.category = category
        self.description = description
        self.amount = amount
        self.date = date
        self.isRecurring = isRecurring
    }
}
