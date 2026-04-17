import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct TransactionsViewModelTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeVM(transactions: [Transaction] = [], categories: [CustomCategory] = []) -> TransactionsViewModel {
        let vm = TransactionsViewModel()
        vm.update(allTransactions: transactions, customCategories: categories)
        return vm
    }

    // MARK: - Monthly filter

    @Test
    func testMonthlyFilterOnlyShowsTransactionsInSelectedMonth() {
        let calendar = Calendar.current
        let jan15 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let feb15 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 15))!

        let janExpense = Transaction(amount: 100, category: "Food", date: jan15)
        let febExpense = Transaction(amount: 200, category: "Transport", date: feb15)

        let vm = TransactionsViewModel()
        vm.selectedDate = jan15
        vm.update(allTransactions: [janExpense, febExpense], customCategories: [])

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.amount == 100)
    }

    @Test
    func testMonthlyFilterExcludesSoftDeletedTransactions() {
        let active = Transaction(amount: 100, category: "Food", date: Date())
        let deleted = Transaction(amount: 200, category: "Transport", date: Date())
        deleted.isSoftDeleted = true

        let vm = makeVM(transactions: [active, deleted])

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.amount == 100)
    }

    // MARK: - Search

    @Test
    func testSearchFiltersByCategory() {
        let food = Transaction(amount: 100, category: "Food", date: Date())
        let transport = Transaction(amount: 200, category: "Transport", date: Date())

        let vm = makeVM(transactions: [food, transport])
        vm.searchText = "Food"

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.category == "Food")
    }

    @Test
    func testSearchByCategoryIsCaseInsensitive() {
        let food = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let vm = makeVM(transactions: [food])
        vm.searchText = "food"

        #expect(vm.filteredTransactions.count == 1)
    }

    @Test
    func testSearchFiltersByDescription() {
        let lunch = Transaction(amount: 100, category: "Food", date: Date(), transactionDescription: "Lunch meeting")
        let other = Transaction(amount: 200, category: "Transport", date: Date(), transactionDescription: "Taxi")

        let vm = makeVM(transactions: [lunch, other])
        vm.searchText = "Lunch"

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.transactionDescription == "Lunch meeting")
    }

    @Test
    func testSearchFiltersByNotes() {
        let t1 = Transaction(amount: 100, category: "Food", date: Date(), notes: "with team")
        let t2 = Transaction(amount: 200, category: "Food", date: Date(), notes: "solo")

        let vm = makeVM(transactions: [t1, t2])
        vm.searchText = "team"

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.notes == "with team")
    }

    @Test
    func testClearingSearchTextRestoresAll() {
        let t1 = Transaction(amount: 100, category: "Food", date: Date())
        let t2 = Transaction(amount: 200, category: "Transport", date: Date())

        let vm = makeVM(transactions: [t1, t2])
        vm.searchText = "Food"
        #expect(vm.filteredTransactions.count == 1)

        vm.searchText = ""
        #expect(vm.filteredTransactions.count == 2)
    }

    // MARK: - Category filter

    @Test
    func testCategoryFilterNarrowsToExactMatch() {
        let t1 = Transaction(amount: 100, category: "Food", date: Date())
        let t2 = Transaction(amount: 200, category: "Transport", date: Date())
        let t3 = Transaction(amount: 300, category: "Food", date: Date())

        let vm = makeVM(transactions: [t1, t2, t3])
        vm.selectedCategoryFilter = "Food"

        #expect(vm.filteredTransactions.count == 2)
        #expect(vm.filteredTransactions.allSatisfy { $0.category == "Food" })
    }

    // MARK: - Transaction type filter

    @Test
    func testTypeFilterAllShowsBoth() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let income = Transaction(type: .income, amount: 500, category: "Work & Professional", date: Date())

        let vm = makeVM(transactions: [expense, income])
        vm.transactionTypeFilter = .all

        #expect(vm.filteredTransactions.count == 2)
    }

    @Test
    func testTypeFilterExpensesHidesIncome() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let income = Transaction(type: .income, amount: 500, category: "Work & Professional", date: Date())

        let vm = makeVM(transactions: [expense, income])
        vm.transactionTypeFilter = .expenses

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.type == .expense)
    }

    @Test
    func testTypeFilterIncomeHidesExpenses() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let income = Transaction(type: .income, amount: 500, category: "Work & Professional", date: Date())

        let vm = makeVM(transactions: [expense, income])
        vm.transactionTypeFilter = .income

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.type == .income)
    }

    // MARK: - Delete flow

    @Test
    func testDeleteTransactionSetsConfirmingState() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let vm = makeVM(transactions: [expense])

        vm.deleteTransaction(expense)

        #expect(vm.transactionToDelete === expense)
        #expect(vm.isConfirmingDelete == true)
    }

    @Test
    func testCancelDeleteClearsStateWithoutSoftDeleting() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let vm = makeVM(transactions: [expense])

        vm.deleteTransaction(expense)
        vm.cancelDeleteTransaction()

        #expect(vm.transactionToDelete == nil)
        #expect(vm.isConfirmingDelete == false)
        #expect(expense.isSoftDeleted == false)
    }

    @Test
    func testConfirmDeleteSoftDeletesAndRemovesFromFiltered() throws {
        let context = try makeContext()
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        context.insert(expense)
        try context.save()

        let vm = TransactionsViewModel()
        vm.modelContext = context
        vm.update(allTransactions: [expense], customCategories: [])

        vm.deleteTransaction(expense)
        vm.confirmDeleteTransaction()

        #expect(expense.isSoftDeleted == true)
        #expect(vm.transactionToDelete == nil)
        #expect(vm.isConfirmingDelete == false)
        #expect(vm.filteredTransactions.isEmpty)
    }

    @Test
    func testConfirmDeleteWithNilTransactionToDeleteDoesNothing() {
        let vm = makeVM()
        vm.confirmDeleteTransaction()

        #expect(vm.isConfirmingDelete == false)
        #expect(vm.filteredTransactions.isEmpty)
    }

    // MARK: - Combined filters

    @Test
    func testCombinedSearchAndTypeFilterNarrowsResults() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let income = Transaction(type: .income, amount: 500, category: "Food", date: Date())
        let other = Transaction(amount: 200, category: "Transport", date: Date())

        let vm = makeVM(transactions: [expense, income, other])
        vm.searchText = "Food"
        vm.transactionTypeFilter = .expenses

        // Should only return the expense with category "Food"
        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.type == .expense)
    }

    @Test
    func testClearingCategoryFilterRestoresAll() {
        let food = Transaction(amount: 100, category: "Food", date: Date())
        let transport = Transaction(amount: 200, category: "Transport", date: Date())

        let vm = makeVM(transactions: [food, transport])
        vm.selectedCategoryFilter = "Food"
        #expect(vm.filteredTransactions.count == 1)

        vm.selectedCategoryFilter = nil
        #expect(vm.filteredTransactions.count == 2)
    }

    @Test
    func testTransactionTypeFilterDidSetTriggersRecalculate() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let income = Transaction(type: .income, amount: 500, category: "Salary", date: Date())

        let vm = makeVM(transactions: [expense, income])
        #expect(vm.filteredTransactions.count == 2)

        vm.transactionTypeFilter = .income
        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.type == .income)
    }

    @Test
    func testSelectedDateDidSetReFilters() {
        let calendar = Calendar.current
        let jan = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let feb = calendar.date(from: DateComponents(year: 2024, month: 2, day: 15))!

        let janExpense = Transaction(amount: 100, category: "Food", date: jan)
        let febExpense = Transaction(amount: 200, category: "Food", date: feb)

        let vm = TransactionsViewModel()
        vm.selectedDate = jan
        vm.update(allTransactions: [janExpense, febExpense], customCategories: [])

        #expect(vm.filteredTransactions.count == 1)

        vm.selectedDate = feb
        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.amount == 200)
    }

    @Test
    func testSearchAndCategoryFilterCombined() {
        let food1 = Transaction(amount: 100, category: "Food", date: Date(), transactionDescription: "Lunch")
        let food2 = Transaction(amount: 200, category: "Food", date: Date(), transactionDescription: "Dinner")
        let transport = Transaction(amount: 50, category: "Transport", date: Date())

        let vm = makeVM(transactions: [food1, food2, transport])
        vm.selectedCategoryFilter = "Food"
        vm.searchText = "Lunch"

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.transactionDescription == "Lunch")
    }
}
