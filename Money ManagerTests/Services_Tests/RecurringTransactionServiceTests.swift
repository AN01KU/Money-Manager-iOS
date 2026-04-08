import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringTransactionServiceTests {

    @Test
    func testGeneratePendingTransactionsSkipsInactive() throws {
        let inactive = RecurringTransaction(
            name: "Old",
            amount: 100,
            category: "Other",
            frequency: .monthly,
            startDate: Date(),
            isActive: false
        )

        let context = ModelContext(try makeTestContainer())

        context.insert(inactive)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.isEmpty)
    }

    @Test
    func testGeneratePendingTransactionsCreatesTransactionForActive() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let context = ModelContext(try makeTestContainer())

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
    func testGeneratePendingTransactionsUpdatesLastAddedDate() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let context = ModelContext(try makeTestContainer())

        context.insert(recurring)
        try? context.save()

        #expect(recurring.lastAddedDate == nil)

        RecurringTransactionService.generatePendingTransactions(context: context)

        #expect(recurring.lastAddedDate != nil)
    }

    @Test
    func testGeneratePendingTransactionsDoesNotDuplicateOnSameDay() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)!

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: today,
            isActive: true,
            lastAddedDate: nextMonth
        )

        let context = ModelContext(try makeTestContainer())

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.isEmpty)
    }

    @Test
    func testGeneratePendingTransactionsSetsRecurringTransactionId() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let context = ModelContext(try makeTestContainer())

        context.insert(recurring)
        try? context.save()

        let recurringId = recurring.id

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.first?.recurringExpenseId == recurringId)
    }

    @Test
    func testGeneratePendingTransactionsSetsDescriptionFromName() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix Subscription",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let context = ModelContext(try makeTestContainer())

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.first?.transactionDescription == "Netflix Subscription")
    }

    @Test
    func testGeneratePendingTransactionsCopiesNotes() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true,
            notes: "Monthly subscription"
        )

        let context = ModelContext(try makeTestContainer())

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.first?.notes == "Monthly subscription")
    }

    @Test
    func testGeneratePendingTransactionsCalledTwiceDoesNotCreateDuplicates() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true
        )

        let context = ModelContext(try makeTestContainer())

        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)
        RecurringTransactionService.generatePendingTransactions(context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let transactions = (try? context.fetch(descriptor)) ?? []

        #expect(transactions.count == 1)
    }

    @Test("Skips soft-deleted recurring items")
    func testSkipsSoftDeletedItems() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Deleted Sub",
            amount: 199,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true,
            isSoftDeleted: true
        )

        let context = ModelContext(try makeTestContainer())
        context.insert(recurring)

        RecurringTransactionService.generatePendingTransactions(context: context)

        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        #expect(transactions.isEmpty)
    }

    @Test("Does not generate a transaction past the end date")
    func testSkipsItemsPastEndDate() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Daily frequency so nextOccurrence is tomorrow — but endDate is yesterday,
        // so nextOccurrence returns nil and service skips it.
        let recurring = RecurringTransaction(
            name: "Expired Sub",
            amount: 99,
            category: "Entertainment",
            frequency: .daily,
            startDate: calendar.date(byAdding: .day, value: -5, to: today)!,
            endDate: calendar.date(byAdding: .day, value: -1, to: today)!,
            isActive: true
        )

        let context = ModelContext(try makeTestContainer())
        context.insert(recurring)

        RecurringTransactionService.generatePendingTransactions(context: context)

        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        #expect(transactions.isEmpty)
    }

    @Test("lastAddedDate is set to nextOccurrence after offline generation, preventing future duplicates")
    func testLastAddedDatePreventsSecondGeneration() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Daily item that is due — service will generate once and set lastAddedDate.
        // A second call should produce no new transaction because lastAddedDate >= nextOccurrence.
        let recurring = RecurringTransaction(
            name: "Gym",
            amount: 500,
            category: "Health",
            frequency: .daily,
            startDate: calendar.date(byAdding: .day, value: -1, to: today)!,
            isActive: true
        )

        let context = ModelContext(try makeTestContainer())
        context.insert(recurring)

        RecurringTransactionService.generatePendingTransactions(context: context)

        let lastAdded = recurring.lastAddedDate
        #expect(lastAdded != nil)

        // Second call: lastAddedDate is now set, so nextOccurrence <= lastAddedDay — skipped.
        RecurringTransactionService.generatePendingTransactions(context: context)

        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        #expect(transactions.count == 1)
    }

    @Test("Generates transactions for multiple due items in one pass")
    func testGeneratesForMultipleDueItems() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let context = ModelContext(try makeTestContainer())

        for i in 1...3 {
            let recurring = RecurringTransaction(
                name: "Sub \(i)",
                amount: Double(i * 100),
                category: "Entertainment",
                frequency: .monthly,
                startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
                isActive: true
            )
            context.insert(recurring)
        }

        RecurringTransactionService.generatePendingTransactions(context: context)

        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        #expect(transactions.count == 3)
    }

    // MARK: - Transaction type propagation

    @Test("Generated transaction inherits income type from recurring record")
    func testGeneratedTransactionInheritsIncomeType() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Salary",
            amount: 50000,
            category: "Income",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true,
            type: .income
        )

        let context = ModelContext(try makeTestContainer())
        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        #expect(transactions.first?.type == .income)
    }

    @Test("Generated transaction inherits expense type from recurring record")
    func testGeneratedTransactionInheritsExpenseType() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: calendar.date(byAdding: .month, value: -1, to: today)!,
            isActive: true,
            type: .expense
        )

        let context = ModelContext(try makeTestContainer())
        context.insert(recurring)
        try? context.save()

        RecurringTransactionService.generatePendingTransactions(context: context)

        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        #expect(transactions.first?.type == .expense)
    }
}
