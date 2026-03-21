import Foundation
import SwiftUI
import SwiftData
import Testing
@testable import Money_Manager

struct CategorySpendingModelTests {
    
    @Test
    func testCategorySpendingInitialization() {
        let spending = CategorySpending(
            categoryName: "Food & Dining",
            icon: "fork.knife.circle.fill",
            color: Color(hex: "#FF6B6B"),
            amount: 500,
            percentage: 50
        )
        
        #expect(spending.categoryName == "Food & Dining")
        #expect(spending.amount == 500)
        #expect(spending.percentage == 50)
    }
    
    @Test
    func testCategorySpendingGeneratesUniqueId() {
        let spending1 = CategorySpending(categoryName: "Food", icon: "fork.knife.circle.fill", color: .red, amount: 100, percentage: 50)
        let spending2 = CategorySpending(categoryName: "Food", icon: "fork.knife.circle.fill", color: .red, amount: 100, percentage: 50)
        
        #expect(spending1.id != spending2.id)
    }
    
    @Test
    func testCategorySpendingWithZeroAmount() {
        let spending = CategorySpending(
            categoryName: "Transport",
            icon: "car.circle.fill",
            color: Color(hex: "#4ECDC4"),
            amount: 0,
            percentage: 0
        )
        
        #expect(spending.amount == 0)
        #expect(spending.percentage == 0)
    }
    
    @Test
    func testCategorySpendingWithHighPercentage() {
        let spending = CategorySpending(
            categoryName: "Food & Dining",
            icon: "fork.knife.circle.fill",
            color: Color(hex: "#FF6B6B"),
            amount: 1000,
            percentage: 100
        )
        
        #expect(spending.percentage == 100)
        #expect(spending.amount == 1000)
    }
    
    @Test
    func testCategorySpendingIsIdentifiable() {
        let spending = CategorySpending(categoryName: "Food", icon: "fork.knife.circle.fill", color: .red, amount: 100, percentage: 50)
        
        #expect(spending.id != nil)
    }
}
