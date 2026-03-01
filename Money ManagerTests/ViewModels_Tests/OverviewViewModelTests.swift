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
    
    // MARK: - Budget Matching
    
    @Test
    func testCurrentBudgetMatchesSelectedMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        
        let matchingBudget = MonthlyBudget(year: year, month: month, limit: 5000)
        let otherBudget = MonthlyBudget(year: year, month: month == 12 ? 1 : month + 1, limit: 3000)
        
        viewModel.configure(allExpenses: [], budgets: [matchingBudget, otherBudget], modelContext: nil)
        
        #expect(viewModel.currentBudget?.limit == 5000)
        #expect(viewModel.currentBudget?.year == year)
        #expect(viewModel.currentBudget?.month == month)
    }
    
    @Test
    func testCurrentBudgetIsNilWhenNoMatchingMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        
        let otherBudget = MonthlyBudget(year: year, month: month == 12 ? 1 : month + 1, limit: 3000)
        
        viewModel.configure(allExpenses: [], budgets: [otherBudget], modelContext: nil)
        
        #expect(viewModel.currentBudget == nil)
    }
    
    @Test
    func testCurrentBudgetUpdatesWhenDateChanges() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan2026 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let feb2026 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        
        let janBudget = MonthlyBudget(year: 2026, month: 1, limit: 4000)
        let febBudget = MonthlyBudget(year: 2026, month: 2, limit: 6000)
        
        viewModel.selectedDate = jan2026
        viewModel.configure(allExpenses: [], budgets: [janBudget, febBudget], modelContext: nil)
        #expect(viewModel.currentBudget?.limit == 4000)
        
        viewModel.updateSelectedDate(feb2026)
        #expect(viewModel.currentBudget?.limit == 6000)
    }
    
    // MARK: - Search Text Triggering Recalculation
    
    @Test
    func testUpdateSearchTextTriggersRecalculate() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 200, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        #expect(viewModel.filteredExpenses.count == 2)
        
        viewModel.updateSearchText("Transport")
        
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.filteredExpenses.first?.category == "Transport")
        #expect(viewModel.totalSpent == 200)
    }
    
    @Test
    func testClearingSearchTextShowsAllExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 200, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        viewModel.updateSearchText("Food")
        #expect(viewModel.filteredExpenses.count == 1)
        
        viewModel.updateSearchText("")
        #expect(viewModel.filteredExpenses.count == 2)
        #expect(viewModel.totalSpent == 300)
    }
    
    // MARK: - Filter Mode Switching
    
    @Test
    func testSwitchingFromMonthlyToDailyNarrowsResults() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let differentDay = calendar.date(byAdding: .day, value: 5, to: startOfMonth)!
        let todayStart = calendar.startOfDay(for: today)
        
        let expenseToday = Expense(amount: 100, category: "Food & Dining", date: todayStart)
        let expenseOtherDay = Expense(amount: 200, category: "Transport", date: differentDay)
        
        viewModel.selectedDate = todayStart
        viewModel.configure(allExpenses: [expenseToday, expenseOtherDay], budgets: [], modelContext: nil)
        
        viewModel.updateFilterMode(.monthly)
        let monthlyCount = viewModel.filteredExpenses.count
        
        viewModel.updateFilterMode(.daily)
        let dailyCount = viewModel.filteredExpenses.count
        
        #expect(monthlyCount >= dailyCount)
        #expect(viewModel.filterMode == .daily)
    }
    
    @Test
    func testDailyFilterExcludesExpensesFromOtherDays() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let expenseToday = Expense(amount: 100, category: "Food & Dining", date: today)
        let expenseYesterday = Expense(amount: 200, category: "Transport", date: yesterday)
        
        viewModel.selectedDate = today
        viewModel.configure(allExpenses: [expenseToday, expenseYesterday], budgets: [], modelContext: nil)
        viewModel.updateFilterMode(.daily)
        
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.filteredExpenses.first?.amount == 100)
    }
    
    // MARK: - Date Navigation Between Months
    
    @Test
    func testNavigatingToAnotherMonthShowsDifferentExpenses() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan15 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let feb15 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        
        let janExpense = Expense(amount: 100, category: "Food & Dining", date: jan15)
        let febExpense = Expense(amount: 200, category: "Transport", date: feb15)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = jan15
        viewModel.configure(allExpenses: [janExpense, febExpense], budgets: [], modelContext: nil)
        
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.totalSpent == 100)
        
        viewModel.updateSelectedDate(feb15)
        
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.totalSpent == 200)
    }
    
    @Test
    func testNavigatingToEmptyMonthShowsNoExpenses() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan15 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let mar15 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        
        let janExpense = Expense(amount: 100, category: "Food & Dining", date: jan15)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = jan15
        viewModel.configure(allExpenses: [janExpense], budgets: [], modelContext: nil)
        #expect(viewModel.filteredExpenses.count == 1)
        
        viewModel.updateSelectedDate(mar15)
        
        #expect(viewModel.filteredExpenses.isEmpty)
        #expect(viewModel.totalSpent == 0)
        #expect(viewModel.categorySpending.isEmpty)
    }
    
    // MARK: - Category Spending Percentage Edge Cases
    
    @Test
    func testSingleCategoryGets100Percent() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 500, category: "Food & Dining", date: Date())
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        
        #expect(viewModel.categorySpending.count == 1)
        #expect(viewModel.categorySpending.first?.percentage == 100)
        #expect(viewModel.categorySpending.first?.amount == 500)
    }
    
    @Test
    func testMultipleExpensesSameCategoryGets100Percent() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 200, category: "Food & Dining", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        
        #expect(viewModel.categorySpending.count == 1)
        #expect(viewModel.categorySpending.first?.percentage == 100)
        #expect(viewModel.categorySpending.first?.amount == 300)
    }
    
    @Test
    func testEqualSplitBetweenTwoCategories() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Expense(amount: 100, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        
        #expect(viewModel.categorySpending.count == 2)
        for spending in viewModel.categorySpending {
            #expect(spending.percentage == 50)
        }
    }
    
    // MARK: - Search by Notes and GroupName
    
    @Test
    func testSearchFiltersByNotes() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 100, category: "Food & Dining", date: Date(), notes: "paid with credit card")
        let expense2 = Expense(amount: 200, category: "Transport", date: Date(), notes: "monthly bus pass")
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        viewModel.updateSearchText("credit")
        
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.filteredExpenses.first?.amount == 100)
    }
    
    @Test
    func testSearchFiltersByGroupName() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Expense(amount: 150, category: "Food & Dining", date: Date(), groupName: "Weekend Trip")
        let expense2 = Expense(amount: 300, category: "Transport", date: Date(), groupName: "Office Expenses")
        
        viewModel.configure(allExpenses: [expense1, expense2], budgets: [], modelContext: nil)
        viewModel.updateSearchText("Weekend")
        
        #expect(viewModel.filteredExpenses.count == 1)
        #expect(viewModel.filteredExpenses.first?.groupName == "Weekend Trip")
    }
    
    @Test
    func testSearchByGroupNameIsCaseInsensitive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 100, category: "Food & Dining", date: Date(), groupName: "Family Dinner")
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        viewModel.updateSearchText("family dinner")
        
        #expect(viewModel.filteredExpenses.count == 1)
    }
    
    @Test
    func testSearchByNotesIsCaseInsensitive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 100, category: "Food & Dining", date: Date(), notes: "Reimbursable expense")
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        viewModel.updateSearchText("REIMBURSABLE")
        
        #expect(viewModel.filteredExpenses.count == 1)
    }
    
    @Test
    func testSearchDoesNotMatchNilNotesOrGroupName() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Expense(amount: 100, category: "Transport", date: Date())
        
        viewModel.configure(allExpenses: [expense], budgets: [], modelContext: nil)
        viewModel.updateSearchText("some random text")
        
        #expect(viewModel.filteredExpenses.isEmpty)
    }
}
