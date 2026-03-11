import Foundation
import SwiftData
import Testing
@testable import Money_Manager

typealias TestCategory = Money_Manager.Category

struct CategorySpendingModelTests {
    
    @Test
    func testCategorySpendingInitialization() {
        let spending = CategorySpending(
            category: .food,
            amount: 500,
            percentage: 50
        )
        
        #expect(spending.category == .food)
        #expect(spending.amount == 500)
        #expect(spending.percentage == 50)
    }
    
    @Test
    func testCategorySpendingGeneratesUniqueId() {
        let spending1 = CategorySpending(category: .food, amount: 100, percentage: 50)
        let spending2 = CategorySpending(category: .food, amount: 100, percentage: 50)
        
        #expect(spending1.id != spending2.id)
    }
    
    @Test
    func testCategorySpendingWithZeroAmount() {
        let spending = CategorySpending(
            category: .transport,
            amount: 0,
            percentage: 0
        )
        
        #expect(spending.amount == 0)
        #expect(spending.percentage == 0)
    }
    
    @Test
    func testCategorySpendingWithAllCategoryTypes() {
        let categories: [TestCategory] = [.food, .transport, .housing, .healthMedical, .shopping, .utilities, .entertainment, .travel, .workProfessional, .education, .debtPayments, .booksMedia, .familyKids, .gifts, .other]
        
        for category in categories {
            let spending = CategorySpending(category: category, amount: 100, percentage: 10)
            #expect(spending.category == category)
        }
    }
    
    @Test
    func testCategorySpendingWithHighPercentage() {
        let spending = CategorySpending(
            category: .food,
            amount: 1000,
            percentage: 100
        )
        
        #expect(spending.percentage == 100)
        #expect(spending.amount == 1000)
    }
    
    @Test
    func testCategorySpendingIsIdentifiable() {
        let spending = CategorySpending(category: .food, amount: 100, percentage: 50)
        
        #expect(spending.id != nil)
    }
}
