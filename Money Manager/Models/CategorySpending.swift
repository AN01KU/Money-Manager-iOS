import SwiftUI

struct CategorySpending: Identifiable {
    let id: UUID
    let categoryId: UUID
    let categoryName: String
    let icon: String
    let color: Color
    let amount: Double
    let percentage: Int

    init(id: UUID = UUID(), categoryId: UUID, categoryName: String, icon: String, color: Color, amount: Double, percentage: Int) {
        self.id = id
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.icon = icon
        self.color = color
        self.amount = amount
        self.percentage = percentage
    }
}
