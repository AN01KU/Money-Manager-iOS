import Foundation
import SwiftUI
import SwiftData
import Testing
@testable import Money_Manager

struct CategorySpendingModelTests {

    @Test
    func testCategorySpendingGeneratesUniqueId() {
        let spending1 = CategorySpending(categoryName: "Food", icon: "fork.knife.circle.fill", color: .red, amount: 100, percentage: 50)
        let spending2 = CategorySpending(categoryName: "Food", icon: "fork.knife.circle.fill", color: .red, amount: 100, percentage: 50)
        #expect(spending1.id != spending2.id)
    }
}
