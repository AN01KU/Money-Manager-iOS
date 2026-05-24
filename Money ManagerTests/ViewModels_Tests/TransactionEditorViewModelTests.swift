import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct TransactionEditorViewModelTests {

    private func makePersistence() throws -> PersistenceService {
        let context = ModelContext(try makeTestContainer())
        return PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
    }

    // MARK: - Initial state

    @Test
    func testCreateModeStartsEmpty() {
        let vm = TransactionEditorViewModel(mode: .create)
        #expect(vm.amountText.isEmpty)
        #expect(vm.selectedCategory == "other")
        #expect(vm.description.isEmpty)
        #expect(vm.transactionType == .expense)
    }

    @Test
    func testViewModePopulatesFromTransaction() {
        let tx = Transaction(type: .income, amount: 1234.50, category: "food-dining", date: Date(),
                             transactionDescription: "Lunch", notes: "With team")
        let vm = TransactionEditorViewModel(mode: .view(tx))
        #expect(vm.amountText == "1234.50")
        #expect(vm.selectedCategory == "food-dining")
        #expect(vm.description == "Lunch")
        #expect(vm.notes == "With team")
        #expect(vm.transactionType == .income)
    }

    @Test
    func testEditModePopulatesFromTransaction() {
        let tx = Transaction(amount: 99, category: "transport", date: Date())
        let vm = TransactionEditorViewModel(mode: .edit(tx))
        #expect(vm.amountText == "99")
        #expect(vm.selectedCategory == "transport")
    }

    // MARK: - canSave

    @Test
    func testCanSaveFalseWhenAmountEmpty() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.amountText = ""
        #expect(vm.canSave == false)
    }

    @Test
    func testCanSaveFalseWhenAmountZero() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.amountText = "0"
        #expect(vm.canSave == false)
    }

    @Test
    func testCanSaveTrueWithPositiveAmount() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.amountText = "50"
        #expect(vm.canSave == true)
    }

    @Test
    func testCanSaveFalseInViewMode() {
        let tx = Transaction(amount: 50, category: "other", date: Date())
        let vm = TransactionEditorViewModel(mode: .view(tx))
        vm.amountText = "100"
        #expect(vm.canSave == false)
    }

    // MARK: - typeLabel

    @Test
    func testTypeLabelExpense() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.transactionType = .expense
        #expect(vm.typeLabel == "Expense")
    }

    @Test
    func testTypeLabelIncome() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.transactionType = .income
        #expect(vm.typeLabel == "Income")
    }

    // MARK: - dateLabel

    @Test
    func testDateLabelWithoutTime() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.hasTime = false
        let expected = vm.selectedDate.formatted(date: .abbreviated, time: .omitted)
        #expect(vm.dateLabel == expected)
    }

    @Test
    func testDateLabelWithTime() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.hasTime = true
        // dateLabel should contain both date and time parts
        let datePart = vm.selectedDate.formatted(date: .abbreviated, time: .omitted)
        let timePart = vm.selectedTime.formatted(date: .omitted, time: .shortened)
        #expect(vm.dateLabel.contains(datePart))
        #expect(vm.dateLabel.contains(timePart))
    }

    // MARK: - signedAmountString

    @Test
    func testSignedAmountStringExpenseIsNegative() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.transactionType = .expense
        vm.amountText = "100"
        #expect(vm.signedAmountString.hasPrefix("-"))
    }

    @Test
    func testSignedAmountStringIncomeIsPositive() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.transactionType = .income
        vm.amountText = "200"
        #expect(vm.signedAmountString.hasPrefix("+"))
    }

    @Test
    func testSignedAmountStringEmptyWhenAmountUnparseable() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.amountText = "abc"
        #expect(vm.signedAmountString.isEmpty)
    }

    // MARK: - save (create mode)

    @Test
    func testSaveCreateInsertsTransaction() throws {
        let persistence = try makePersistence()
        let vm = TransactionEditorViewModel(mode: .create, persistence: persistence)
        vm.amountText = "150"
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.hasTime = false

        var didComplete = false
        vm.save { didComplete = true }

        #expect(didComplete)
        #expect(vm.errorMessage == nil)

        let ctx = persistence.modelContext
        let all = try ctx.fetch(FetchDescriptor<Transaction>())
        #expect(all.count == 1)
        #expect(all[0].amount == 150)
        #expect(all[0].category == "food-dining")
    }

    @Test
    func testSaveCreateDoesNothingWithZeroAmount() {
        let vm = TransactionEditorViewModel(mode: .create)
        vm.amountText = "0"

        var didComplete = false
        vm.save { didComplete = true }

        #expect(!didComplete)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - save (edit mode)

    @Test
    func testSaveEditUpdatesTransaction() throws {
        let persistence = try makePersistence()
        let tx = Transaction(amount: 50, category: "transport", date: Date())
        persistence.modelContext.insert(tx)

        let vm = TransactionEditorViewModel(mode: .edit(tx), persistence: persistence)
        vm.amountText = "200"
        vm.selectedCategory = "food-dining"

        var didComplete = false
        vm.save { didComplete = true }

        #expect(didComplete)
        #expect(tx.amount == 200)
        #expect(tx.category == "food-dining")
    }

    // MARK: - save (view mode — no-op)

    @Test
    func testSaveInViewModeDoesNothing() throws {
        let persistence = try makePersistence()
        let tx = Transaction(amount: 50, category: "other", date: Date())
        persistence.modelContext.insert(tx)

        let vm = TransactionEditorViewModel(mode: .view(tx), persistence: persistence)
        vm.amountText = "999"

        var didComplete = false
        vm.save { didComplete = true }

        // view mode: canSave is false, so save exits early
        #expect(!didComplete)
    }

    // MARK: - delete

    @Test
    func testDeleteSoftDeletesTransaction() throws {
        let persistence = try makePersistence()
        let tx = Transaction(amount: 50, category: "other", date: Date())
        persistence.modelContext.insert(tx)

        let vm = TransactionEditorViewModel(mode: .edit(tx), persistence: persistence)

        var didComplete = false
        vm.delete { didComplete = true }

        #expect(didComplete)
        #expect(tx.isSoftDeleted)
    }

    @Test
    func testDeleteInCreateModeIsNoop() {
        let vm = TransactionEditorViewModel(mode: .create)
        var didComplete = false
        vm.delete { didComplete = true }
        #expect(!didComplete)
    }

    // MARK: - hasTime propagates to saved transaction

    @Test
    func testSaveWithHasTimeFalseStoresNilTime() throws {
        let persistence = try makePersistence()
        let vm = TransactionEditorViewModel(mode: .create, persistence: persistence)
        vm.amountText = "75"
        vm.hasTime = false

        vm.save { }

        let all = try persistence.modelContext.fetch(FetchDescriptor<Transaction>())
        #expect(all.first?.time == nil)
    }

    @Test
    func testSaveWithHasTimeTrueStoresTime() throws {
        let persistence = try makePersistence()
        let vm = TransactionEditorViewModel(mode: .create, persistence: persistence)
        vm.amountText = "75"
        vm.hasTime = true

        vm.save { }

        let all = try persistence.modelContext.fetch(FetchDescriptor<Transaction>())
        #expect(all.first?.time != nil)
    }
}
