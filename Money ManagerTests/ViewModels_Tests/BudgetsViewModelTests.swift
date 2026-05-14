import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetsViewModelTests {

    // Fixed mid-month reference: January 15, 2026 — never the 1st or last day of any month.
    private static let calendar = Calendar.current
    private static let fixedRef = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!

    private func makeVM(referenceDate: Date = fixedRef) -> BudgetsViewModel {
        let vm = BudgetsViewModel()
        vm.referenceDate = referenceDate
        vm.selectedMonth = referenceDate
        return vm
    }

    private func budget(limit: Double) -> UserBudget { UserBudget(limit: limit) }

    @Test
    func testTotalSpentCalculatesCorrectly() {
        let vm = makeVM()
        let expense1 = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let expense2 = Transaction(amount: 300, category: "Transport", date: Self.fixedRef)
        vm.configure(allTransactions: [expense1, expense2], userBudget: nil, modelContext: nil)
        #expect(vm.totalSpent == 800)
    }

    @Test
    func testTotalSpentIgnoresDeletedTransactions() {
        let vm = makeVM()
        let active = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let deleted = Transaction(amount: 300, category: "Transport", date: Self.fixedRef)
        deleted.isSoftDeleted = true
        vm.configure(allTransactions: [active, deleted], userBudget: nil, modelContext: nil)
        #expect(vm.totalSpent == 500)
    }

    @Test
    func testTotalSpentReturnsZeroForNoTransactions() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.totalSpent == 0)
    }

    @Test
    func testRemainingBudgetWhenNoBudgetSet() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.remainingBudget == 0)
    }

    @Test
    func testRemainingBudgetCalculatesCorrectly() {
        let vm = makeVM()
        let expense = Transaction(amount: 300, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.remainingBudget == 700)
    }

    @Test
    func testRemainingBudgetNeverNegative() {
        let vm = makeVM()
        let expense = Transaction(amount: 1500, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.remainingBudget == 0)
    }

    @Test
    func testBudgetPercentageCalculatesCorrectly() {
        let vm = makeVM()
        let expense = Transaction(amount: 250, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.budgetPercentage == 25)
    }

    @Test
    func testBudgetPercentageIsZeroWhenNoBudget() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: nil, modelContext: nil)
        #expect(vm.budgetPercentage == 0)
    }

    @Test
    func testBudgetPercentageIsZeroWhenLimitIsNil() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: UserBudget(limit: nil), modelContext: nil)
        #expect(vm.budgetPercentage == 0)
    }

    @Test
    func testBudgetPercentageAtLimit() {
        let vm = makeVM()
        let expense = Transaction(amount: 1000, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.budgetPercentage == 100)
    }

    @Test
    func testBudgetPercentageOverBudget() {
        let vm = makeVM()
        let expense = Transaction(amount: 1500, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.budgetPercentage == 150)
    }

    @Test
    func testDailyAverageCalculatesCorrectly() {
        let vm = makeVM()
        let expense = Transaction(amount: 200, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.dailyAverage > 0)
    }

    @Test
    func testDailyAverageIsZeroWhenNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }

    @Test
    func testBudgetLimitExposesScalar() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: budget(limit: 5000), modelContext: nil)
        #expect(vm.budgetLimit == 5000)
    }

    @Test
    func testBudgetLimitIsNilWhenNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.budgetLimit == nil)
    }

    @Test
    func testCurrentMonthTransactionsFiltersByMonth() {
        let calendar = Calendar.current
        let vm = makeVM()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Self.fixedRef)!
        let expenseThisMonth = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let expenseLastMonth = Transaction(amount: 300, category: "Food", date: lastMonth)
        vm.configure(allTransactions: [expenseThisMonth, expenseLastMonth], userBudget: nil, modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
        #expect(vm.currentMonthTransactions.first?.amount == 500)
    }

    // MARK: - Days Remaining Tests

    @Test
    func testDaysRemainingCalculatesForCurrentMonth() {
        // Fixed reference: Jan 15, 2026. Jan has 31 days.
        // startOfDay(Jan 15) to startOfDay(Feb 1) = 17 days
        let vm = makeVM()
        #expect(vm.daysRemaining == 17)
    }

    @Test
    func testDaysRemainingReturnsZeroForPastMonth() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let lastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = lastMonth
        #expect(vm.daysRemaining == 0)
    }

    @Test
    func testDaysRemainingReturnsZeroForFutureMonth() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let nextMonth = Self.calendar.date(byAdding: .month, value: 1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = nextMonth
        #expect(vm.daysRemaining == 0)
    }

    // MARK: - Daily Average Tests

    @Test
    func testDailyAverageIsZeroWhenDaysRemainingIsZero() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let lastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = lastMonth
        vm.configure(allTransactions: [], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }

    // MARK: - Month boundary edge cases

    @Test
    func testCurrentMonthTransactionsIncludesTransactionOnLastDayOfMonth() {
        let vm = makeVM()
        let lastDayOfJan = Self.calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let expense = Transaction(amount: 500, category: "Food", date: lastDayOfJan)
        vm.configure(allTransactions: [expense], userBudget: nil, modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
    }

    @Test
    func testCurrentMonthTransactionsExcludesTransactionOnFirstDayOfNextMonth() {
        let vm = makeVM()
        let firstDayOfFeb = Self.calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let expense = Transaction(amount: 500, category: "Transport", date: firstDayOfFeb)
        vm.configure(allTransactions: [expense], userBudget: nil, modelContext: nil)
        #expect(vm.currentMonthTransactions.isEmpty)
    }

    @Test
    func testCurrentMonthTransactionsIncludesTransactionOnFirstDayOfMonth() {
        let vm = makeVM()
        let firstDayOfJan = Self.calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let expense = Transaction(amount: 300, category: "Food", date: firstDayOfJan)
        vm.configure(allTransactions: [expense], userBudget: nil, modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
    }

    // MARK: - currentMonthTransactions: income exclusion

    @Test
    func testCurrentMonthTransactionsExcludesIncomeTransactions() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let income = Transaction(type: .income, amount: 2000, category: "Salary", date: Self.fixedRef)
        vm.configure(allTransactions: [expense, income], userBudget: nil, modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
        #expect(vm.currentMonthTransactions.first?.category == "Food")
    }

    // MARK: - projectedMonthEnd

    @Test
    func testProjectedMonthEndIsPositiveForCurrentMonth() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 5000), modelContext: nil)
        #expect(vm.projectedMonthEnd > 0)
    }

    @Test
    func testProjectedMonthEndForPastMonthUsesFullMonthRate() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let lastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        let startOfLastMonth = Self.calendar.date(from: Self.calendar.dateComponents([.year, .month], from: lastMonth))!
        vm.referenceDate = ref
        vm.selectedMonth = lastMonth
        let expense = Transaction(amount: 300, category: "Food", date: startOfLastMonth)
        vm.configure(allTransactions: [expense], userBudget: nil, modelContext: nil)
        // Past month: daysElapsed == full month length, daysLeft == 0 → projected == totalSpent
        #expect(vm.projectedMonthEnd == vm.totalSpent)
    }

    // MARK: - spendingInsight

    @Test
    func testSpendingInsightNilWhenNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testSpendingInsightNilForPastMonth() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let lastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = lastMonth
        vm.configure(allTransactions: [], userBudget: budget(limit: 5000), modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testSpendingInsightExceededBudgetMessage() {
        // Fixed mid-month reference guarantees daysElapsed > 1
        let vm = makeVM()
        let expense = Transaction(amount: 2000, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.spendingInsight?.contains("exceeded") == true)
    }

    @Test
    func testSpendingInsightOnTrackMessage() {
        // Fixed mid-month reference guarantees daysElapsed > 1 → insight always runs
        let vm = makeVM()
        let expense = Transaction(amount: 1, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1_000_000), modelContext: nil)
        #expect(vm.spendingInsight?.contains("On track") == true)
    }

    @Test
    func testSpendingInsightNilWhenDaysElapsedIsOne() {
        let firstOfJan = Self.calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let vm = BudgetsViewModel()
        vm.referenceDate = firstOfJan
        vm.selectedMonth = firstOfJan
        let expense = Transaction(amount: 500, category: "Food", date: firstOfJan)
        vm.configure(allTransactions: [expense], userBudget: budget(limit: 1000), modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testSpendingInsightNilLimitBudgetReturnsNil() {
        let vm = makeVM()
        let expense = Transaction(amount: 100, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], userBudget: UserBudget(limit: nil), modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testDaysRemainingIsZeroForPastMonth() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let pastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = pastMonth
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.daysRemaining == 0)
    }

    @Test
    func testDailyAverageIsZeroWhenNoDaysRemaining() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let pastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = pastMonth
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }
}
