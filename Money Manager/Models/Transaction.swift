//
//  Transaction.swift
//  Money Manager
//

import Foundation
import SwiftUI

// Display-only struct used in TransactionList component.
// Renamed from Transaction to free the name for the SwiftData model.
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
