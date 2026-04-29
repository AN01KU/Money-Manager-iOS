import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct AddTransactionViewModelTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    // MARK: - Validation

    @Test
    func testIsValidRequiresPositiveAmountAndCategory() {
        let vm = AddTransactionViewModel(mode: .personal())

        #expect(vm.isValid == false) // empty amount + category

        vm.amount = "500"
        #expect(vm.isValid == false) // empty category

        vm.selectedCategory = "Food"
        #expect(vm.isValid == true)

        vm.amount = "0"
        #expect(vm.isValid == false) // zero amount

        vm.amount = "-10"
        #expect(vm.isValid == false) // negative

        vm.amount = "abc"
        #expect(vm.isValid == false) // non-numeric
    }

    // MARK: - Navigation Title

    @Test
    func testNavigationTitleIdentifier() {
        let addVM = AddTransactionViewModel(mode: .personal())
        #expect(addVM.navigationTitleIdentifier == "add-transaction")

        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let editVM = AddTransactionViewModel(mode: .personal(editing: expense))
        #expect(editVM.navigationTitleIdentifier == "edit-expense")
    }

    @Test
    func testNavigationTitleIdentifierForIncome() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.transactionType = .income
        #expect(vm.navigationTitleIdentifier == "add-income")

        let income = Transaction(type: .income, amount: 100, category: "Work & Professional", date: Date())
        let editVM = AddTransactionViewModel(mode: .personal(editing: income))
        #expect(editVM.navigationTitleIdentifier == "edit-income")
    }

    // MARK: - Setup from existing transaction

    @Test
    func testSetupPopulatesFieldsFromTransaction() {
        let expense = Transaction(
            amount: 250.50,
            category: "Transport",
            date: Date(),
            time: Date(),
            transactionDescription: "Taxi",
            notes: "Airport trip"
        )
        let vm = AddTransactionViewModel(mode: .personal(editing: expense))
        vm.setup()

        #expect(vm.amount == "250.50")
        #expect(vm.selectedCategory == "Transport")
        #expect(vm.description == "Taxi")
        #expect(vm.notes == "Airport trip")
        #expect(vm.hasTime == true)
        #expect(vm.transactionType == .expense)
    }

    @Test
    func testSetupPopulatesTransactionTypeForIncome() {
        let income = Transaction(
            type: .income,
            amount: 5000,
            category: "Work & Professional",
            date: Date()
        )
        let vm = AddTransactionViewModel(mode: .personal(editing: income))
        vm.setup()

        #expect(vm.transactionType == .income)
    }

    @Test
    func testSetupWithNoTimeTransaction() {
        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let vm = AddTransactionViewModel(mode: .personal(editing: expense))
        vm.setup()

        #expect(vm.hasTime == false)
        #expect(vm.description == "")
        #expect(vm.notes == "")
    }

    @Test
    func testSetupDoesNothingForNewTransactionMode() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.setup()

        #expect(vm.amount.isEmpty)
        #expect(vm.selectedCategory.isEmpty)
    }

    // MARK: - Format helpers

    @Test
    func testFormatDateAndTime() {
        let vm = AddTransactionViewModel(mode: .personal())
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 15))!

        let dateStr = vm.formatDate(date)
        #expect(dateStr.contains("Mar") || dateStr.contains("15"))

        let timeStr = vm.formatTime(date)
        #expect(!timeStr.isEmpty)
    }

    // MARK: - Save: new expense

    @Test
    func testSaveCreatesNewTransaction() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context

        vm.amount = "150.75"
        vm.selectedCategory = "Food & Dining"
        vm.description = "Lunch"
        vm.notes = "With team"
        vm.hasTime = true

        var completed = false
        vm.save { completed = true }

        #expect(completed == true)
        #expect(vm.isSaving == false)
        #expect(vm.showError == false)

        let expenses = try context.fetch(FetchDescriptor<Transaction>())
        #expect(expenses.count == 1)
        #expect(expenses.first?.amount == 150.75)
        #expect(expenses.first?.category == "Food & Dining")
        #expect(expenses.first?.transactionDescription == "Lunch")
        #expect(expenses.first?.notes == "With team")
        #expect(expenses.first?.time != nil)
    }

    @Test
    func testSaveCreatesIncomeTransaction() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.transactionType = .income

        vm.amount = "5000"
        vm.selectedCategory = "Work & Professional"

        vm.save {}

        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        #expect(transactions.first?.type == .income)
    }

    @Test
    func testSaveWithoutTimeSetTimeToNil() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context

        vm.amount = "100"
        vm.selectedCategory = "Transport"
        vm.hasTime = false

        vm.save {}

        let expenses = try context.fetch(FetchDescriptor<Transaction>())
        #expect(expenses.first?.time == nil)
    }

    @Test
    func testSaveWithEmptyDescriptionAndNotesSetsNil() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context

        vm.amount = "50"
        vm.selectedCategory = "Other"
        vm.description = ""
        vm.notes = ""

        vm.save {}

        let expenses = try context.fetch(FetchDescriptor<Transaction>())
        #expect(expenses.first?.transactionDescription == nil)
        #expect(expenses.first?.notes == nil)
    }

    // MARK: - Save: edit existing expense

    @Test
    func testSaveUpdatesExistingTransaction() throws {
        let context = try makeContext()
        let existing = Transaction(
            amount: 100,
            category: "Food",
            date: Date(),
            time: Date(),
            transactionDescription: "Old",
            notes: "Old note"
        )
        context.insert(existing)
        try context.save()

        let vm = AddTransactionViewModel(mode: .personal(editing: existing))
        vm.modelContext = context

        vm.amount = "200"
        vm.selectedCategory = "Transport"
        vm.description = "Updated"
        vm.notes = ""
        vm.hasTime = false

        var completed = false
        vm.save { completed = true }

        #expect(completed == true)
        #expect(existing.amount == 200)
        #expect(existing.category == "Transport")
        #expect(existing.transactionDescription == "Updated")
        #expect(existing.notes == nil)
        #expect(existing.time == nil)
    }

    // MARK: - Save: validation failures

    @Test
    func testSaveFailsWithZeroAmount() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "0"
        vm.selectedCategory = "Food"

        var completed = false
        vm.save { completed = true }

        #expect(completed == false)
        #expect(vm.showError == true)
        print(vm.errorMessage)
        #expect(vm.errorMessage.contains("amount"))
    }

    @Test
    func testSaveFailsWithNonNumericAmount() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "abc"
        vm.selectedCategory = "Food"

        var completed = false
        vm.save { completed = true }

        #expect(completed == false)
        #expect(vm.showError == true)
    }

    @Test
    func testSaveWithNoModelContextDoesNothing() {
        let vm = AddTransactionViewModel(mode: .personal())
        // No modelContext set
        vm.amount = "100"
        vm.selectedCategory = "Food"

        var completed = false
        vm.save { completed = true }

        #expect(completed == false)
    }

    // MARK: - Save: date handling

    @Test
    func testSaveSetsCorrectDateWithTime() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context

        let specificDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let specificTime = Calendar.current.date(from: DateComponents(hour: 14, minute: 30))!

        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.selectedDate = specificDate
        vm.selectedTime = specificTime
        vm.hasTime = true

        vm.save {}

        let expenses = try context.fetch(FetchDescriptor<Transaction>())
        let saved = expenses.first!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: saved.date)
        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    @Test
    func testSaveSetsStartOfDayWhenNoTime() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context

        let specificDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 18, minute: 45))!

        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.selectedDate = specificDate
        vm.hasTime = false

        vm.save {}

        let expenses = try context.fetch(FetchDescriptor<Transaction>())
        let saved = expenses.first!
        let components = Calendar.current.dateComponents([.hour, .minute], from: saved.date)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
    }

    // MARK: - isRecurring validation

    @Test
    func testIsValidFalseWhenRecurringEnabledButDescriptionBlank() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.amount = "500"
        vm.selectedCategory = "Food"
        vm.isRecurring = true
        vm.description = "  "  // blank

        #expect(vm.isValid == false)
    }

    @Test
    func testIsValidTrueWhenRecurringEnabledWithDescription() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.amount = "500"
        vm.selectedCategory = "Food"
        vm.isRecurring = true
        vm.description = "Monthly Rent"

        #expect(vm.isValid == true)
    }

    // MARK: - isRecurring save creates RecurringTransaction

    @Test
    func testSaveWithRecurringCreatesRecurringTransaction() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "5000"
        vm.selectedCategory = "Housing"
        vm.description = "Monthly Rent"
        vm.isRecurring = true
        vm.recurringFrequency = .monthly
        vm.recurringDayOfMonth = 1

        vm.save {}

        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(recurring.count == 1)
        #expect(recurring.first?.name == "Monthly Rent")
        #expect(recurring.first?.frequency == .monthly)

        // The transaction should link to the recurring template
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        #expect(transactions.first?.recurringExpenseId == recurring.first?.id)
    }

    @Test
    func testSaveWithRecurringMonthlySetsDayOfMonth() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "1000"
        vm.selectedCategory = "Food"
        vm.description = "Subscription"
        vm.isRecurring = true
        vm.recurringFrequency = .monthly
        vm.recurringDayOfMonth = 15

        vm.save {}

        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(recurring.first?.dayOfMonth == 15)
    }

    @Test
    func testSaveWithRecurringNonMonthlyDoesNotSetDayOfMonth() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "200"
        vm.selectedCategory = "Food"
        vm.description = "Weekly lunch"
        vm.isRecurring = true
        vm.recurringFrequency = .weekly

        vm.save {}

        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(recurring.first?.dayOfMonth == nil)
    }

    @Test
    func testSaveWithRecurringHasEndDatePersistsEndDate() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "500"
        vm.selectedCategory = "Housing"
        vm.description = "Lease"
        vm.isRecurring = true
        vm.recurringFrequency = .monthly
        vm.recurringHasEndDate = true
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        vm.recurringEndDate = endDate

        vm.save {}

        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(recurring.first?.endDate != nil)
    }

    @Test
    func testSaveWithRecurringNoEndDateSetsNilEndDate() throws {
        let context = try makeContext()
        let vm = AddTransactionViewModel(mode: .personal())
        vm.modelContext = context
        vm.amount = "500"
        vm.selectedCategory = "Housing"
        vm.description = "Ongoing rent"
        vm.isRecurring = true
        vm.recurringFrequency = .monthly
        vm.recurringHasEndDate = false  // no end date

        vm.save {}

        let recurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(recurring.first?.endDate == nil)
    }

    // MARK: - Recurring amount alert (editing recurring-linked transaction)

    @Test
    func testSaveShowsRecurringAlertWhenEditingRecurringLinkedWithChangedAmount() throws {
        let context = try makeContext()
        // Create a recurring transaction and a linked expense
        let recurring = RecurringTransaction(name: "Rent", amount: 1000, category: "Housing", frequency: .monthly)
        context.insert(recurring)

        let existing = Transaction(
            amount: 1000,
            category: "Housing",
            date: Date(),
            recurringExpenseId: recurring.id
        )
        context.insert(existing)
        try context.save()

        let vm = AddTransactionViewModel(mode: .personal(editing: existing))
        vm.modelContext = context
        vm.setup()  // sets originalAmount = 1000, editingRecurringExpenseId

        // Change the amount — this should trigger the alert instead of saving
        vm.amount = "1500"
        vm.selectedCategory = "Housing"

        var completed = false
        vm.save { completed = true }

        #expect(vm.showRecurringAmountAlert == true)
        #expect(completed == false) // alert shown, save deferred
    }

    @Test
    func testSaveDoesNotShowAlertWhenAmountUnchanged() throws {
        let context = try makeContext()
        let recurring = RecurringTransaction(name: "Rent", amount: 1000, category: "Housing", frequency: .monthly)
        context.insert(recurring)

        let existing = Transaction(
            amount: 1000,
            category: "Housing",
            date: Date(),
            recurringExpenseId: recurring.id
        )
        context.insert(existing)
        try context.save()

        let vm = AddTransactionViewModel(mode: .personal(editing: existing))
        vm.modelContext = context
        vm.setup()  // sets originalAmount = 1000

        // Keep the same amount — no alert expected
        vm.amount = "1000"
        vm.selectedCategory = "Housing"

        var completed = false
        vm.save { completed = true }

        #expect(vm.showRecurringAmountAlert == false)
        #expect(completed == true)
    }

    @Test
    func testSaveAlsoUpdatingRecurringUpdatesRecurringAmount() throws {
        let context = try makeContext()
        let recurring = RecurringTransaction(name: "Rent", amount: 1000, category: "Housing", frequency: .monthly)
        context.insert(recurring)

        let existing = Transaction(
            amount: 1000,
            category: "Housing",
            date: Date(),
            recurringExpenseId: recurring.id
        )
        context.insert(existing)
        try context.save()

        let vm = AddTransactionViewModel(mode: .personal(editing: existing))
        vm.modelContext = context
        vm.setup()

        vm.amount = "2000"
        vm.selectedCategory = "Housing"

        // Trigger save → shows alert (deferred)
        vm.save { }
        #expect(vm.showRecurringAmountAlert == true)

        // User chooses to also update the recurring template
        var completed = false
        vm.saveAlsoUpdatingRecurring { completed = true }

        #expect(completed == true)
        // Recurring amount should now be updated
        let fetchedRecurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(fetchedRecurring.first?.amount == 2000)
    }

    @Test
    func testSaveThisTransactionOnlyDoesNotUpdateRecurringTemplate() throws {
        let context = try makeContext()
        let recurring = RecurringTransaction(name: "Rent", amount: 1000, category: "Housing", frequency: .monthly)
        context.insert(recurring)

        let existing = Transaction(
            amount: 1000,
            category: "Housing",
            date: Date(),
            recurringExpenseId: recurring.id
        )
        context.insert(existing)
        try context.save()

        let vm = AddTransactionViewModel(mode: .personal(editing: existing))
        vm.modelContext = context
        vm.setup()

        vm.amount = "1500"
        vm.selectedCategory = "Housing"

        vm.save { }
        #expect(vm.showRecurringAmountAlert == true)

        // User chooses to update only this transaction
        vm.saveThisTransactionOnly()

        // Recurring amount stays unchanged
        let fetchedRecurring = try context.fetch(FetchDescriptor<RecurringTransaction>())
        #expect(fetchedRecurring.first?.amount == 1000)

        // Transaction is updated
        let fetchedTx = try context.fetch(FetchDescriptor<Transaction>())
        let editedTx = fetchedTx.first { $0.recurringExpenseId == recurring.id }
        #expect(editedTx?.amount == 1500)
    }

    // MARK: - TransactionType init(kind:)

    @Test
    func testTransactionTypeInitFromIncomeKind() {
        let type = TransactionType(kind: .income)
        #expect(type == .income)
    }

    @Test
    func testTransactionTypeInitFromExpenseKind() {
        let type = TransactionType(kind: .expense)
        #expect(type == .expense)
    }

    @Test
    func testTransactionTypeKindForExpense() {
        #expect(TransactionType.expense.kind == .expense)
    }

    @Test
    func testTransactionTypeKindForIncome() {
        #expect(TransactionType.income.kind == .income)
    }
}
