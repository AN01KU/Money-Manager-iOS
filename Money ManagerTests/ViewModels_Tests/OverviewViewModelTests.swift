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
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 2)
    }
    
    @Test
    func testRecalculateWithMonthlyFilterReturnsMonthExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1], budgets: [], customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testRecalculateFiltersOutDeletedExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let activeExpense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let deletedExpense = Transaction(amount: 200, category: "Transport", date: Date())
        deletedExpense.isDeleted = true
        
        viewModel.update(allTransactions: [activeExpense, deletedExpense], budgets: [], customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.amount == 100)
    }
    
    @Test
    func testRecalculateCalculatesTotalSpentCorrectly() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 250, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        
        #expect(viewModel.totalSpent == 350)
    }
    
    @Test
    func testRecalculateWithZeroExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [])
        
        #expect(viewModel.totalSpent == 0)
        #expect(viewModel.filteredTransactions.isEmpty)
    }
    
    @Test
    func testRecalculateGroupsExpensesByCategory() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Food & Dining", date: Date())
        let expense3 = Transaction(amount: 150, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], budgets: [], customCategories: [])
        
        #expect(viewModel.categorySpending.count == 2)
    }
    
    @Test
    func testRecalculateCalculatesCategoryPercentages() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 75, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 25, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        
        let foodCategory = viewModel.categorySpending.first { $0.categoryName == "Food & Dining" }
        #expect(foodCategory?.percentage == 75)
    }
    
    @Test
    func testRecalculateCategoriesSortedByAmount() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Transport", date: Date())
        let expense2 = Transaction(amount: 500, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        
        #expect(viewModel.categorySpending.first?.categoryName == "Food & Dining")
    }
    
    @Test
    func testSearchFiltersByCategory() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        viewModel.searchText = "Food"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchFiltersByDescription() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food", date: Date(), transactionDescription: "Lunch at restaurant")
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        viewModel.searchText = "Lunch"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchReturnsEmptyForNoMatch() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food", date: Date(), transactionDescription: "Lunch")
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        viewModel.searchText = "Dinner"
        
        #expect(viewModel.filteredTransactions.isEmpty)
    }
    
    @Test
    func testSearchIsCaseInsensitive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        viewModel.searchText = "FOOD"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testCategorySpendingEmptyWhenNoExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [])
        
        #expect(viewModel.categorySpending.isEmpty)
    }
    
    @Test
    func testCurrentBudgetMatchesSelectedMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        
        let matchingBudget = MonthlyBudget(year: year, month: month, limit: 5000)
        let otherBudget = MonthlyBudget(year: year, month: month == 12 ? 1 : month + 1, limit: 3000)
        
        viewModel.update(allTransactions: [], budgets: [matchingBudget, otherBudget], customCategories: [])
        
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
        
        viewModel.update(allTransactions: [], budgets: [otherBudget], customCategories: [])
        
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
        viewModel.update(allTransactions: [], budgets: [janBudget, febBudget], customCategories: [])
        #expect(viewModel.currentBudget?.limit == 4000)
        
        viewModel.selectedDate = feb2026
        #expect(viewModel.currentBudget?.limit == 6000)
    }
    
    @Test
    func testUpdateSearchTextTriggersRecalculate() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        #expect(viewModel.filteredTransactions.count == 2)
        
        viewModel.searchText = "Transport"
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.category == "Transport")
        #expect(viewModel.totalSpent == 200)
    }
    
    @Test
    func testClearingSearchTextShowsAllExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        viewModel.searchText = "Food"
        #expect(viewModel.filteredTransactions.count == 1)
        
        viewModel.searchText = ""
        #expect(viewModel.filteredTransactions.count == 2)
        #expect(viewModel.totalSpent == 300)
    }
    
    @Test
    func testSwitchingFromMonthlyToDailyNarrowsResults() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let differentDay = calendar.date(byAdding: .day, value: 5, to: startOfMonth)!
        let todayStart = calendar.startOfDay(for: today)
        
        let expenseToday = Transaction(amount: 100, category: "Food & Dining", date: todayStart)
        let expenseOtherDay = Transaction(amount: 200, category: "Transport", date: differentDay)
        
        viewModel.selectedDate = todayStart
        viewModel.update(allTransactions: [expenseToday, expenseOtherDay], budgets: [], customCategories: [])
        
        viewModel.filterMode = .monthly
        let monthlyCount = viewModel.filteredTransactions.count
        
        viewModel.filterMode = .daily
        let dailyCount = viewModel.filteredTransactions.count
        
        #expect(monthlyCount >= dailyCount)
        #expect(viewModel.filterMode == .daily)
    }
    
    @Test
    func testDailyFilterExcludesExpensesFromOtherDays() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let expenseToday = Transaction(amount: 100, category: "Food & Dining", date: today)
        let expenseYesterday = Transaction(amount: 200, category: "Transport", date: yesterday)
        
        viewModel.selectedDate = today
        viewModel.filterMode = .daily
        viewModel.update(allTransactions: [expenseToday, expenseYesterday], budgets: [], customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.amount == 100)
    }
    
    @Test
    func testNavigatingToAnotherMonthShowsDifferentExpenses() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan15 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let feb15 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        
        let janExpense = Transaction(amount: 100, category: "Food & Dining", date: jan15)
        let febExpense = Transaction(amount: 200, category: "Transport", date: feb15)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = jan15
        viewModel.update(allTransactions: [janExpense, febExpense], budgets: [], customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.totalSpent == 100)
        
        viewModel.selectedDate = feb15
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.totalSpent == 200)
    }
    
    @Test
    func testNavigatingToEmptyMonthShowsNoExpenses() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan15 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let mar15 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        
        let janExpense = Transaction(amount: 100, category: "Food & Dining", date: jan15)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = jan15
        viewModel.update(allTransactions: [janExpense], budgets: [], customCategories: [])
        #expect(viewModel.filteredTransactions.count == 1)
        
        viewModel.selectedDate = mar15
        
        #expect(viewModel.filteredTransactions.isEmpty)
        #expect(viewModel.totalSpent == 0)
        #expect(viewModel.categorySpending.isEmpty)
    }
    
    @Test
    func testSingleCategoryGets100Percent() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 500, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        
        #expect(viewModel.categorySpending.count == 1)
        #expect(viewModel.categorySpending.first?.percentage == 100)
        #expect(viewModel.categorySpending.first?.amount == 500)
    }
    
    @Test
    func testMultipleExpensesSameCategoryGets100Percent() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        
        #expect(viewModel.categorySpending.count == 1)
        #expect(viewModel.categorySpending.first?.percentage == 100)
        #expect(viewModel.categorySpending.first?.amount == 300)
    }
    
    @Test
    func testEqualSplitBetweenTwoCategories() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 100, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        
        #expect(viewModel.categorySpending.count == 2)
        for spending in viewModel.categorySpending {
            #expect(spending.percentage == 50)
        }
    }
    
    @Test
    func testSearchFiltersByNotes() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date(), notes: "paid with credit card")
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date(), notes: "monthly bus pass")
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        viewModel.searchText = "credit"
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.amount == 100)
    }
    
    @Test
    func testSearchFiltersByNotes2() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense1 = Transaction(amount: 150, category: "Food & Dining", date: Date(), notes: "Weekend Trip")
        let expense2 = Transaction(amount: 300, category: "Transport", date: Date(), notes: "Office Expenses")

        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        viewModel.searchText = "Weekend"

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.notes == "Weekend Trip")
    }

    @Test
    func testSearchByNotesIsCaseInsensitive2() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date(), notes: "Family Dinner")

        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        viewModel.searchText = "family dinner"

        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchByNotesIsCaseInsensitive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date(), notes: "Reimbursable expense")
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        viewModel.searchText = "REIMBURSABLE"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchDoesNotMatchNilNotesOrGroupName() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        viewModel.searchText = "some random text"
        
        #expect(viewModel.filteredTransactions.isEmpty)
    }
    
    // MARK: - Resolve Category Tests
    
    @Test
    func testResolveCategoryReturnsCustomCategoryIconAndColor() {
        let viewModel = OverviewViewModel()
        
        let customCategory = CustomCategory(
            name: "My Groceries",
            icon: "cart.fill",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [customCategory])
        
        let result = viewModel.resolveCategory("My Groceries")
        
        #expect(result.icon == "cart.fill")
    }
    
    @Test
    func testResolveCategoryReturnsPredefinedCategoryIconAndColor() {
        let viewModel = OverviewViewModel()
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [])
        
        let result = viewModel.resolveCategory("Food & Dining")
        
        #expect(!result.icon.isEmpty)
    }
    
    @Test
    func testResolveCategoryReturnsFallbackForUnknown() {
        let viewModel = OverviewViewModel()
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [])
        
        let result = viewModel.resolveCategory("Unknown Category")
        
        #expect(result.icon == "ellipsis.circle.fill")
    }
    
    @Test
    func testResolveCategoryIgnoresHiddenCustomCategories() {
        let viewModel = OverviewViewModel()
        
        let hiddenCategory = CustomCategory(
            name: "Hidden Cat",
            icon: "star.fill",
            color: "#000000",
            isPredefined: false,
            predefinedKey: nil
        )
        hiddenCategory.isHidden = true
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [hiddenCategory])
        
        let result = viewModel.resolveCategory("Hidden Cat")
        
        #expect(result.icon == "ellipsis.circle.fill")
    }
    
    // MARK: - Ensure Budget Exists Tests
    
    @Test
    func testEnsureBudgetExistsDoesNothingWhenBudgetExists() {
        let viewModel = OverviewViewModel()
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        let existingBudget = MonthlyBudget(year: year, month: month, limit: 5000)
        
        viewModel.update(allTransactions: [], budgets: [existingBudget], customCategories: [])
        
        let initialCount = viewModel.currentBudget != nil ? 1 : 0
        
        let schema = Schema([Transaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        
        viewModel.ensureBudgetExists(defaultBudgetLimit: 5000, modelContext: context)
        
        #expect(viewModel.currentBudget != nil)
    }
    
    @Test
    func testEnsureBudgetExistsCreatesBudgetWhenNoneExists() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [])
        
        let schema = Schema([Transaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        
        #expect(viewModel.currentBudget == nil)
        
        viewModel.ensureBudgetExists(defaultBudgetLimit: 5000, modelContext: context)
        
        let descriptor = FetchDescriptor<MonthlyBudget>()
        let budgets = (try? context.fetch(descriptor)) ?? []
        #expect(budgets.count == 1)
    }
    
    @Test
    func testEnsureBudgetExistsDoesNothingWhenLimitIsZero() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.update(allTransactions: [], budgets: [], customCategories: [])
        
        let schema = Schema([Transaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)
        
        viewModel.ensureBudgetExists(defaultBudgetLimit: 0, modelContext: context)
        
        let descriptor = FetchDescriptor<MonthlyBudget>()
        let budgets = (try? context.fetch(descriptor)) ?? []
        #expect(budgets.isEmpty)
    }
    
    // MARK: - Delete Expense Flow
    
    @Test
    func testDeleteExpenseSetsExpenseToDelete() {
        let viewModel = OverviewViewModel()
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.deleteTransaction(expense)
        
        #expect(viewModel.transactionToDelete?.amount == 100)
    }
    
    @Test
    func testCancelDeleteExpenseClearsExpenseToDelete() {
        let viewModel = OverviewViewModel()
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.deleteTransaction(expense)
        #expect(viewModel.transactionToDelete != nil)
        
        viewModel.cancelDeleteTransaction()
        #expect(viewModel.transactionToDelete == nil)
    }
    
    @Test
    func testConfirmDeleteExpenseMarksAsDeleted() {
        let viewModel = OverviewViewModel()
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        
        viewModel.deleteTransaction(expense)
        viewModel.confirmDeleteTransaction()
        
        #expect(expense.isDeleted == true)
        #expect(viewModel.transactionToDelete == nil)
    }
    
    @Test
    func testConfirmDeleteExpenseDoesNothingWhenNoExpenseToDelete() {
        let viewModel = OverviewViewModel()
        viewModel.update(allTransactions: [], budgets: [], customCategories: [])
        
        viewModel.confirmDeleteTransaction()
        
        #expect(viewModel.transactionToDelete == nil)
    }
    
    @Test
    func testConfirmDeleteExpenseRecalculates() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        #expect(viewModel.totalSpent == 300)
        
        viewModel.deleteTransaction(expense1)
        viewModel.confirmDeleteTransaction()
        
        #expect(viewModel.totalSpent == 200)
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    // MARK: - Daily Budget Limit
    
    @Test
    func testDailyBudgetLimitCalculatedInDailyMode() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        
        let budget = MonthlyBudget(year: year, month: month, limit: 3000)
        
        viewModel.filterMode = .daily
        viewModel.selectedDate = Date()
        viewModel.update(allTransactions: [], budgets: [budget], customCategories: [])
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())!.count
        let expectedDaily = 3000.0 / Double(daysInMonth)
        
        #expect(viewModel.dailyBudgetLimit == expectedDaily)
    }
    
    @Test
    func testDailyBudgetLimitIsZeroInMonthlyMode() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        
        let budget = MonthlyBudget(year: year, month: month, limit: 3000)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        viewModel.update(allTransactions: [], budgets: [budget], customCategories: [])
        
        #expect(viewModel.dailyBudgetLimit == 0)
    }
    
    // MARK: - Category Filter Tests
    
    @Test
    func testFilterByCategoryShowsOnlyMatchingExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        let expense3 = Transaction(amount: 150, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], budgets: [], customCategories: [])
        viewModel.filterByCategory("Food & Dining")
        
        #expect(viewModel.filteredTransactions.count == 2)
        #expect(viewModel.filteredTransactions.allSatisfy { $0.category == "Food & Dining" })
        #expect(viewModel.totalSpent == 250)
    }
    
    @Test
    func testFilterByCategorySwitchesToDailyView() {
        let viewModel = OverviewViewModel()
        viewModel.selectedView = .categories
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        
        viewModel.filterByCategory("Food & Dining")
        
        #expect(viewModel.selectedView == .daily)
    }
    
    @Test
    func testClearCategoryFilterShowsAllExpenses() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        viewModel.filterByCategory("Food & Dining")
        #expect(viewModel.filteredTransactions.count == 1)
        
        viewModel.clearCategoryFilter()
        
        #expect(viewModel.filteredTransactions.count == 2)
        #expect(viewModel.totalSpent == 300)
    }
    
    @Test
    func testClearCategoryFilterSwitchesToCategoriesView() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        
        viewModel.filterByCategory("Food & Dining")
        #expect(viewModel.selectedView == .daily)
        
        viewModel.clearCategoryFilter()
        
        #expect(viewModel.selectedView == .categories)
        #expect(viewModel.selectedCategoryFilter == nil)
    }
    
    @Test
    func testCategoryFilterCombinesWithSearchText() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date(), transactionDescription: "Lunch")
        let expense2 = Transaction(amount: 200, category: "Food & Dining", date: Date(), transactionDescription: "Dinner")
        let expense3 = Transaction(amount: 300, category: "Transport", date: Date(), transactionDescription: "Lunch ride")
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], budgets: [], customCategories: [])
        viewModel.filterByCategory("Food & Dining")
        viewModel.searchText = "Lunch"
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.transactionDescription == "Lunch")
    }
    
    @Test
    func testCategoryFilterReturnsEmptyForNonExistentCategory() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])
        
        viewModel.filterByCategory("Entertainment")
        
        #expect(viewModel.filteredTransactions.isEmpty)
        #expect(viewModel.totalSpent == 0)
    }
    
    @Test
    func testCategoryFilterPersistsAcrossDateChanges() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan15 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let feb15 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        
        let janFood = Transaction(amount: 100, category: "Food & Dining", date: jan15)
        let janTransport = Transaction(amount: 200, category: "Transport", date: jan15)
        let febFood = Transaction(amount: 300, category: "Food & Dining", date: feb15)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = jan15
        viewModel.update(allTransactions: [janFood, janTransport, febFood], budgets: [], customCategories: [])
        
        viewModel.filterByCategory("Food & Dining")
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.totalSpent == 100)
        
        viewModel.selectedDate = feb15
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.totalSpent == 300)
        #expect(viewModel.selectedCategoryFilter == "Food & Dining")
    }
    
    @Test
    func testCategoryFilterUpdatedTotalSpent() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        let expense3 = Transaction(amount: 50, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], budgets: [], customCategories: [])
        #expect(viewModel.totalSpent == 350)
        
        viewModel.filterByCategory("Food & Dining")
        #expect(viewModel.totalSpent == 150)
    }
    
    @Test
    func testSettingCategoryFilterDirectlyTriggersRecalculate() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())

        viewModel.update(allTransactions: [expense1, expense2], budgets: [], customCategories: [])
        #expect(viewModel.filteredTransactions.count == 2)

        viewModel.selectedCategoryFilter = "Transport"

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.category == "Transport")
    }

    // MARK: - Month boundary edge cases

    @Test
    func testMonthlyFilterIncludesExpenseOnLastDayOfMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        // Last day of January 2026
        let lastDayOfJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let midJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let expense = Transaction(amount: 500, category: "Food & Dining", date: lastDayOfJan)

        viewModel.filterMode = .monthly
        viewModel.selectedDate = midJan
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])

        #expect(viewModel.filteredTransactions.count == 1)
    }

    @Test
    func testMonthlyFilterExcludesExpenseOnFirstDayOfNextMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let firstDayOfFeb = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let midJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let expense = Transaction(amount: 500, category: "Transport", date: firstDayOfFeb)

        viewModel.filterMode = .monthly
        viewModel.selectedDate = midJan
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])

        #expect(viewModel.filteredTransactions.isEmpty)
    }

    @Test
    func testMonthlyFilterIncludesExpenseOnFirstDayOfMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let firstDayOfJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let midJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let expense = Transaction(amount: 300, category: "Food & Dining", date: firstDayOfJan)

        viewModel.filterMode = .monthly
        viewModel.selectedDate = midJan
        viewModel.update(allTransactions: [expense], budgets: [], customCategories: [])

        #expect(viewModel.filteredTransactions.count == 1)
    }
}
