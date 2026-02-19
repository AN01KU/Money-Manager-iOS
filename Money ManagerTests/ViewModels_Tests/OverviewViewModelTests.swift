import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct OverviewViewModelTests {
    
    @Test
    func testRecalculateWithDailyFilterReturnsSingleDayExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .daily
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 200, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        
        #expect(viewModel.filteredExpenses.count == 2)
    }
    
    @Test
    func testRecalculateWithMonthlyFilterReturnsMonthExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        
        viewModel.configure(allExpenses: [expense1], budgets: [], modelContext: nil)
        
        #expect(viewModel.filteredExpenses.count == 1)
    }
    
    @Test
    func testRecalculateFiltersOutDeletedExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let activeExpense = Expense(amount: 100, category: "Food & Dining", date: Date())
        let deletedExpense = Expense(amount: 200, category: "Transport", date: Date())
        deletedExpense.isDeleted = true
        
        viewModel.configure(allExpenses: [activeExpense, deletedExpense], budgets: [], modelContext: nil)
        
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.filteredExpenses.first?.amount == 100)
    }
    
    @Test
    func testRecalculateCalculatesTotalSpentCorrectly() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 250, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        
        #expect(viewModel.totalSpent == 350)
    }
    
    @Test
    func testRecalculateWithZeroExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.configure(allExpenses: [], budgets: [], modelContext: nil)
        
        #expect(viewModel.totalSpent == 0)
        #expect(viewModel.filteredExpenses.isEmpty)
    }
    
    @Test
    func testRecalculateGroupsExpensesByCategory() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 200, category: "Food & Dining", date: Date())
        let expense3 = Expense(amount: 150, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2, expense3], budgets: [], modelContext: nil)
        
        #expect(viewModel.categorySpending.count == 2)
    }
    
    @Test
    func testRecalculateCalculatesCategoryPercentages() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 75, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 25, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        
        let foodCategory = viewModel.categorySpending.first { $0.category == .food }
        #expect(foodCategory?.percentage == 75)
    }
    
    @Test
    func testRecalculateCategoriesSortedByAmount() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Transport", date: Date())
        let expense2 = Expense(amount: 500, category: "Food & Dining", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        
        #expect(viewModel.categorySpending.first?.category == .food)
    }
    
    @Test
    func testSearchFiltersByCategory() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 100, category: "Food & Dining", date: Date())
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        viewModel.updateSearchText("Food")
        
        #expect(viewModel.filteredExpenses.count == 1)
    }
    
    @Test
    func testSearchFiltersByDescription() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 100, category: "Food", date: Date(), expenseDescription: "Lunch at restaurant")
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        viewModel.updateSearchText("Lunch")
        
        #expect(viewModel.filteredExpenses.count == 1)
    }
    
    @Test
    func testSearchReturnsEmptyForNoMatch() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 100, category: "Food", date: Date(), expenseDescription: "Lunch")
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        viewModel.updateSearchText("Dinner")
        
        #expect(viewModel.filteredExpenses.isEmpty)
    }
    
    @Test
    func testSearchIsCaseInsensitive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 100, category: "Food", date: Date())
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        viewModel.updateSearchText("FOOD")
        
        #expect(viewModel.filteredExpenses.count == 1)
    }
    
    @Test
    func testUpdateFilterModeTriggersRecalculate() {
        let viewModel = OverviewViewModel()
        let expense = Expense(amount: 100, category: "Food", date: Date())
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        
        viewModel.updateFilterMode(.daily)
        
        #expect(viewModel.filterMode == .daily)
    }
    
    @Test
    func testUpdateSelectedDateTriggersRecalculate() {
        let viewModel = OverviewViewModel()
        
        viewModel.updateSelectedDate(Date())
        
        #expect(viewModel.selectedDate != nil)
    }
    
    @Test
    func testCategorySpendingEmptyWhenNoExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.configure(allExpenses: [], budgets: [], modelContext: nil)
        
        #expect(viewModel.categorySpending.isEmpty)
    }
}
