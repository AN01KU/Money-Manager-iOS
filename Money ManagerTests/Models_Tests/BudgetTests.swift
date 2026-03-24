import Foundation
import Testing
@testable import Money_Manager

@MainActor
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
    
    // Additional edge case tests
    
    @Test
    func testBudgetPercentageExactFifty() {
        let budget = Budget(monthlyLimit: 1000, spent: 500, month: Date())
        
        #expect(budget.percentage == 50)
    }
    
    @Test
    func testBudgetPercentageOverBudget() {
        let budget = Budget(monthlyLimit: 1000, spent: 1500, month: Date())
        
        #expect(budget.percentage == 150)
    }
    
    @Test
    func testBudgetRemainingUnderBudget() {
        let budget = Budget(monthlyLimit: 5000, spent: 2000, month: Date())
        
        #expect(budget.remaining == 3000)
    }
    
    @Test
    func testBudgetRemainingOverBudget() {
        let budget = Budget(monthlyLimit: 3000, spent: 5000, month: Date())
        
        #expect(budget.remaining == -2000)
    }
    
    @Test
    func testBudgetPercentageZeroSpent() {
        let budget = Budget(monthlyLimit: 5000, spent: 0, month: Date())
        
        #expect(budget.percentage == 0)
        #expect(budget.remaining == 5000)
    }
    
    @Test
    func testBudgetPercentageRoundsDown() {
        let budget = Budget(monthlyLimit: 1000, spent: 333, month: Date())
        
        #expect(budget.percentage == 33)
    }
}
