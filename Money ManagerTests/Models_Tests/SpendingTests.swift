import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct SpendingTests {

    // MARK: - Helpers

    private func jan2026() -> DateInterval {
        DateInterval(
            start: makeDate(2026, 1, 1, hour: 0),
            end: makeDate(2026, 1, 31, hour: 23, minute: 59, second: 59)
        )
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0, second: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute; comps.second = second
        return Calendar.current.date(from: comps)!
    }

    private func tx(amount: Double, type: TransactionKind = .expense, category: String = "Food", onDay day: Int = 15) -> Transaction {
        Transaction(type: type, amount: amount, category: category, date: makeDate(2026, 1, day))
    }

    // MARK: - Empty input

    @Test func testEmptyTransactions_producesZeroSpending() {
        let spending = Spending.from(transactions: [], in: jan2026())
        #expect(spending.income == 0)
        #expect(spending.expense == 0)
        #expect(spending.byCategory.isEmpty)
        #expect(spending.filtered.isEmpty)
    }

    // MARK: - Mixed types

    @Test func testMixedTypes_separatesIncomeAndExpense() {
        let transactions = [
            tx(amount: 500, type: .income, category: "Salary"),
            tx(amount: 100, type: .expense, category: "Food"),
            tx(amount: 200, type: .expense, category: "Transport"),
        ]
        let spending = Spending.from(transactions: transactions, in: jan2026())
        #expect(spending.income == 500)
        #expect(spending.expense == 300)
    }

    // MARK: - Date filtering

    @Test func testPartialDateOverlap_includesOnlyTransactionsInInterval() {
        let inside  = Transaction(type: .expense, amount: 100, category: "Food", date: makeDate(2026, 1, 15))
        let outside = Transaction(type: .expense, amount: 999, category: "Food", date: makeDate(2026, 2, 1))
        let spending = Spending.from(transactions: [inside, outside], in: jan2026())
        #expect(spending.filtered.count == 1)
        #expect(spending.expense == 100)
    }

    @Test func testTransactionOnIntervalBoundary_isIncluded() {
        let first = Transaction(type: .expense, amount: 10, category: "Food", date: makeDate(2026, 1, 1, hour: 0, minute: 0, second: 0))
        let last  = Transaction(type: .expense, amount: 20, category: "Food", date: makeDate(2026, 1, 31, hour: 23, minute: 59, second: 59))
        let spending = Spending.from(transactions: [first, last], in: jan2026())
        #expect(spending.filtered.count == 2)
    }

    // MARK: - Search

    @Test func testSearchHit_matchesCategory() {
        let food = tx(amount: 100, category: "Food")
        let gym  = tx(amount: 50,  category: "Health")
        let spending = Spending.from(transactions: [food, gym], in: jan2026(), search: "Food")
        #expect(spending.filtered.count == 1)
        #expect(spending.filtered.first?.category == "Food")
    }

    @Test func testSearchHit_matchesDescription() {
        let t = Transaction(type: .expense, amount: 200, category: "Travel", date: makeDate(2026, 1, 10), transactionDescription: "Uber ride")
        let spending = Spending.from(transactions: [t], in: jan2026(), search: "uber")
        #expect(spending.filtered.count == 1)
    }

    @Test func testSearchHit_matchesNotes() {
        let t = Transaction(type: .expense, amount: 50, category: "Food", date: makeDate(2026, 1, 10), notes: "birthday dinner")
        let spending = Spending.from(transactions: [t], in: jan2026(), search: "birthday")
        #expect(spending.filtered.count == 1)
    }

    @Test func testSearchMiss_returnsEmptyFiltered() {
        let t = tx(amount: 100)
        let spending = Spending.from(transactions: [t], in: jan2026(), search: "zzznomatch")
        #expect(spending.filtered.isEmpty)
    }

    @Test func testEmptySearch_includesAll() {
        let transactions = [tx(amount: 100), tx(amount: 200)]
        let spending = Spending.from(transactions: transactions, in: jan2026(), search: "")
        #expect(spending.filtered.count == 2)
    }

    @Test func testNilSearch_includesAll() {
        let transactions = [tx(amount: 100), tx(amount: 200)]
        let spending = Spending.from(transactions: transactions, in: jan2026(), search: nil)
        #expect(spending.filtered.count == 2)
    }

    // MARK: - Category grouping

    @Test func testByCategory_groupsExpensesOnly() {
        let transactions = [
            tx(amount: 100, type: .expense, category: "Food"),
            tx(amount: 200, type: .expense, category: "Food"),
            tx(amount: 300, type: .income,  category: "Salary"),
        ]
        let spending = Spending.from(transactions: transactions, in: jan2026())
        #expect(spending.byCategory["Food"] == 300)
        #expect(spending.byCategory["Salary"] == nil)
    }

    @Test func testByCategory_aggregatesMultipleCategories() {
        let transactions = [
            tx(amount: 100, category: "Food"),
            tx(amount: 50,  category: "Transport"),
            tx(amount: 80,  category: "Food"),
        ]
        let spending = Spending.from(transactions: transactions, in: jan2026())
        #expect(spending.byCategory["Food"] == 180)
        #expect(spending.byCategory["Transport"] == 50)
    }

    // MARK: - Decimal precision

    @Test func testDecimalPrecision_noFloatingPointAccumulation() {
        let transactions = [
            tx(amount: 0.1),
            tx(amount: 0.2),
        ]
        let spending = Spending.from(transactions: transactions, in: jan2026())
        #expect(spending.expense == Decimal(string: "0.3")!)
    }

    // MARK: - Soft-deleted transactions are excluded

    @Test func testSoftDeletedTransactions_areExcluded() {
        let active  = tx(amount: 100)
        let deleted = tx(amount: 999)
        deleted.isSoftDeleted = true
        let spending = Spending.from(transactions: [active, deleted], in: jan2026())
        #expect(spending.filtered.count == 1)
        #expect(spending.expense == 100)
    }
}
