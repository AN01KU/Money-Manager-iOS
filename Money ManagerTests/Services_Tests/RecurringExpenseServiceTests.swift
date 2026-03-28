import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringExpenseServiceTests {

    @Test
    func testGeneratePendingExpensesSkipsInactive() {
        let inactive = RecurringExpense(
            name: "Old",
            amount: 100,
            category: "Other",
            frequency: "monthly",
            startDate: Date(),
            isActive: false
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(inactive)
        try? context.save()

        RecurringExpenseService.generatePendingExpenses(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.isEmpty)
    }

    @Test
    func testGeneratePendingExpensesCreatesExpenseForActive() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringExpenseService.generatePendingExpenses(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.count == 1)
        #expect(expenses.first?.transactionDescription == "Netflix")
        #expect(expenses.first?.amount == 649)
        #expect(expenses.first?.category == "Entertainment")
    }

    @Test
    func testGeneratePendingExpensesUpdatesLastAddedDate() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        #expect(recurring.lastAddedDate == nil)

        RecurringExpenseService.generatePendingExpenses(context: context)

        #expect(recurring.lastAddedDate != nil)
    }

    @Test
    func testGeneratePendingExpensesDoesNotDuplicateOnSameDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)!

        let recurring = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: today,
            isActive: true,
            lastAddedDate: nextMonth
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringExpenseService.generatePendingExpenses(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.isEmpty)
    }

    @Test
    func testGeneratePendingExpensesSetsRecurringExpenseId() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        let recurringId = recurring.id

        RecurringExpenseService.generatePendingExpenses(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.recurringExpenseId == recurringId)
    }

    @Test
    func testGeneratePendingExpensesSetsExpenseDescriptionFromName() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringExpense(
            name: "Netflix Subscription",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringExpenseService.generatePendingExpenses(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.transactionDescription == "Netflix Subscription")
    }

    @Test
    func testGeneratePendingExpensesCopiesNotes() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true,
            notes: "Monthly subscription"
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringExpenseService.generatePendingExpenses(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.first?.notes == "Monthly subscription")
    }

    @Test
    func testGeneratePendingExpensesCalledTwiceDoesNotCreateDuplicates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringExpense(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringExpenseService.generatePendingExpenses(context: context)
        RecurringExpenseService.generatePendingExpenses(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = (try? context.fetch(descriptor)) ?? []

        #expect(expenses.count == 1)
    }
}
