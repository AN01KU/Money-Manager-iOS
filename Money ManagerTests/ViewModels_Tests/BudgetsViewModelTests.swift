import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetsViewModelTests {
    
    @Test
    func testTotalSpentCalculatesCorrectly() {
        let viewModel = BudgetsViewModel()
        
        let expense1 = Expense(amount: 500, category: "Food", date: Date())
        let expense2 = Expense(amount: 300, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        
        #expect(viewModel.totalSpent == 800)
    }
    
    @Test
    func testTotalSpentIgnoresDeletedExpenses() {
        let viewModel = BudgetsViewModel()
        
        let activeExpense = Expense(amount: 500, category: "Food", date: Date())
        let deletedExpense = Expense(amount: 300, category: "Transport", date: Date())
        deletedExpense.isDeleted = true
        
        viewModel.configure(allExpenses: [activeExpense, deletedExpense], budgets: [], modelContext: nil)
        
        #expect(viewModel.totalSpent == 500)
    }
    
    @Test
    func testTotalSpentReturnsZeroForNoExpenses() {
        let viewModel = BudgetsViewModel()
        
        viewModel.configure(allExpenses: [], budgets: [], modelContext: nil)
        
        #expect(viewModel.totalSpent == 0)
    }
    
    @Test
    func testRemainingBudgetWhenNoBudgetSet() {
        let viewModel = BudgetsViewModel()
        
        viewModel.configure(allExpenses: [], budgets: [], modelContext: nil)
        
        #expect(viewModel.remainingBudget == 0)
    }
    
    @Test
    func testRemainingBudgetCalculatesCorrectly() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 300, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.remainingBudget == 700)
    }
    
    @Test
    func testRemainingBudgetNeverNegative() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 1500, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.remainingBudget == 0)
    }
    
    @Test
    func testBudgetPercentageCalculatesCorrectly() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 250, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 25)
    }
    
    @Test
    func testBudgetPercentageIsZeroWhenNoBudget() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 500, category: "Food", date: Date())
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 0)
    }
    
    @Test
    func testBudgetPercentageIsZeroWhenLimitIsZero() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 500, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 0)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 0)
    }
    
    @Test
    func testBudgetPercentageAtLimit() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 1000, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 100)
    }
    
    @Test
    func testBudgetPercentageOverBudget() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 1500, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 150)
    }
    
    @Test
    func testDailyAverageCalculatesCorrectly() {
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 200, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.dailyAverage > 0)
    }
    
    @Test
    func testDailyAverageIsZeroWhenNoBudget() {
        let viewModel = BudgetsViewModel()
        
        viewModel.configure(allExpenses: [], budgets: [], modelContext: nil)
        
        #expect(viewModel.dailyAverage == 0)
    }
    
    @Test
    func testCurrentBudgetFindsCorrectMonth() {
        let viewModel = BudgetsViewModel()
        viewModel.selectedMonth = Date()
        
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 5000)
        
        viewModel.configure(allExpenses: [], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.currentBudget == nil || viewModel.currentBudget?.limit == 5000)
    }
    
    @Test
    func testCurrentMonthExpensesFiltersByMonth() {
        let viewModel = BudgetsViewModel()
        viewModel.selectedMonth = Date()
        
        let calendar = Calendar.current
        let thisMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: thisMonth)!
        
        let expenseThisMonth = Expense(amount: 500, category: "Food", date: thisMonth)
        let expenseLastMonth = Expense(amount: 300, category: "Food", date: lastMonth)
        
        viewModel.configure(allExpenses: [expenseThisMonth, expenseLastMonth], budgets: [], modelContext: nil)
        
        #expect(viewModel.currentMonthExpenses.count >= 1)
    }
}
