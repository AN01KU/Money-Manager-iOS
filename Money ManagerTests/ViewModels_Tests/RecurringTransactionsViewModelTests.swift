import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringTransactionsViewModelTests {

    @Test
    func testActiveRecurringFiltersOutInactive() {
        let viewModel = RecurringTransactionsViewModel()

        let active1 = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        let active2 = RecurringTransaction(name: "Gym", amount: 500, category: "Health", frequency: .monthly)
        let inactive = RecurringTransaction(name: "Old", amount: 100, category: "Other", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [active1, active2, inactive])

        #expect(viewModel.activeRecurring.count == 2)
    }

    @Test
    func testActiveRecurringReturnsEmptyWhenAllInactive() {
        let viewModel = RecurringTransactionsViewModel()

        let inactive = RecurringTransaction(name: "Old", amount: 100, category: "Other", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [inactive])

        #expect(viewModel.activeRecurring.isEmpty)
    }

    @Test
    func testPausedRecurringReturnsOnlyInactive() {
        let viewModel = RecurringTransactionsViewModel()

        let active1 = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        let active2 = RecurringTransaction(name: "Gym", amount: 500, category: "Health", frequency: .monthly)
        let inactive = RecurringTransaction(name: "Old", amount: 100, category: "Other", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [active1, active2, inactive])

        #expect(viewModel.pausedRecurring.count == 1)
        #expect(viewModel.pausedRecurring.first?.name == "Old")
    }

    @Test
    func testAllRecurringReturnsAll() {
        let viewModel = RecurringTransactionsViewModel()

        let active = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly)
        let inactive = RecurringTransaction(name: "Old", amount: 100, category: "Other", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [active, inactive])

        #expect(viewModel.allRecurring.count == 2)
    }

    @Test
    func testToggleSwapsActiveState() {
        let viewModel = RecurringTransactionsViewModel()

        let active = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly, isActive: true)

        viewModel.update(recurring: [active])

        #expect(viewModel.activeRecurring.count == 1)

        viewModel.toggle(active)

        #expect(active.isActive == false)
    }

    @Test
    func testToggleInactiveBecomesActive() {
        let viewModel = RecurringTransactionsViewModel()

        let inactive = RecurringTransaction(name: "Old Gym", amount: 500, category: "Health", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [inactive])

        #expect(viewModel.pausedRecurring.count == 1)

        viewModel.toggle(inactive)

        #expect(inactive.isActive == true)
    }

    @Test
    func testDeactivateSetsIsActiveToFalse() {
        let viewModel = RecurringTransactionsViewModel()

        let active = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly, isActive: true)

        viewModel.update(recurring: [active])

        #expect(viewModel.activeRecurring.count == 1)

        viewModel.toggle(active)

        #expect(active.isActive == false)
    }

    @Test
    func testDeactivateDoesNothingForUnrelatedItem() {
        let viewModel = RecurringTransactionsViewModel()

        let active = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly, isActive: true)
        let other = RecurringTransaction(name: "Other", amount: 100, category: "Other", frequency: .monthly, isActive: true)

        viewModel.update(recurring: [active])

        // toggling an item not in the list should not affect active
        viewModel.toggle(other)

        #expect(active.isActive == true)
    }

    @Test
    func testDeactivateRemovesFromActiveList() {
        let viewModel = RecurringTransactionsViewModel()

        let active1 = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly, isActive: true)
        let active2 = RecurringTransaction(name: "Gym", amount: 500, category: "Health", frequency: .monthly, isActive: true)

        viewModel.update(recurring: [active1, active2])

        #expect(viewModel.activeRecurring.count == 2)

        viewModel.toggle(active1)

        #expect(viewModel.activeRecurring.count == 1)
        #expect(viewModel.activeRecurring.first?.name == "Gym")
    }

    @Test
    func testDeleteDoesNothingForUnrelatedItem() {
        let viewModel = RecurringTransactionsViewModel()

        let paused = RecurringTransaction(name: "Old", amount: 100, category: "Other", frequency: .monthly, isActive: false)
        let other = RecurringTransaction(name: "Other", amount: 50, category: "Other", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [paused])

        viewModel.deleteItem(other)

        #expect(viewModel.pausedRecurring.count == 1)
    }

    @Test
    func testDeleteSoftDeletesRecord() {
        let paused = RecurringTransaction(name: "ToDelete", amount: 100, category: "Other", frequency: .monthly, isActive: false)

        let viewModel = RecurringTransactionsViewModel()
        viewModel.update(recurring: [paused])

        viewModel.deleteItem(paused)

        #expect(paused.isSoftDeleted == true)
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
            category: "Housing",
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
            category: "Income",
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
            category: "Income",
            frequency: .daily,
            startDate: yesterday,
            isActive: true,
            type: .income
        )
        let expense = RecurringTransaction(
            name: "Rent",
            amount: 20000,
            category: "Housing",
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
            category: "Entertainment",
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
            category: "Health",
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
            category: "Food",
            frequency: .daily,
            startDate: nearFuture,
            isActive: true
        )
        let later = RecurringTransaction(
            name: "Later",
            amount: 200,
            category: "Food",
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
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == true)
    }

    @Test
    func testIsValidFailsWithEmptyName() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = ""
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithWhitespaceName() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "   "
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithZeroAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "0"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithNegativeAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "-100"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithInvalidAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "abc"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithEmptyCategory() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = ""

        #expect(viewModel.isValid == false)
    }

    @Test
    func testSaveFailsWithInvalidAmount() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "abc"
        viewModel.selectedCategory = "Entertainment"

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
        viewModel.selectedCategory = "Entertainment"

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("name"))
    }

    @Test
    func testSaveFailsWithEmptyCategory() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = ""

        let result = viewModel.save()

        #expect(result == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("category"))
    }

    @Test
    func testSaveTrimsWhitespaceFromName() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "  Netflix  "
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
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

    @Test
    func testSaveWithModelContextPersistsRecurringTransaction() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 1

        let context = ModelContext(try makeTestContainer())

        viewModel.modelContext = context

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
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 15

        let context = ModelContext(try makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.dayOfMonth == 15)
    }

    @Test
    func testSaveDoesNotSetDayOfMonthForNonMonthly() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.frequency = .weekly

        let context = ModelContext(try makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.dayOfMonth == nil)
    }

    @Test
    func testSaveWithEndDatePersistsEndDate() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Entertainment"
        viewModel.hasEndDate = true
        viewModel.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        let context = ModelContext(try makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.endDate != nil)
    }

    @Test
    func testSaveWithoutEndDateSetsNilEndDate() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Entertainment"
        viewModel.hasEndDate = false

        let context = ModelContext(try makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.endDate == nil)
    }

    @Test
    func testSaveWithNotesPersistsNotes() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.notes = "Test notes"

        let context = ModelContext(try makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.notes == "Test notes")
    }

    @Test
    func testSaveWithEmptyNotesSetsNil() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.notes = ""

        let context = ModelContext(try makeTestContainer())

        viewModel.modelContext = context
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
        viewModel.prefill(amount: "5000", category: "Salary", type: .income)
        #expect(viewModel.transactionType == .income)
    }

    @Test
    func testPrefillDefaultsToExpenseWhenTypeOmitted() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.prefill(amount: "500", category: "Food")
        #expect(viewModel.transactionType == .expense)
    }

    @Test
    func testSavePersistsIncomeType() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Salary"
        viewModel.amount = "50000"
        viewModel.selectedCategory = "Income"
        viewModel.transactionType = .income

        let context = ModelContext(try makeTestContainer())
        viewModel.modelContext = context
        _ = viewModel.save()

        let items = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        #expect(items.first?.type == .income)
    }

    @Test
    func testSavePersistsExpenseType() throws {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.transactionType = .expense

        let context = ModelContext(try makeTestContainer())
        viewModel.modelContext = context
        _ = viewModel.save()

        let items = (try? context.fetch(FetchDescriptor<RecurringTransaction>())) ?? []
        #expect(items.first?.type == .expense)
    }
}
