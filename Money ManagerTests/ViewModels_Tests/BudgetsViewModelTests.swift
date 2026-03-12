import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetsViewModelTests {
    
    private func currentYearMonth() -> (year: Int, month: Int) {
        let calendar = Calendar.current
        let now = Date()
        return (calendar.component(.year, from: now), calendar.component(.month, from: now))
    }
    
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
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 300, category: "Food", date: Date())
        let budget = MonthlyBudget(year: year, month: month, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.remainingBudget == 700)
    }
    
    @Test
    func testRemainingBudgetNeverNegative() {
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 1500, category: "Food", date: Date())
        let budget = MonthlyBudget(year: year, month: month, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.remainingBudget == 0)
    }
    
    @Test
    func testBudgetPercentageCalculatesCorrectly() {
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 250, category: "Food", date: Date())
        let budget = MonthlyBudget(year: year, month: month, limit: 1000)
        
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
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 500, category: "Food", date: Date())
        let budget = MonthlyBudget(year: year, month: month, limit: 0)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 0)
    }
    
    @Test
    func testBudgetPercentageAtLimit() {
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 1000, category: "Food", date: Date())
        let budget = MonthlyBudget(year: year, month: month, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 100)
    }
    
    @Test
    func testBudgetPercentageOverBudget() {
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 1500, category: "Food", date: Date())
        let budget = MonthlyBudget(year: year, month: month, limit: 1000)
        
        viewModel.configure(allExpenses: [expense], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.budgetPercentage == 150)
    }
    
    @Test
    func testDailyAverageCalculatesCorrectly() {
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        
        let expense = Expense(amount: 200, category: "Food", date: Date())
        let budget = MonthlyBudget(year: year, month: month, limit: 1000)
        
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
        let (year, month) = currentYearMonth()
        let viewModel = BudgetsViewModel()
        viewModel.selectedMonth = Date()
        
        let budget = MonthlyBudget(year: year, month: month, limit: 5000)
        
        viewModel.configure(allExpenses: [], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.currentBudget?.limit == 5000)
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
        
        #expect(viewModel.currentMonthExpenses.count == 1)
        #expect(viewModel.currentMonthExpenses.first?.amount == 500)
    }
    
    // MARK: - Days Remaining Tests
    
    @Test
    func testDaysRemainingCalculatesForCurrentMonth() {
        let viewModel = BudgetsViewModel()
        viewModel.selectedMonth = Date()
        
        #expect(viewModel.daysRemaining > 0)
    }
    
    @Test
    func testDaysRemainingReturnsZeroForPastMonth() {
        let viewModel = BudgetsViewModel()
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        viewModel.selectedMonth = lastMonth
        
        #expect(viewModel.daysRemaining == 0)
    }
    
    @Test
    func testDaysRemainingReturnsZeroForFutureMonth() {
        let viewModel = BudgetsViewModel()
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date())!
        
        viewModel.selectedMonth = nextMonth
        
        #expect(viewModel.daysRemaining == 0)
    }
    
    // MARK: - Daily Average Tests
    
    @Test
    func testDailyAverageIsZeroWhenDaysRemainingIsZero() {
        let viewModel = BudgetsViewModel()
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        viewModel.selectedMonth = lastMonth
        
        let budget = MonthlyBudget(year: 2025, month: 1, limit: 1000)
        viewModel.configure(allExpenses: [], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.dailyAverage == 0)
    }
    
    // MARK: - Current Budget Tests
    
    @Test
    func testCurrentBudgetReturnsNilWhenNoBudgets() {
        let viewModel = BudgetsViewModel()
        viewModel.selectedMonth = Date()
        
        viewModel.configure(allExpenses: [], budgets: [], modelContext: nil)
        
        #expect(viewModel.currentBudget == nil)
    }
    
    @Test
    func testCurrentBudgetReturnsNilWhenNoMatchingMonth() {
        let viewModel = BudgetsViewModel()
        viewModel.selectedMonth = Date()
        
        let budget = MonthlyBudget(year: 2020, month: 1, limit: 1000)
        viewModel.configure(allExpenses: [], budgets: [budget], modelContext: nil)
        
        #expect(viewModel.currentBudget == nil)
    }
    
    @Test
    func testCurrentBudgetFindsCorrectYearAndMonth() {
        let viewModel = BudgetsViewModel()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        
        viewModel.selectedMonth = Date()
        
        let budget1 = MonthlyBudget(year: year, month: month, limit: 5000)
        let budget2 = MonthlyBudget(year: year + 1, month: month, limit: 6000)
        
        viewModel.configure(allExpenses: [], budgets: [budget1, budget2], modelContext: nil)
        
        #expect(viewModel.currentBudget?.limit == 5000)
    }
    
    // MARK: - Initial State Tests
    
    @Test
    func testInitialState() {
        let viewModel = BudgetsViewModel()
        
        #expect(viewModel.showBudgetSheet == false)
        #expect(viewModel.allExpenses.isEmpty)
        #expect(viewModel.budgets.isEmpty)
    }
}
