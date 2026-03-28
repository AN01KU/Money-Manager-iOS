import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringTransactionServiceTests {

    @Test
    func testGeneratePendingTransactionsSkipsInactive() {
        let inactive = RecurringTransaction(
            name: "Old",
            amount: 100,
            category: "Other",
            frequency: "monthly",
            startDate: Date(),
            isActive: false
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(inactive)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.isEmpty)
    }

    @Test
    func testGeneratePendingTransactionsCreatesTransactionForActive() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.count == 1)
        #expect(transactions.first?.transactionDescription == "Netflix")
        #expect(transactions.first?.amount == 649)
        #expect(transactions.first?.category == "Entertainment")
    }

    @Test
    func testGeneratePendingTransactionsUpdatesLastAddedDate() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        #expect(recurring.lastAddedDate == nil)

        RecurringTransactionService.generatePendingTransactions(context: context)

        #expect(recurring.lastAddedDate != nil)
    }

    @Test
    func testGeneratePendingTransactionsDoesNotDuplicateOnSameDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)!

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: today,
            isActive: true,
            lastAddedDate: nextMonth
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.isEmpty)
    }

    @Test
    func testGeneratePendingTransactionsSetsRecurringTransactionId() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        let recurringId = recurring.id

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.first?.recurringExpenseId == recurringId)
    }

    @Test
    func testGeneratePendingTransactionsSetsDescriptionFromName() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix Subscription",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.first?.transactionDescription == "Netflix Subscription")
    }

    @Test
    func testGeneratePendingTransactionsCopiesNotes() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true,
            notes: "Monthly subscription"
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.first?.notes == "Monthly subscription")
    }

    @Test
    func testGeneratePendingTransactionsCalledTwiceDoesNotCreateDuplicates() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let schema = Schema([Transaction.self, RecurringTransaction.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = ModelContext(container)

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)
        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.count == 1)
    }
}
