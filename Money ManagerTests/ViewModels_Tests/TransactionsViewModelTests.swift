import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct TransactionsViewModelTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeVM(transactions: [Transaction] = [], categories: [Money_Manager.Category] = []) -> TransactionsViewModel {
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

        let janExpense = Transaction(amount: 100, categoryId: UUID(), date: jan15)
        let febExpense = Transaction(amount: 200, categoryId: UUID(), date: feb15)

        let vm = TransactionsViewModel()
        vm.selectedDate = jan15
        vm.update(allTransactions: [janExpense, febExpense], customCategories: [])

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.amount == 100)
    }

    @Test
    func testMonthlyFilterExcludesSoftDeletedTransactions() {
        let active = Transaction(amount: 100, categoryId: UUID(), date: Date())
        let deleted = Transaction(amount: 200, categoryId: UUID(), date: Date())
        deleted.isSoftDeleted = true

        let vm = makeVM(transactions: [active, deleted])

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.amount == 100)
    }

    // MARK: - Search

    @Test
    func testSearchFiltersByCategory() {
        let foodCat = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let food = Transaction(amount: 100, categoryId: foodCat.id, date: Date())
        let transport = Transaction(amount: 200, categoryId: UUID(), date: Date())

        let vm = makeVM(transactions: [food, transport], categories: [foodCat])
        vm.searchText = "Food"

        #expect(vm.filteredTransactions.count == 1)
    }

    @Test
    func testSearchByCategoryIsCaseInsensitive() {
        let foodCat = Category(name: "Food", icon: "fork.knife", color: "#FF0000")
        let food = Transaction(amount: 100, categoryId: foodCat.id, date: Date())
        let vm = makeVM(transactions: [food], categories: [foodCat])
        vm.searchText = "food"

        #expect(vm.filteredTransactions.count == 1)
    }

    @Test
    func testSearchFiltersByDescription() {
        let lunch = Transaction(amount: 100, categoryId: UUID(), date: Date(), transactionDescription: "Lunch meeting")
        let other = Transaction(amount: 200, categoryId: UUID(), date: Date(), transactionDescription: "Taxi")

        let vm = makeVM(transactions: [lunch, other])
        vm.searchText = "Lunch"

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.transactionDescription == "Lunch meeting")
    }

    @Test
    func testSearchFiltersByNotes() {
        let t1 = Transaction(amount: 100, categoryId: UUID(), date: Date(), notes: "with team")
        let t2 = Transaction(amount: 200, categoryId: UUID(), date: Date(), notes: "solo")

        let vm = makeVM(transactions: [t1, t2])
        vm.searchText = "team"

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.notes == "with team")
    }

    @Test
    func testClearingSearchTextRestoresAll() {
        let t1 = Transaction(amount: 100, categoryId: UUID(), date: Date(), transactionDescription: "Lunch")
        let t2 = Transaction(amount: 200, categoryId: UUID(), date: Date(), transactionDescription: "Taxi")

        let vm = makeVM(transactions: [t1, t2])
        vm.searchText = "Lunch"
        #expect(vm.filteredTransactions.count == 1)

        vm.searchText = ""
        #expect(vm.filteredTransactions.count == 2)
    }

    // MARK: - Category filter

    @Test
    func testCategoryFilterNarrowsToExactMatch() {
        let foodId = UUID()
        let t1 = Transaction(amount: 100, categoryId: foodId, date: Date())
        let t2 = Transaction(amount: 200, categoryId: foodId, date: Date())
        let t3 = Transaction(amount: 300, categoryId: UUID(), date: Date())

        let vm = makeVM(transactions: [t1, t2, t3])
        vm.selectedCategoryFilter = foodId

        #expect(vm.filteredTransactions.count == 2)
    }

    // MARK: - Transaction type filter

    @Test
    func testTypeFilterAllShowsBoth() {
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date())
        let income = Transaction(type: .income, amount: 500, categoryId: UUID(), date: Date())

        let vm = makeVM(transactions: [expense, income])
        vm.transactionTypeFilter = .all

        #expect(vm.filteredTransactions.count == 2)
    }

    @Test
    func testTypeFilterExpensesHidesIncome() {
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date())
        let income = Transaction(type: .income, amount: 500, categoryId: UUID(), date: Date())

        let vm = makeVM(transactions: [expense, income])
        vm.transactionTypeFilter = .expenses

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.type == .expense)
    }

    @Test
    func testTypeFilterIncomeHidesExpenses() {
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date())
        let income = Transaction(type: .income, amount: 500, categoryId: UUID(), date: Date())

        let vm = makeVM(transactions: [expense, income])
        vm.transactionTypeFilter = .income

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.type == .income)
    }

    // MARK: - Delete flow

    @Test
    func testDeleteTransactionSetsConfirmingState() {
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date())
        let vm = makeVM(transactions: [expense])

        vm.deleteTransaction(expense)

        #expect(vm.transactionToDelete === expense)
        #expect(vm.isConfirmingDelete == true)
    }

    @Test
    func testCancelDeleteClearsStateWithoutSoftDeleting() {
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date())
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
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date())
        context.insert(expense)
        try context.save()

        let persistence = PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
        let vm = TransactionsViewModel(persistence: persistence)
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
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date(), transactionDescription: "Grocery run")
        let income = Transaction(type: .income, amount: 500, categoryId: UUID(), date: Date(), transactionDescription: "Grocery reimbursement")
        let other = Transaction(amount: 200, categoryId: UUID(), date: Date(), transactionDescription: "Taxi")

        let vm = makeVM(transactions: [expense, income, other])
        vm.searchText = "Grocery"
        vm.transactionTypeFilter = .expenses

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.type == .expense)
    }

    @Test
    func testClearingCategoryFilterRestoresAll() {
        let foodId = UUID()
        let food = Transaction(amount: 100, categoryId: foodId, date: Date())
        let transport = Transaction(amount: 200, categoryId: UUID(), date: Date())

        let vm = makeVM(transactions: [food, transport])
        vm.selectedCategoryFilter = foodId
        #expect(vm.filteredTransactions.count == 1)

        vm.selectedCategoryFilter = nil
        #expect(vm.filteredTransactions.count == 2)
    }

    @Test
    func testTransactionTypeFilterDidSetTriggersRecalculate() {
        let expense = Transaction(amount: 100, categoryId: UUID(), date: Date())
        let income = Transaction(type: .income, amount: 500, categoryId: UUID(), date: Date())

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

        let janExpense = Transaction(amount: 100, categoryId: UUID(), date: jan)
        let febExpense = Transaction(amount: 200, categoryId: UUID(), date: feb)

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
        let foodId = UUID()
        let food1 = Transaction(amount: 100, categoryId: foodId, date: Date(), transactionDescription: "Lunch")
        let food2 = Transaction(amount: 200, categoryId: foodId, date: Date(), transactionDescription: "Dinner")
        let transport = Transaction(amount: 50, categoryId: UUID(), date: Date())

        let vm = makeVM(transactions: [food1, food2, transport])
        vm.selectedCategoryFilter = foodId
        vm.searchText = "Lunch"

        #expect(vm.filteredTransactions.count == 1)
        #expect(vm.filteredTransactions.first?.transactionDescription == "Lunch")
    }
}
