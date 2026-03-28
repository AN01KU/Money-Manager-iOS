import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringExpensesViewModelTests {

    @Test
    func testActiveExpensesFiltersOutInactive() {
        let viewModel = RecurringExpensesViewModel()

        let active1 = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly")
        let active2 = RecurringExpense(name: "Gym", amount: 500, category: "Health", frequency: "monthly")
        let inactive = RecurringExpense(name: "Old", amount: 100, category: "Other", frequency: "monthly", isActive: false)

        viewModel.update(expenses: [active1, active2, inactive])

        #expect(viewModel.activeExpenses.count == 2)
    }

    @Test
    func testActiveExpensesReturnsEmptyWhenAllInactive() {
        let viewModel = RecurringExpensesViewModel()

        let inactive = RecurringExpense(name: "Old", amount: 100, category: "Other", frequency: "monthly", isActive: false)

        viewModel.update(expenses: [inactive])

        #expect(viewModel.activeExpenses.isEmpty)
    }

    @Test
    func testPausedExpensesReturnsOnlyInactive() {
        let viewModel = RecurringExpensesViewModel()

        let active1 = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly")
        let active2 = RecurringExpense(name: "Gym", amount: 500, category: "Health", frequency: "monthly")
        let inactive = RecurringExpense(name: "Old", amount: 100, category: "Other", frequency: "monthly", isActive: false)

        viewModel.update(expenses: [active1, active2, inactive])

        #expect(viewModel.pausedExpenses.count == 1)
        #expect(viewModel.pausedExpenses.first?.name == "Old")
    }

    @Test
    func testAllRecurringExpensesReturnsAll() {
        let viewModel = RecurringExpensesViewModel()

        let active = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly")
        let inactive = RecurringExpense(name: "Old", amount: 100, category: "Other", frequency: "monthly", isActive: false)

        viewModel.update(expenses: [active, inactive])

        #expect(viewModel.allRecurringExpenses.count == 2)
    }

    @Test
    func testToggleExpenseSwapsActiveState() {
        let viewModel = RecurringExpensesViewModel()

        let active = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly", isActive: true)

        viewModel.update(expenses: [active])

        #expect(viewModel.activeExpenses.count == 1)

        viewModel.toggleExpense(at: 0)

        #expect(active.isActive == false)
    }

    @Test
    func testToggleExpenseInactiveExpenseBecomesActive() {
        let viewModel = RecurringExpensesViewModel()

        let inactive = RecurringExpense(name: "Old Gym", amount: 500, category: "Health", frequency: "monthly", isActive: false)

        viewModel.update(expenses: [inactive])

        #expect(viewModel.pausedExpenses.count == 1)

        viewModel.toggleExpense(at: 0)

        #expect(inactive.isActive == true)
    }

    @Test
    func testDeactivateExpenseSetsIsActiveToFalse() {
        let viewModel = RecurringExpensesViewModel()

        let active = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly", isActive: true)

        viewModel.update(expenses: [active])

        #expect(viewModel.activeExpenses.count == 1)

        viewModel.deactivateExpense(at: 0)

        #expect(active.isActive == false)
    }

    @Test
    func testDeactivateExpenseDoesNothingForInvalidIndex() {
        let viewModel = RecurringExpensesViewModel()

        let active = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly", isActive: true)

        viewModel.update(expenses: [active])

        viewModel.deactivateExpense(at: 5)

        #expect(active.isActive == true)
    }

    @Test
    func testDeactivateExpenseRemovesFromActiveList() {
        let viewModel = RecurringExpensesViewModel()

        let active1 = RecurringExpense(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly", isActive: true)
        let active2 = RecurringExpense(name: "Gym", amount: 500, category: "Health", frequency: "monthly", isActive: true)

        viewModel.update(expenses: [active1, active2])

        #expect(viewModel.activeExpenses.count == 2)

        viewModel.deactivateExpense(at: 0)

        #expect(viewModel.activeExpenses.count == 1)
        #expect(viewModel.activeExpenses.first?.name == "Gym")
    }

    @Test
    func testDeleteExpenseDoesNothingForInvalidIndex() {
        let viewModel = RecurringExpensesViewModel()

        let paused = RecurringExpense(name: "Old", amount: 100, category: "Other", frequency: "monthly", isActive: false)

        viewModel.update(expenses: [paused])

        viewModel.deleteExpense(at: 5)

        #expect(viewModel.pausedExpenses.count == 1)
    }

    @Test
    func testDeleteExpenseRemovesFromDatabase() {
        let paused = RecurringExpense(name: "ToDelete", amount: 100, category: "Other", frequency: "monthly", isActive: false)

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(paused)
        try? context.save()

        let viewModel = RecurringExpensesViewModel()
        viewModel.modelContext = context
        viewModel.update(expenses: [paused])

        viewModel.deleteExpense(at: 0)

        let descriptor = FetchDescriptor<RecurringExpense>()
        let remaining = (try? context.fetch(descriptor)) ?? []

        #expect(remaining.isEmpty)
    }
}

@MainActor
struct AddRecurringExpenseViewModelTests {

    @Test
    func testIsValidWithAllRequiredFields() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == true)
    }

    @Test
    func testIsValidFailsWithEmptyName() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = ""
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithWhitespaceName() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "   "
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithZeroAmount() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "0"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithNegativeAmount() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "-100"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithInvalidAmount() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "abc"
        viewModel.selectedCategory = "Entertainment"

        #expect(viewModel.isValid == false)
    }

    @Test
    func testIsValidFailsWithEmptyCategory() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = ""

        #expect(viewModel.isValid == false)
    }

    @Test
    func testSaveFailsWithInvalidAmount() {
        let viewModel = AddRecurringExpenseViewModel()
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
        let viewModel = AddRecurringExpenseViewModel()
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
        let viewModel = AddRecurringExpenseViewModel()
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
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "  Netflix  "
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = "monthly"
        viewModel.dayOfMonth = 1

        let result = viewModel.save()

        #expect(result == true)
    }

    @Test
    func testFrequenciesContainsStandardOptions() {
        let viewModel = AddRecurringExpenseViewModel()

        #expect(viewModel.frequencies.contains("daily"))
        #expect(viewModel.frequencies.contains("weekly"))
        #expect(viewModel.frequencies.contains("monthly"))
        #expect(viewModel.frequencies.contains("yearly"))
    }

    @Test
    func testSaveWithModelContextPersistsRecurringExpense() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Netflix"
        viewModel.amount = "649"
        viewModel.selectedCategory = "Entertainment"
        viewModel.frequency = "monthly"
        viewModel.dayOfMonth = 1

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        viewModel.modelContext = context

        let result = viewModel.save()

        #expect(result == true)

        let descriptor = FetchDescriptor<RecurringExpense>()
        let expenses = (try? context.fetch(descriptor)) ?? []
        #expect(expenses.count == 1)
        #expect(expenses.first?.name == "Netflix")
        #expect(expenses.first?.amount == 649)
    }

    @Test
    func testSaveSetsDayOfMonthOnlyForMonthly() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.frequency = "monthly"
        viewModel.dayOfMonth = 15

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        viewModel.modelContext = context
        viewModel.save()

        let descriptor = FetchDescriptor<RecurringExpense>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.dayOfMonth == 15)
    }

    @Test
    func testSaveDoesNotSetDayOfMonthForNonMonthly() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.frequency = "weekly"

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        viewModel.modelContext = context
        viewModel.save()

        let descriptor = FetchDescriptor<RecurringExpense>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.dayOfMonth == nil)
    }

    @Test
    func testSaveWithEndDatePersistsEndDate() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Entertainment"
        viewModel.hasEndDate = true
        viewModel.endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        viewModel.modelContext = context
        viewModel.save()

        let descriptor = FetchDescriptor<RecurringExpense>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.endDate != nil)
    }

    @Test
    func testSaveWithoutEndDateSetsNilEndDate() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Subscription"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Entertainment"
        viewModel.hasEndDate = false

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        viewModel.modelContext = context
        viewModel.save()

        let descriptor = FetchDescriptor<RecurringExpense>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.endDate == nil)
    }

    @Test
    func testSaveWithNotesPersistsNotes() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.notes = "Test notes"

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        viewModel.modelContext = context
        viewModel.save()

        let descriptor = FetchDescriptor<RecurringExpense>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.notes == "Test notes")
    }

    @Test
    func testSaveWithEmptyNotesSetsNil() {
        let viewModel = AddRecurringExpenseViewModel()
        viewModel.name = "Test"
        viewModel.amount = "100"
        viewModel.selectedCategory = "Food"
        viewModel.notes = ""

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        viewModel.modelContext = context
        viewModel.save()

        let descriptor = FetchDescriptor<RecurringExpense>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.notes == nil)
    }
}
