//
//  CategorySpending.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import SwiftUI

struct CategorySpending: Identifiable {
    let id: UUID
    let categoryKey: String
    let categoryName: String
    let icon: String
    let color: Color
    let amount: Double
    let percentage: Int

    init(id: UUID = UUID(), categoryKey: String? = nil, categoryName: String, icon: String, color: Color, amount: Double, percentage: Int) {
        self.id = id
        self.categoryKey = categoryKey ?? categoryName
        self.categoryName = categoryName
        self.icon = icon
        self.color = color
        self.amount = amount
        self.percentage = percentage
    }
}
