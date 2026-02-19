import Foundation
import Testing
@testable import Money_Manager

struct BudgetModelTests {
    
    @Test
    func testBudgetPercentageWithZeroLimitDoesNotCrash() {
        let budget = Budget(monthlyLimit: 0, spent: 100, month: Date())
        
        #expect(budget.percentage == 0)
    }
    
    @Test
    func testBudgetRemainingWithNegativeSpending() {
        let budget = Budget(monthlyLimit: 1000, spent: -100, month: Date())
        
        #expect(budget.remaining == 1100)
    }
    
    @Test
    func testBudgetPercentageWithVeryLargeNumbers() {
        let budget = Budget(monthlyLimit: Double.greatestFiniteMagnitude, spent: 1000000, month: Date())
        
        #expect(budget.percentage == 0)
    }
    
    @Test
    func testBudgetRemainingWithExactLimit() {
        let budget = Budget(monthlyLimit: 5000, spent: 5000, month: Date())
        
        #expect(budget.remaining == 0)
        #expect(budget.percentage == 100)
    }
}
