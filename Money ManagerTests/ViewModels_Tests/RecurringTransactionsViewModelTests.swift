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

        viewModel.toggle(at: 0)

        #expect(active.isActive == false)
    }

    @Test
    func testToggleInactiveBecomesActive() {
        let viewModel = RecurringTransactionsViewModel()

        let inactive = RecurringTransaction(name: "Old Gym", amount: 500, category: "Health", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [inactive])

        #expect(viewModel.pausedRecurring.count == 1)

        viewModel.toggle(at: 0)

        #expect(inactive.isActive == true)
    }

    @Test
    func testDeactivateSetsIsActiveToFalse() {
        let viewModel = RecurringTransactionsViewModel()

        let active = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly, isActive: true)

        viewModel.update(recurring: [active])

        #expect(viewModel.activeRecurring.count == 1)

        viewModel.deactivate(at: 0)

        #expect(active.isActive == false)
    }

    @Test
    func testDeactivateDoesNothingForInvalidIndex() {
        let viewModel = RecurringTransactionsViewModel()

        let active = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly, isActive: true)

        viewModel.update(recurring: [active])

        viewModel.deactivate(at: 5)

        #expect(active.isActive == true)
    }

    @Test
    func testDeactivateRemovesFromActiveList() {
        let viewModel = RecurringTransactionsViewModel()

        let active1 = RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: .monthly, isActive: true)
        let active2 = RecurringTransaction(name: "Gym", amount: 500, category: "Health", frequency: .monthly, isActive: true)

        viewModel.update(recurring: [active1, active2])

        #expect(viewModel.activeRecurring.count == 2)

        viewModel.deactivate(at: 0)

        #expect(viewModel.activeRecurring.count == 1)
        #expect(viewModel.activeRecurring.first?.name == "Gym")
    }

    @Test
    func testDeleteDoesNothingForInvalidIndex() {
        let viewModel = RecurringTransactionsViewModel()

        let paused = RecurringTransaction(name: "Old", amount: 100, category: "Other", frequency: .monthly, isActive: false)

        viewModel.update(recurring: [paused])

        viewModel.delete(at: 5)

        #expect(viewModel.pausedRecurring.count == 1)
    }

    @Test
    func testDeleteSoftDeletesRecord() {
        let paused = RecurringTransaction(name: "ToDelete", amount: 100, category: "Other", frequency: .monthly, isActive: false)

        let viewModel = RecurringTransactionsViewModel()
        viewModel.update(recurring: [paused])

        viewModel.delete(at: 0)

        #expect(paused.isSoftDeleted == true)
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
    func testSaveWithModelContextPersistsRecurringTransaction() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 1

        let context = ModelContext(makeTestContainer())

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
    func testSaveSetsDayOfMonthOnlyForMonthly() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.frequency = .monthly
        viewModel.dayOfMonth = 15

        let context = ModelContext(makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.dayOfMonth == 15)
    }

    @Test
    func testSaveDoesNotSetDayOfMonthForNonMonthly() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.frequency = .weekly

        let context = ModelContext(makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.dayOfMonth == nil)
    }

    @Test
    func testSaveWithEndDatePersistsEndDate() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Entertainment"
        viewModel.hasEndDate = true
        viewModel.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        let context = ModelContext(makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.endDate != nil)
    }

    @Test
    func testSaveWithoutEndDateSetsNilEndDate() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Entertainment"
        viewModel.hasEndDate = false

        let context = ModelContext(makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.endDate == nil)
    }

    @Test
    func testSaveWithNotesPersistsNotes() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.notes = "Test notes"

        let context = ModelContext(makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.notes == "Test notes")
    }

    @Test
    func testSaveWithEmptyNotesSetsNil() {
        let viewModel = AddRecurringTransactionViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.notes = ""

        let context = ModelContext(makeTestContainer())

        viewModel.modelContext = context
        _ = viewModel.save()

        let descriptor = FetchDescriptor<RecurringTransaction>()
        let items = (try? context.fetch(descriptor)) ?? []

        #expect(items.first?.notes == nil)
    }
}
