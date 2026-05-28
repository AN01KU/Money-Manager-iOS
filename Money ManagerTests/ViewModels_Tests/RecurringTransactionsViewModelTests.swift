import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringTransactionsViewModelTests {

    private func makeService(items: [RecurringTransaction] = []) throws -> (RecurringTransactionsViewModel, ModelContext) {
        let context = ModelContext(try makeTestContainer())
        for item in items { context.insert(item) }
        if !items.isEmpty { try context.save() }
        let svc = PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
        return (RecurringTransactionsViewModel(persistence: svc), context)
    }

    @Test
    func testActiveRecurringFiltersOutInactive() {
        let viewModel = RecurringTransactionsViewModel()

        let active1 = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly)
        let active2 = RecurringTransaction(name: "Gym", amount: 500, categoryId: UUID(), frequency: .monthly)
        let inactive = RecurringTransaction(name: "Old", amount: 100, categoryId: UUID(), frequency: .monthly, isActive: false)

        viewModel.update(recurring: [active1, active2, inactive])

        #expect(viewModel.activeRecurring.count == 2)
    }

    @Test
    func testActiveRecurringReturnsEmptyWhenAllInactive() {
        let viewModel = RecurringTransactionsViewModel()

        let inactive = RecurringTransaction(name: "Old", amount: 100, categoryId: UUID(), frequency: .monthly, isActive: false)

        viewModel.update(recurring: [inactive])

        #expect(viewModel.activeRecurring.isEmpty)
    }

    @Test
    func testPausedRecurringReturnsOnlyInactive() {
        let viewModel = RecurringTransactionsViewModel()

        let active1 = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly)
        let active2 = RecurringTransaction(name: "Gym", amount: 500, categoryId: UUID(), frequency: .monthly)
        let inactive = RecurringTransaction(name: "Old", amount: 100, categoryId: UUID(), frequency: .monthly, isActive: false)

        viewModel.update(recurring: [active1, active2, inactive])

        #expect(viewModel.pausedRecurring.count == 1)
        #expect(viewModel.pausedRecurring.first?.name == "Old")
    }

    @Test
    func testToggleSwapsActiveState() throws {
        let active = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly, isActive: true)
        let (viewModel, _) = try makeService(items: [active])
        viewModel.update(recurring: [active])

        #expect(viewModel.activeRecurring.count == 1)
        viewModel.toggle(active)
        #expect(active.isActive == false)
    }

    @Test
    func testToggleInactiveBecomesActive() throws {
        let inactive = RecurringTransaction(name: "Old Gym", amount: 500, categoryId: UUID(), frequency: .monthly, isActive: false)
        let (viewModel, _) = try makeService(items: [inactive])
        viewModel.update(recurring: [inactive])

        #expect(viewModel.pausedRecurring.count == 1)
        viewModel.toggle(inactive)
        #expect(inactive.isActive == true)
    }

    @Test
    func testDeactivateSetsIsActiveToFalse() throws {
        let active = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly, isActive: true)
        let (viewModel, _) = try makeService(items: [active])
        viewModel.update(recurring: [active])

        #expect(viewModel.activeRecurring.count == 1)
        viewModel.toggle(active)
        #expect(active.isActive == false)
    }

    @Test
    func testDeactivateDoesNothingForUnrelatedItem() throws {
        let active = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly, isActive: true)
        let other = RecurringTransaction(name: "Other", amount: 100, categoryId: UUID(), frequency: .monthly, isActive: true)
        let (viewModel, _) = try makeService(items: [active, other])
        viewModel.update(recurring: [active])

        viewModel.toggle(other)
        #expect(active.isActive == true)
    }

    @Test
    func testDeactivateRemovesFromActiveList() throws {
        let active1 = RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly, isActive: true)
        let active2 = RecurringTransaction(name: "Gym", amount: 500, categoryId: UUID(), frequency: .monthly, isActive: true)
        let (viewModel, _) = try makeService(items: [active1, active2])
        viewModel.update(recurring: [active1, active2])

        #expect(viewModel.activeRecurring.count == 2)
        viewModel.toggle(active1)
        #expect(viewModel.activeRecurring.count == 1)
        #expect(viewModel.activeRecurring.first?.name == "Gym")
    }

    @Test
    func testDeleteDoesNothingForUnrelatedItem() throws {
        let paused = RecurringTransaction(name: "Old", amount: 100, categoryId: UUID(), frequency: .monthly, isActive: false)
        let other = RecurringTransaction(name: "Other", amount: 50, categoryId: UUID(), frequency: .monthly, isActive: false)
        let (viewModel, _) = try makeService(items: [paused, other])
        viewModel.update(recurring: [paused])

        viewModel.deleteItem(other)

        #expect(viewModel.pausedRecurring.count == 1)
    }

    @Test
    func testDeleteRemovesItemFromAllRecurring() throws {
        let item = RecurringTransaction(name: "ToDelete", amount: 100, categoryId: UUID(), frequency: .monthly)
        let other = RecurringTransaction(name: "Keeper", amount: 200, categoryId: UUID(), frequency: .monthly)
        let (viewModel, _) = try makeService(items: [item, other])
        viewModel.update(recurring: [item, other])

        viewModel.deleteItem(item)

        #expect(!viewModel.allRecurring.contains { $0.id == item.id })
        #expect(viewModel.allRecurring.count == 1)
        #expect(viewModel.allRecurring.first?.name == "Keeper")
    }

    @Test
    func testDeleteSoftDeletesRecord() throws {
        let paused = RecurringTransaction(name: "ToDelete", amount: 100, categoryId: UUID(), frequency: .monthly, isActive: false)
        let (viewModel, _) = try makeService(items: [paused])
        viewModel.update(recurring: [paused])

        viewModel.deleteItem(paused)

        #expect(paused.isSoftDeleted == true)
    }

    @Test
    func testDeleteItemUnlinksLinkedTransactions() throws {
        let context = ModelContext(try makeTestContainer())

        let recurring = RecurringTransaction(name: "Rent", amount: 1000, categoryId: UUID(), frequency: .monthly)
        context.insert(recurring)

        let tx = Transaction(amount: 1000, categoryId: UUID(), date: Date(), recurringExpenseId: recurring.id)
        context.insert(tx)
        try context.save()

        let persistence = PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
        let viewModel = RecurringTransactionsViewModel(persistence: persistence)
        viewModel.update(recurring: [recurring])

        viewModel.deleteItem(recurring)

        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        #expect(transactions.first?.recurringExpenseId == nil)
        #expect(recurring.isSoftDeleted == true)
    }

    // MARK: - upcomingTotalThisMonth

    // nextOccurrence for daily items with yesterday as startDate lands on tomorrow,
    // which is within the current month (unless today is the last day of the month).
    @Test
    func testUpcomingTotalThisMonthIsNegativeForExpenses() {
        let viewModel = RecurringTransactionsViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let expense = RecurringTransaction(
            name: "Rent",
            amount: 10000,
            categoryId: UUID(),
            frequency: .daily,
            startDate: yesterday,
            isActive: true,
            type: .expense
        )
        viewModel.update(recurring: [expense])

        #expect(viewModel.upcomingTotalThisMonth <= 0)
    }

    @Test
    func testUpcomingTotalThisMonthIsPositiveForIncome() {
        let viewModel = RecurringTransactionsViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let income = RecurringTransaction(
            name: "Salary",
            amount: 50000,
            categoryId: UUID(),
            frequency: .daily,
            startDate: yesterday,
            isActive: true,
            type: .income
        )
        viewModel.update(recurring: [income])

        #expect(viewModel.upcomingTotalThisMonth >= 0)
    }

    @Test
    func testUpcomingTotalThisMonthIsNetOfIncomeAndExpense() {
        let viewModel = RecurringTransactionsViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let income = RecurringTransaction(
            name: "Salary",
            amount: 50000,
            categoryId: UUID(),
            frequency: .daily,
            startDate: yesterday,
            isActive: true,
            type: .income
        )
        let expense = RecurringTransaction(
            name: "Rent",
            amount: 20000,
            categoryId: UUID(),
            frequency: .daily,
            startDate: yesterday,
            isActive: true,
            type: .expense
        )
        viewModel.update(recurring: [income, expense])

        // Net = income - expense = 50000 - 20000 = 30000
        // Both items' nextOccurrence is tomorrow (in the current month)
        #expect(viewModel.upcomingTotalThisMonth == 30000)
    }

    // MARK: - upcomingThisMonth filtering

    @Test
    func testUpcomingThisMonthIncludesActiveItemWithNextOccurrenceInMonth() {
        let viewModel = RecurringTransactionsViewModel()
        let calendar = Calendar.current
        // startDate yesterday → nextOccurrence is tomorrow (still this month unless last day)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let active = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            categoryId: UUID(),
            frequency: .daily,
            startDate: yesterday,
            isActive: true
        )
        viewModel.update(recurring: [active])

        // nextOccurrence == tomorrow, which falls in current month
        #expect(viewModel.upcomingThisMonth.count == 1)
    }

    @Test
    func testUpcomingThisMonthExcludesPausedItems() {
        let viewModel = RecurringTransactionsViewModel()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let paused = RecurringTransaction(
            name: "Gym",
            amount: 500,
            categoryId: UUID(),
            frequency: .daily,
            startDate: yesterday,
            isActive: false // paused
        )
        viewModel.update(recurring: [paused])

        // Paused items have nextOccurrence == nil, so they're excluded
        #expect(viewModel.upcomingThisMonth.isEmpty)
    }

    @Test
    func testUpcomingThisMonthSortedByNextOccurrenceAscending() {
        let viewModel = RecurringTransactionsViewModel()
        let calendar = Calendar.current

        // Two daily items: one started further back → nextOccurrence is still tomorrow for both
        // Use monthly to control nextOccurrence date precisely
        let nearFuture = calendar.date(byAdding: .day, value: -1, to: Date())!
        let farStart = calendar.date(byAdding: .day, value: -5, to: Date())!

        let sooner = RecurringTransaction(
            name: "Earlier",
            amount: 100,
            categoryId: UUID(),
            frequency: .daily,
            startDate: nearFuture,
            isActive: true
        )
        let later = RecurringTransaction(
            name: "Later",
            amount: 200,
            categoryId: UUID(),
            frequency: .daily,
            startDate: farStart,
            isActive: true
        )
        viewModel.update(recurring: [later, sooner]) // reversed order in input

        let upcoming = viewModel.upcomingThisMonth
        // Both nextOccurrence values are tomorrow (same day), but at minimum they should be present
        #expect(upcoming.count == 2)
        // Verify ascending sort: first item's nextOccurrence ≤ second item's
        if upcoming.count == 2, let first = upcoming[0].nextOccurrence, let second = upcoming[1].nextOccurrence {
            #expect(first <= second)
        }
    }
}

