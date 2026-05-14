import Foundation
import SwiftUI
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct OverviewViewModelTests {
    
    @Test
    func testRecalculateWithDailyFilterReturnsSingleDayTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .daily
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 2)
    }
    
    @Test
    func testRecalculateWithMonthlyFilterReturnsMonthTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1], userBudget: nil, customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testRecalculateFiltersOutDeletedTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let activeExpense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let deletedExpense = Transaction(amount: 200, category: "Transport", date: Date())
        deletedExpense.isSoftDeleted = true
        
        viewModel.update(allTransactions: [activeExpense, deletedExpense], userBudget: nil, customCategories: [])
        
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
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        
        #expect(viewModel.totalSpent == 350)
    }
    
    @Test
    func testRecalculateWithZeroTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])
        
        #expect(viewModel.totalSpent == 0)
        #expect(viewModel.filteredTransactions.isEmpty)
    }
    
    @Test
    func testRecalculateGroupsTransactionsByCategory() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Food & Dining", date: Date())
        let expense3 = Transaction(amount: 150, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], userBudget: nil, customCategories: [])
        
        #expect(viewModel.categorySpending.count == 2)
    }
    
    @Test
    func testRecalculateCalculatesCategoryPercentages() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 75, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 25, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        
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
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        
        #expect(viewModel.categorySpending.first?.categoryName == "Food & Dining")
    }
    
    @Test
    func testSearchFiltersByCategory() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        viewModel.searchText = "Food"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchFiltersByDescription() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food", date: Date(), transactionDescription: "Lunch at restaurant")
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        viewModel.searchText = "Lunch"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchReturnsEmptyForNoMatch() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food", date: Date(), transactionDescription: "Lunch")
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        viewModel.searchText = "Dinner"
        
        #expect(viewModel.filteredTransactions.isEmpty)
    }
    
    @Test
    func testSearchIsCaseInsensitive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        viewModel.searchText = "FOOD"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testCategorySpendingEmptyWhenNoTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])
        
        #expect(viewModel.categorySpending.isEmpty)
    }
    
    @Test
    func testCurrentBudgetIsSetWhenUserBudgetHasLimit() {
        let viewModel = OverviewViewModel()
        let budget = UserBudget(limit: 5000)
        viewModel.update(allTransactions: [], userBudget: budget, customCategories: [])
        #expect(viewModel.currentBudget?.limit == 5000)
    }

    @Test
    func testCurrentBudgetIsNilWhenNoBudget() {
        let viewModel = OverviewViewModel()
        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])
        #expect(viewModel.currentBudget == nil)
    }

    @Test
    func testCurrentBudgetIsNilWhenLimitIsNil() {
        let viewModel = OverviewViewModel()
        let budget = UserBudget(limit: nil)
        viewModel.update(allTransactions: [], userBudget: budget, customCategories: [])
        #expect(viewModel.currentBudget == nil)
    }
    
    @Test
    func testUpdateSearchTextTriggersRecalculate() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        #expect(viewModel.filteredTransactions.count == 2)
        
        viewModel.searchText = "Transport"
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.category == "Transport")
        // totalSpent reflects the full month scope, not the search-narrowed result
        #expect(viewModel.totalSpent == 300)
    }
    
    @Test
    func testClearingSearchTextShowsAllTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
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
        viewModel.update(allTransactions: [expenseToday, expenseOtherDay], userBudget: nil, customCategories: [])
        
        viewModel.filterMode = .monthly
        let monthlyCount = viewModel.filteredTransactions.count
        
        viewModel.filterMode = .daily
        let dailyCount = viewModel.filteredTransactions.count
        
        #expect(monthlyCount >= dailyCount)
        #expect(viewModel.filterMode == .daily)
    }
    
    @Test
    func testDailyFilterExcludesTransactionsFromOtherDays() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let expenseToday = Transaction(amount: 100, category: "Food & Dining", date: today)
        let expenseYesterday = Transaction(amount: 200, category: "Transport", date: yesterday)
        
        viewModel.selectedDate = today
        viewModel.filterMode = .daily
        viewModel.update(allTransactions: [expenseToday, expenseYesterday], userBudget: nil, customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.amount == 100)
    }
    
    @Test
    func testNavigatingToAnotherMonthShowsDifferentTransactions() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan15 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let feb15 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        
        let janExpense = Transaction(amount: 100, category: "Food & Dining", date: jan15)
        let febExpense = Transaction(amount: 200, category: "Transport", date: feb15)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = jan15
        viewModel.update(allTransactions: [janExpense, febExpense], userBudget: nil, customCategories: [])
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.totalSpent == 100)
        
        viewModel.selectedDate = feb15
        
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.totalSpent == 200)
    }
    
    @Test
    func testNavigatingToEmptyMonthShowsNoTransactions() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        
        let jan15 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let mar15 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        
        let janExpense = Transaction(amount: 100, category: "Food & Dining", date: jan15)
        
        viewModel.filterMode = .monthly
        viewModel.selectedDate = jan15
        viewModel.update(allTransactions: [janExpense], userBudget: nil, customCategories: [])
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
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        
        #expect(viewModel.categorySpending.count == 1)
        #expect(viewModel.categorySpending.first?.percentage == 100)
        #expect(viewModel.categorySpending.first?.amount == 500)
    }
    
    @Test
    func testMultipleTransactionsSameCategoryGets100Percent() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        
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
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        
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
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
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

        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
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

        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        viewModel.searchText = "family dinner"

        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchByNotesIsCaseInsensitive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Food & Dining", date: Date(), notes: "Reimbursable expense")
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        viewModel.searchText = "REIMBURSABLE"
        
        #expect(viewModel.filteredTransactions.count == 1)
    }
    
    @Test
    func testSearchDoesNotMatchNilNotesOrGroupName() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense = Transaction(amount: 100, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        viewModel.searchText = "some random text"
        
        #expect(viewModel.filteredTransactions.isEmpty)
    }
    
    // MARK: - Resolve Category Tests
    
    @Test
    func testResolveCategoryReturnsCategoryIconAndColor() {
        let viewModel = OverviewViewModel()

        let customCategory = Category(
            key: "my-groceries",
            name: "My Groceries",
            icon: "cart.fill",
            color: "#FF0000",
            isPredefined: false,
            predefinedKey: nil
        )

        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [customCategory])

        let result = viewModel.resolveCategory("my-groceries")

        #expect(result.icon == "cart.fill")
    }

    @Test
    func testResolveCategoryReturnsPredefinedCategoryIconAndColor() {
        let viewModel = OverviewViewModel()

        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])

        let result = viewModel.resolveCategory("food-dining")

        #expect(!result.icon.isEmpty)
        #expect(result.color != .gray)
    }

    @Test
    func testResolveCategoryReturnsFallbackForUnknown() {
        let viewModel = OverviewViewModel()

        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])

        let result = viewModel.resolveCategory("unknown-category")

        #expect(result.icon == AppIcons.Category.other)
    }

    @Test
    func testResolveCategoryIgnoresHiddenCustomCategories() {
        let viewModel = OverviewViewModel()

        let hiddenCategory = Category(
            key: "hidden-cat",
            name: "Hidden Cat",
            icon: "star.fill",
            color: "#000000",
            isPredefined: false,
            predefinedKey: nil
        )
        hiddenCategory.isHidden = true

        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [hiddenCategory])

        let result = viewModel.resolveCategory("hidden-cat")

        #expect(result.icon == AppIcons.Category.other)
    }
    
    // MARK: - Ensure Budget Exists Tests
    
    @Test
    func testEnsureBudgetExistsDoesNothingWhenBudgetExists() throws {
        let viewModel = OverviewViewModel()
        let existingBudget = UserBudget(limit: 5000)
        viewModel.update(allTransactions: [], userBudget: existingBudget, customCategories: [])
        let context = ModelContext(try makeTestContainer())
        viewModel.ensureBudgetExists(defaultBudgetLimit: 5000, modelContext: context)
        // currentBudget is already set — no new row created
        #expect(viewModel.currentBudget != nil)
    }

    @Test
    func testEnsureBudgetExistsCreatesBudgetWhenNoneExists() throws {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])
        let context = ModelContext(try makeTestContainer())
        #expect(viewModel.currentBudget == nil)
        viewModel.ensureBudgetExists(defaultBudgetLimit: 5000, modelContext: context)
        let rows = (try? context.fetch(FetchDescriptor<UserBudget>())) ?? []
        #expect(rows.count == 1)
        #expect(rows.first?.limit == 5000)
    }

    @Test
    func testEnsureBudgetExistsDoesNothingWhenLimitIsZero() throws {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])
        let context = ModelContext(try makeTestContainer())
        viewModel.ensureBudgetExists(defaultBudgetLimit: 0, modelContext: context)
        let rows = (try? context.fetch(FetchDescriptor<UserBudget>())) ?? []
        #expect(rows.isEmpty)
    }
    
    // MARK: - Delete Expense Flow
    
    @Test
    func testDeleteTransactionSetsTransactionToDelete() {
        let viewModel = OverviewViewModel()
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.deleteTransaction(expense)
        
        #expect(viewModel.transactionToDelete?.amount == 100)
    }
    
    @Test
    func testCancelDeleteTransactionClearsTransactionToDelete() {
        let viewModel = OverviewViewModel()
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.deleteTransaction(expense)
        #expect(viewModel.transactionToDelete != nil)
        
        viewModel.cancelDeleteTransaction()
        #expect(viewModel.transactionToDelete == nil)
    }
    
    @Test
    func testConfirmDeleteTransactionMarksAsDeleted() {
        let viewModel = OverviewViewModel()
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        
        viewModel.deleteTransaction(expense)
        viewModel.confirmDeleteTransaction()
        
        #expect(expense.isSoftDeleted == true)
        #expect(viewModel.transactionToDelete == nil)
    }
    
    @Test
    func testConfirmDeleteTransactionDoesNothingWhenNoTransactionToDelete() {
        let viewModel = OverviewViewModel()
        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])
        
        viewModel.confirmDeleteTransaction()
        
        #expect(viewModel.transactionToDelete == nil)
    }
    
    @Test
    func testConfirmDeleteTransactionRecalculates() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
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
        let budget = UserBudget(limit: 3000)
        viewModel.filterMode = .daily
        viewModel.selectedDate = Date()
        viewModel.update(allTransactions: [], userBudget: budget, customCategories: [])
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())!.count
        let expectedDaily = 3000.0 / Double(daysInMonth)
        #expect(viewModel.dailyBudgetLimit == expectedDaily)
    }

    @Test
    func testDailyBudgetLimitIsZeroInMonthlyMode() {
        let viewModel = OverviewViewModel()
        let budget = UserBudget(limit: 3000)
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        viewModel.update(allTransactions: [], userBudget: budget, customCategories: [])
        #expect(viewModel.dailyBudgetLimit == 0)
    }
    
    // MARK: - Category Filter Tests
    
    @Test
    func testFilterByCategoryShowsOnlyMatchingTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        let expense3 = Transaction(amount: 150, category: "Food & Dining", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], userBudget: nil, customCategories: [])
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
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        
        viewModel.filterByCategory("Food & Dining")
        
        #expect(viewModel.selectedView == .daily)
    }
    
    @Test
    func testClearCategoryFilterShowsAllTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        
        let expense1 = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let expense2 = Transaction(amount: 200, category: "Transport", date: Date())
        
        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
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
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        
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
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], userBudget: nil, customCategories: [])
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
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])
        
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
        viewModel.update(allTransactions: [janFood, janTransport, febFood], userBudget: nil, customCategories: [])
        
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
        
        viewModel.update(allTransactions: [expense1, expense2, expense3], userBudget: nil, customCategories: [])
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

        viewModel.update(allTransactions: [expense1, expense2], userBudget: nil, customCategories: [])
        #expect(viewModel.filteredTransactions.count == 2)

        viewModel.selectedCategoryFilter = "Transport"

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.category == "Transport")
    }

    // MARK: - Month boundary edge cases

    @Test
    func testMonthlyFilterIncludesTransactionOnLastDayOfMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        // Last day of January 2026
        let lastDayOfJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let midJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let expense = Transaction(amount: 500, category: "Food & Dining", date: lastDayOfJan)

        viewModel.filterMode = .monthly
        viewModel.selectedDate = midJan
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.count == 1)
    }

    @Test
    func testMonthlyFilterExcludesTransactionOnFirstDayOfNextMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let firstDayOfFeb = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let midJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let expense = Transaction(amount: 500, category: "Transport", date: firstDayOfFeb)

        viewModel.filterMode = .monthly
        viewModel.selectedDate = midJan
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.isEmpty)
    }

    @Test
    func testMonthlyFilterIncludesTransactionOnFirstDayOfMonth() {
        let viewModel = OverviewViewModel()
        let calendar = Calendar.current
        let firstDayOfJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let midJan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        let expense = Transaction(amount: 300, category: "Food & Dining", date: firstDayOfJan)

        viewModel.filterMode = .monthly
        viewModel.selectedDate = midJan
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.count == 1)
    }

    // MARK: - Transaction Type Filter

    @Test
    func testTypeFilterAllShowsExpensesAndIncome() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(type: .expense, amount: 100, category: "Food", date: Date())
        let income  = Transaction(type: .income,  amount: 500, category: "Work & Professional", date: Date())

        viewModel.transactionTypeFilter = .all
        viewModel.update(allTransactions: [expense, income], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.count == 2)
    }

    @Test
    func testTypeFilterExpensesHidesIncomeTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(type: .expense, amount: 100, category: "Food", date: Date())
        let income  = Transaction(type: .income,  amount: 500, category: "Work & Professional", date: Date())

        viewModel.transactionTypeFilter = .expenses
        viewModel.update(allTransactions: [expense, income], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.type == .expense)
    }

    @Test
    func testTypeFilterIncomeHidesExpenseTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(type: .expense, amount: 100, category: "Food", date: Date())
        let income  = Transaction(type: .income,  amount: 500, category: "Work & Professional", date: Date())

        viewModel.transactionTypeFilter = .income
        viewModel.update(allTransactions: [expense, income], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.type == .income)
    }

    @Test
    func testTypeFilterExpensesWithNoExpensesReturnsEmpty() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let income = Transaction(type: .income, amount: 500, category: "Work & Professional", date: Date())

        viewModel.transactionTypeFilter = .expenses
        viewModel.update(allTransactions: [income], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.isEmpty)
    }

    @Test
    func testTypeFilterIncomeWithNoIncomeReturnsEmpty() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(type: .expense, amount: 100, category: "Food", date: Date())

        viewModel.transactionTypeFilter = .income
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])

        #expect(viewModel.filteredTransactions.isEmpty)
    }

    // MARK: - totalIncome and totalSpent are independent of type filter

    @Test
    func testTotalIncomeAndTotalSpentAreComputedBeforeTypeFilter() {
        // totalSpent and totalIncome must reflect ALL matching transactions
        // regardless of which type filter is active, so the budget card is always accurate.
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(type: .expense, amount: 200, category: "Food", date: Date())
        let income  = Transaction(type: .income,  amount: 800, category: "Work & Professional", date: Date())

        viewModel.transactionTypeFilter = .expenses  // only expenses visible in list
        viewModel.update(allTransactions: [expense, income], userBudget: nil, customCategories: [])

        // Despite the filter showing only expenses, both totals must be populated
        #expect(viewModel.totalSpent  == 200)
        #expect(viewModel.totalIncome == 800)
    }

    @Test
    func testTotalIncomeIsZeroWhenNoIncomeTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(type: .expense, amount: 150, category: "Food", date: Date())
        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])

        #expect(viewModel.totalIncome == 0)
    }

    @Test
    func testTotalIncomeSumsAllIncomeTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let salary  = Transaction(type: .income, amount: 5000, category: "Work & Professional", date: Date())
        let bonus   = Transaction(type: .income, amount: 1000, category: "Work & Professional", date: Date())
        let expense = Transaction(type: .expense, amount: 200, category: "Food", date: Date())

        viewModel.update(allTransactions: [salary, bonus, expense], userBudget: nil, customCategories: [])

        #expect(viewModel.totalIncome == 6000)
        #expect(viewModel.totalSpent  == 200)
    }

    // MARK: - netBalance

    @Test
    func testNetBalanceIsIncomeMinusSpent() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let income  = Transaction(type: .income,  amount: 3000, category: "Work & Professional", date: Date())
        let expense = Transaction(type: .expense, amount: 1200, category: "Food", date: Date())

        viewModel.update(allTransactions: [income, expense], userBudget: nil, customCategories: [])

        #expect(viewModel.netBalance == 1800)
    }

    @Test
    func testNetBalanceIsNegativeWhenSpentExceedsIncome() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()

        let expense = Transaction(type: .expense, amount: 500, category: "Food", date: Date())

        viewModel.update(allTransactions: [expense], userBudget: nil, customCategories: [])

        #expect(viewModel.netBalance == -500)
    }

    @Test
    func testNetBalanceIsZeroWithNoTransactions() {
        let viewModel = OverviewViewModel()
        viewModel.update(allTransactions: [], userBudget: nil, customCategories: [])

        #expect(viewModel.netBalance == 0)
    }

    // MARK: - categorySpending: income filter

    @Test
    func testCategorySpendingUsesIncomeWhenIncomeFilterActive() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        viewModel.transactionTypeFilter = .income

        let income1 = Transaction(type: .income, amount: 500, category: "Work & Professional", date: Date())
        let income2 = Transaction(type: .income, amount: 300, category: "Other Income", date: Date())

        viewModel.update(allTransactions: [income1, income2], userBudget: nil, customCategories: [])

        // categorySpending should reflect income categories, not expenses
        #expect(viewModel.categorySpending.count == 2)
        let workCategory = viewModel.categorySpending.first { $0.categoryName == "Work & Professional" }
        #expect(workCategory != nil)
        #expect(workCategory?.amount == 500)
    }

    @Test
    func testCategorySpendingIsEmptyWhenNoSpending() {
        let viewModel = OverviewViewModel()
        viewModel.filterMode = .monthly
        viewModel.selectedDate = Date()
        viewModel.transactionTypeFilter = .expenses

        // Only income — no expenses → totalSpent == 0 → categorySpending should be empty
        let income = Transaction(type: .income, amount: 1000, category: "Salary", date: Date())
        viewModel.update(allTransactions: [income], userBudget: nil, customCategories: [])

        #expect(viewModel.categorySpending.isEmpty)
    }
}
