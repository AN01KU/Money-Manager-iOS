//
//  CategorySpending.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation

struct CategorySpending: Identifiable {
    let id: UUID
    let category: Category
    let amount: Double
    let percentage: Int
    
    init(id: UUID = UUID(), category: Category, amount: Double, percentage: Int) {
        self.id = id
        self.category = category
        self.amount = amount
        self.percentage = percentage
    }
}