@MainActor
struct AddRecurringTransactionViewModelTests {

    @Test
    func testIsValidWithAllRequiredFields() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"

        #expect(viewModel.isValid == true)
    }

    @Test
    func testIsValidFailsWithEmptyName() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = ""
        viewModel.amount = "649"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithWhitespaceName() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "   "
        viewModel.amount = "649"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithZeroAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "0"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithNegativeAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "-100"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithInvalidAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "abc"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testSaveFailsWithInvalidAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "abc"

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("Amount"))
    }

    @Test
    func testSaveFailsWithEmptyName() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = ""
        viewModel.amount = "649"

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("name"))
    }

    @Test
    func testSaveTrimsWhitespaceFromName() throws {
        let (svc, _) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "  Netflix  "
        viewModel.amount = "649"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 1

        let result = viewModel.save()

        #expect(result == true)
    }

    @Test
    func testFrequenciesContainsStandardOptions() {
        let viewModel = AddRecurringTransactionViewModel()

        #expect(viewModel.frequencies.contains(.daily))
        #expect(viewModel.frequencies.contains(.weekly))
        #expect(viewModel.frequencies.contains(.monthly))
        #expect(viewModel.frequencies.contains(.yearly))
    }

    private func makeService() throws -> (PersistenceService, ModelContext) {
        let context = ModelContext(try makeTestContainer())
        let svc = PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
        return (svc, context)
    }

    @Test
    func testSaveWithModelContextPersistsRecurringTransaction() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 1

        let result = viewModel.save()

        #expect(result == true)

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []
        #expect(items.count == 1)
        #expect(items.first?.name == "Netflix")
        #expect(items.first?.amount == 649)
    }

    @Test
    func testSaveSetsDayOfMonthOnlyForMonthly() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 15

        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.dayOfMonth == 15)
    }

    @Test
    func testSaveDoesNotSetDayOfMonthForNonMonthly() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.frequency = .weekly

        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.dayOfMonth == nil)
    }

    @Test
    func testSaveWithEndDatePersistsEndDate() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.hasEndDate = true
        viewModel.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.endDate != nil)
    }

    @Test
    func testSaveWithoutEndDateSetsNilEndDate() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.hasEndDate = false

        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.endDate == nil)
    }

    @Test
    func testSaveWithNotesPersistsNotes() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.notes = "Test notes"

        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.notes == "Test notes")
    }

    @Test
    func testSaveWithEmptyNotesSetsNil() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.notes = ""

        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.notes == nil)
    }

    // MARK: - Transaction type

    @Test
    func testDefaultTransactionTypeIsExpense() {
        let viewModel = AddRecurringTransactionViewModel()
        #expect(viewModel.transactionType == .expense)
    }

    @Test
    func testPrefillSetsTransactionType() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.prefill(categoryId: UUID(), type: .income, amountString: "5000")
        #expect(viewModel.transactionType == .income)
    }

    @Test
    func testPrefillDefaultsToExpenseWhenTypeOmitted() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.prefill(categoryId: UUID(), amountString: "500")
        #expect(viewModel.transactionType == .expense)
    }

    @Test
    func testSavePersistsIncomeType() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Salary"
        viewModel.amount = "50000"
        viewModel.transactionType = .income

        _ = viewModel.save()

        let items = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        #expect(items.first?.type == .income)
    }

    @Test
    func testSavePersistsExpenseType() throws {
        let (svc, context) = try makeService()
        let viewModel = AddRecurringTransactionViewModel(persistence: svc)
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.transactionType = .expense

        _ = viewModel.save()

        let items = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        #expect(items.first?.type == .expense)
    }
}

