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

    private func tx(amount: Double, type: TransactionKind = .expense, categoryId: UUID = UUID(), onDay day: Int = 15) -> Transaction {
        Transaction(type: type, amount: amount, categoryId: categoryId, date: makeDate(2026, 1, day))
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
            tx(amount: 500, type: .income),
            tx(amount: 100, type: .expense),
            tx(amount: 200, type: .expense),
        ]
        let spending = Spending.from(transactions: transactions, in: jan2026())
        #expect(spending.income == 500)
        #expect(spending.expense == 300)
    }

    // MARK: - Date filtering

    @Test func testPartialDateOverlap_includesOnlyTransactionsInInterval() {
        let inside  = Transaction(type: .expense, amount: 100, categoryId: UUID(), date: makeDate(2026, 1, 15))
        let outside = Transaction(type: .expense, amount: 999, categoryId: UUID(), date: makeDate(2026, 2, 1))
        let spending = Spending.from(transactions: [inside, outside], in: jan2026())
        #expect(spending.filtered.count == 1)
        #expect(spending.expense == 100)
    }

    @Test func testTransactionAtIntervalStart_isIncluded_legacyInterval() {
        // jan2026() uses a closed-end interval (23:59:59); only the start boundary test is meaningful here.
        let first = Transaction(type: .expense, amount: 10, categoryId: UUID(), date: makeDate(2026, 1, 1, hour: 0, minute: 0, second: 0))
        let spending = Spending.from(transactions: [first], in: jan2026())
        #expect(spending.filtered.count == 1)
    }

    // MARK: - Half-open interval boundary (midnight-to-midnight, matches monthInterval output)

    private func jan2026HalfOpen() -> DateInterval {
        // Matches Calendar.monthInterval(for:): start inclusive, end exclusive (midnight Feb 1).
        DateInterval(
            start: makeDate(2026, 1, 1, hour: 0),
            end:   makeDate(2026, 2, 1, hour: 0)
        )
    }

    @Test func testTransactionAtIntervalEnd_isExcluded() {
        // A transaction at exactly midnight Feb 1 must NOT appear in January.
        let feb1Midnight = Transaction(type: .expense, amount: 999, categoryId: UUID(),
                                       date: makeDate(2026, 2, 1, hour: 0, minute: 0, second: 0))
        let spending = Spending.from(transactions: [feb1Midnight], in: jan2026HalfOpen())
        #expect(spending.filtered.isEmpty)
        #expect(spending.expense == 0)
    }

    @Test func testTransactionAtIntervalStart_isIncluded() {
        // A transaction at exactly midnight Jan 1 must appear in January.
        let jan1Midnight = Transaction(type: .expense, amount: 100, categoryId: UUID(),
                                       date: makeDate(2026, 1, 1, hour: 0, minute: 0, second: 0))
        let spending = Spending.from(transactions: [jan1Midnight], in: jan2026HalfOpen())
        #expect(spending.filtered.count == 1)
        #expect(spending.expense == 100)
    }

    @Test func testTransactionJustBeforeIntervalEnd_isIncluded() {
        // Jan 31 23:59:59 is still within January.
        let lastSecond = Transaction(type: .expense, amount: 50, categoryId: UUID(),
                                     date: makeDate(2026, 1, 31, hour: 23, minute: 59, second: 59))
        let spending = Spending.from(transactions: [lastSecond], in: jan2026HalfOpen())
        #expect(spending.filtered.count == 1)
    }

    // MARK: - Search

    @Test func testSearchHit_matchesCategoryName() {
        let foodId = UUID()
        let foodCat = Category(id: foodId, name: "Food", icon: "fork.knife", color: "#FF0000")
        let gymId = UUID()
        let gymCat = Category(id: gymId, name: "Health", icon: "heart", color: "#00FF00")
        let food = tx(amount: 100, categoryId: foodId)
        let gym  = tx(amount: 50, categoryId: gymId)
        let lookup = CategoryResolver.makeLookup(from: [foodCat, gymCat])
        let spending = Spending.from(transactions: [food, gym], in: jan2026(), search: "Food", categoryLookup: lookup)
        #expect(spending.filtered.count == 1)
    }

    @Test func testSearchHit_matchesDescription() {
        let t = Transaction(type: .expense, amount: 200, categoryId: UUID(), date: makeDate(2026, 1, 10), transactionDescription: "Uber ride")
        let spending = Spending.from(transactions: [t], in: jan2026(), search: "uber")
        #expect(spending.filtered.count == 1)
    }

    @Test func testSearchHit_matchesNotes() {
        let t = Transaction(type: .expense, amount: 50, categoryId: UUID(), date: makeDate(2026, 1, 10), notes: "birthday dinner")
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
        let foodId = UUID()
        let salaryId = UUID()
        let transactions = [
            tx(amount: 100, type: .expense, categoryId: foodId),
            tx(amount: 200, type: .expense, categoryId: foodId),
            tx(amount: 300, type: .income, categoryId: salaryId),
        ]
        let spending = Spending.from(transactions: transactions, in: jan2026())
        #expect(spending.byCategory[foodId] == 300)
        #expect(spending.byCategory[salaryId] == nil)
    }

    @Test func testByCategory_aggregatesMultipleCategories() {
        let foodId = UUID()
        let transportId = UUID()
        let transactions = [
            tx(amount: 100, categoryId: foodId),
            tx(amount: 50, categoryId: transportId),
            tx(amount: 80, categoryId: foodId),
        ]
        let spending = Spending.from(transactions: transactions, in: jan2026())
        #expect(spending.byCategory[foodId] == 180)
        #expect(spending.byCategory[transportId] == 50)
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