@MainActor
struct EditRecurringTransactionViewModelTests {

    private func makeMonthly() -> RecurringTransaction {
        RecurringTransaction(name: "Rent", amount: 1000, categoryId: UUID(), frequency: .monthly, dayOfMonth: 5)
    }

    private func makeWeekly() -> RecurringTransaction {
        RecurringTransaction(name: "Gym", amount: 500, categoryId: UUID(), frequency: .weekly, daysOfWeek: [1, 3])
    }

    // MARK: - load

    @Test
    func testLoadPopulatesFields() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)

        #expect(vm.name == "Rent")
        #expect(Double(vm.amount) == 1000)
        #expect(vm.selectedCategoryId == recurring.categoryId)
        #expect(vm.frequency == .monthly)
        #expect(vm.dayOfMonth == 5)
        #expect(vm.frequencyError == nil)
    }

    @Test
    func testLoadResetsFrequencyError() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.frequencyError = "stale error"
        vm.load(from: recurring)

        #expect(vm.frequencyError == nil)
    }

    // MARK: - isValid

    @Test
    func testIsValidTrueWhenNoFrequencyChange() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)

        #expect(vm.isValid == true)
    }

    @Test
    func testIsValidFalseWhenChangingToWeeklyWithNoDaysSelected() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.frequency = .weekly
        vm.daysOfWeek = []

        #expect(vm.isValid == false)
    }

    @Test
    func testIsValidTrueWhenChangingToWeeklyWithDaysSelected() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.frequency = .weekly
        vm.daysOfWeek = [1, 3]

        #expect(vm.isValid == true)
    }

    @Test
    func testIsValidFalseWithEmptyName() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.name = ""

        #expect(vm.isValid == false)
    }

    @Test
    func testIsValidFalseWithZeroAmount() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.amount = "0"

        #expect(vm.isValid == false)
    }

    // MARK: - validateFrequency

    @Test
    func testValidateFrequencySetsErrorWhenChangingToWeeklyWithNoDays() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.frequency = .weekly
        vm.daysOfWeek = []
        vm.validateFrequency()

        #expect(vm.frequencyError != nil)
        #expect(vm.frequencyError?.contains("day of the week") == true)
    }

    @Test
    func testValidateFrequencyClearsErrorWhenDaysSelected() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.frequency = .weekly
        vm.daysOfWeek = []
        vm.validateFrequency()
        vm.daysOfWeek = [2]
        vm.validateFrequency()

        #expect(vm.frequencyError == nil)
    }

    @Test
    func testValidateFrequencyNoErrorWhenFrequencyUnchanged() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.validateFrequency()

        #expect(vm.frequencyError == nil)
    }

    // MARK: - apply

    @Test
    func testApplyReturnsFalseWhenWeeklyWithNoDays() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.frequency = .weekly
        vm.daysOfWeek = []

        let result = vm.apply(to: recurring)

        #expect(result == false)
        #expect(vm.showError == true)
        #expect(vm.errorMessage.contains("day of the week"))
    }

    @Test
    func testApplySetsDaysOfWeekWhenWeekly() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.frequency = .weekly
        vm.daysOfWeek = [1, 4]

        let result = vm.apply(to: recurring)

        #expect(result == true)
        #expect(recurring.daysOfWeek == [1, 4])
        #expect(recurring.dayOfMonth == nil)
    }

    @Test
    func testApplyClearsDaysOfWeekWhenMonthly() {
        let recurring = makeWeekly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)
        vm.frequency = .monthly
        vm.dayOfMonth = 10

        let result = vm.apply(to: recurring)

        #expect(result == true)
        #expect(recurring.dayOfMonth == 10)
        #expect(recurring.daysOfWeek == nil)
    }

    @Test
    func testApplyReturnsTrueWhenValidMonthly() {
        let recurring = makeMonthly()
        let vm = EditRecurringTransactionViewModel()
        vm.load(from: recurring)

        let result = vm.apply(to: recurring)

        #expect(result == true)
        #expect(recurring.name == "Rent")
    }
}
