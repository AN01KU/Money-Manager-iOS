import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetsViewModelTests {

    // Fixed mid-month reference: January 15, 2026 — never the 1st or last day of any month.
    private static let calendar = Calendar.current
    private static let fixedRef = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
    private static let fixedYear = 2026
    private static let fixedMonth = 1

    private func makeVM(referenceDate: Date = fixedRef) -> BudgetsViewModel {
        let vm = BudgetsViewModel()
        vm.referenceDate = referenceDate
        vm.selectedMonth = referenceDate
        return vm
    }

    @Test
    func testTotalSpentCalculatesCorrectly() {
        let vm = makeVM()
        let expense1 = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let expense2 = Transaction(amount: 300, category: "Transport", date: Self.fixedRef)
        vm.configure(allTransactions: [expense1, expense2], budgets: [], modelContext: nil)
        #expect(vm.totalSpent == 800)
    }

    @Test
    func testTotalSpentIgnoresDeletedTransactions() {
        let vm = makeVM()
        let active = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let deleted = Transaction(amount: 300, category: "Transport", date: Self.fixedRef)
        deleted.isSoftDeleted = true
        vm.configure(allTransactions: [active, deleted], budgets: [], modelContext: nil)
        #expect(vm.totalSpent == 500)
    }

    @Test
    func testTotalSpentReturnsZeroForNoTransactions() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.totalSpent == 0)
    }

    @Test
    func testRemainingBudgetWhenNoBudgetSet() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.remainingBudget == 0)
    }

    @Test
    func testRemainingBudgetCalculatesCorrectly() {
        let vm = makeVM()
        let expense = Transaction(amount: 300, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.remainingBudget == 700)
    }

    @Test
    func testRemainingBudgetNeverNegative() {
        let vm = makeVM()
        let expense = Transaction(amount: 1500, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.remainingBudget == 0)
    }

    @Test
    func testBudgetPercentageCalculatesCorrectly() {
        let vm = makeVM()
        let expense = Transaction(amount: 250, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.budgetPercentage == 25)
    }

    @Test
    func testBudgetPercentageIsZeroWhenNoBudget() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [expense], budgets: [], modelContext: nil)
        #expect(vm.budgetPercentage == 0)
    }

    @Test
    func testBudgetPercentageIsZeroWhenLimitIsZero() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 0)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.budgetPercentage == 0)
    }

    @Test
    func testBudgetPercentageAtLimit() {
        let vm = makeVM()
        let expense = Transaction(amount: 1000, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.budgetPercentage == 100)
    }

    @Test
    func testBudgetPercentageOverBudget() {
        let vm = makeVM()
        let expense = Transaction(amount: 1500, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.budgetPercentage == 150)
    }

    @Test
    func testDailyAverageCalculatesCorrectly() {
        let vm = makeVM()
        let expense = Transaction(amount: 200, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.dailyAverage > 0)
    }

    @Test
    func testDailyAverageIsZeroWhenNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }

    @Test
    func testCurrentBudgetFindsCorrectMonth() {
        let vm = makeVM()
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 5000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.currentBudget?.limit == 5000)
    }

    @Test
    func testCurrentMonthTransactionsFiltersByMonth() {
        let calendar = Calendar.current
        let vm = makeVM()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Self.fixedRef)!
        let expenseThisMonth = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let expenseLastMonth = Transaction(amount: 300, category: "Food", date: lastMonth)
        vm.configure(allTransactions: [expenseThisMonth, expenseLastMonth], budgets: [], modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
        #expect(vm.currentMonthTransactions.first?.amount == 500)
    }

    // MARK: - Days Remaining Tests

    @Test
    func testDaysRemainingCalculatesForCurrentMonth() {
        // Fixed reference: Jan 15, 2026. Jan has 31 days; 16 days remain (16th–31st).
        let vm = makeVM()
        // Jan 15 is the referenceDate → 17 days remain (15th to midnight Feb 1 = 17 days)
        // startOfDay(Jan 15) to startOfDay(Feb 1) = 17 days
        #expect(vm.daysRemaining == 17)
    }

    @Test
    func testDaysRemainingReturnsZeroForPastMonth() {
        let vm = BudgetsViewModel()
        // Reference is today; selected month is last month relative to reference
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
        let budget = MonthlyBudget(year: 2025, month: 12, limit: 1000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }

    // MARK: - Current Budget Tests

    @Test
    func testCurrentBudgetReturnsNilWhenNoBudgets() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.currentBudget == nil)
    }

    @Test
    func testCurrentBudgetReturnsNilWhenNoMatchingMonth() {
        let vm = makeVM()
        let budget = MonthlyBudget(year: 2020, month: 1, limit: 1000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.currentBudget == nil)
    }

    @Test
    func testCurrentBudgetFindsCorrectYearAndMonth() {
        let vm = makeVM()
        let budget1 = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 5000)
        let budget2 = MonthlyBudget(year: Self.fixedYear + 1, month: Self.fixedMonth, limit: 6000)
        vm.configure(allTransactions: [], budgets: [budget1, budget2], modelContext: nil)
        #expect(vm.currentBudget?.limit == 5000)
    }

    // MARK: - Month boundary edge cases

    @Test
    func testCurrentMonthTransactionsIncludesTransactionOnLastDayOfMonth() {
        let vm = makeVM()
        let lastDayOfJan = Self.calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let expense = Transaction(amount: 500, category: "Food", date: lastDayOfJan)
        vm.configure(allTransactions: [expense], budgets: [], modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
    }

    @Test
    func testCurrentMonthTransactionsExcludesTransactionOnFirstDayOfNextMonth() {
        let vm = makeVM()
        let firstDayOfFeb = Self.calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let expense = Transaction(amount: 500, category: "Transport", date: firstDayOfFeb)
        vm.configure(allTransactions: [expense], budgets: [], modelContext: nil)
        #expect(vm.currentMonthTransactions.isEmpty)
    }

    @Test
    func testCurrentMonthTransactionsIncludesTransactionOnFirstDayOfMonth() {
        let vm = makeVM()
        let firstDayOfJan = Self.calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let expense = Transaction(amount: 300, category: "Food", date: firstDayOfJan)
        vm.configure(allTransactions: [expense], budgets: [], modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
    }

    // MARK: - currentMonthTransactions: income exclusion

    @Test
    func testCurrentMonthTransactionsExcludesIncomeTransactions() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let income = Transaction(type: .income, amount: 2000, category: "Salary", date: Self.fixedRef)
        vm.configure(allTransactions: [expense, income], budgets: [], modelContext: nil)
        #expect(vm.currentMonthTransactions.count == 1)
        #expect(vm.currentMonthTransactions.first?.category == "Food")
    }

    // MARK: - projectedMonthEnd

    @Test
    func testProjectedMonthEndIsPositiveForCurrentMonth() {
        let vm = makeVM()
        let expense = Transaction(amount: 500, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 5000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
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
        vm.configure(allTransactions: [expense], budgets: [], modelContext: nil)
        // Past month: daysElapsed == full month length, daysLeft == 0 → projected == totalSpent
        #expect(vm.projectedMonthEnd == vm.totalSpent)
    }

    // MARK: - spendingInsight

    @Test
    func testSpendingInsightNilWhenNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testSpendingInsightNilForPastMonth() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let lastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        let year = Self.calendar.component(.year, from: lastMonth)
        let month = Self.calendar.component(.month, from: lastMonth)
        vm.referenceDate = ref
        vm.selectedMonth = lastMonth
        let budget = MonthlyBudget(year: year, month: month, limit: 5000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testSpendingInsightExceededBudgetMessage() {
        // Fixed mid-month reference guarantees daysElapsed > 1
        let vm = makeVM()
        let expense = Transaction(amount: 2000, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        // daysElapsed == 15 (Jan 15), guaranteed > 1 → insight must be non-nil
        #expect(vm.spendingInsight?.contains("exceeded") == true)
    }

    @Test
    func testSpendingInsightOnTrackMessage() {
        // Fixed mid-month reference guarantees daysElapsed > 1 → insight always runs
        let vm = makeVM()
        let expense = Transaction(amount: 1, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 1_000_000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.spendingInsight?.contains("On track") == true)
    }

    @Test
    func testSpendingInsightNilWhenDaysElapsedIsOne() {
        // Inject the 1st of the month as both selectedMonth and referenceDate
        // so daysElapsed == 1 and the guard fires → insight is nil
        let firstOfJan = Self.calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let vm = BudgetsViewModel()
        vm.referenceDate = firstOfJan
        vm.selectedMonth = firstOfJan
        let expense = Transaction(amount: 500, category: "Food", date: firstOfJan)
        let budget = MonthlyBudget(year: 2026, month: 1, limit: 1000)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testSpendingInsightZeroLimitBudgetReturnsNil() {
        let vm = makeVM()
        let expense = Transaction(amount: 100, category: "Food", date: Self.fixedRef)
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 0)
        vm.configure(allTransactions: [expense], budgets: [budget], modelContext: nil)
        #expect(vm.spendingInsight == nil)
    }

    @Test
    func testDaysRemainingIsZeroForPastMonth() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let pastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = pastMonth
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.daysRemaining == 0)
    }

    @Test
    func testDailyAverageIsZeroWhenNoDaysRemaining() {
        let vm = BudgetsViewModel()
        let ref = Self.fixedRef
        let pastMonth = Self.calendar.date(byAdding: .month, value: -1, to: ref)!
        vm.referenceDate = ref
        vm.selectedMonth = pastMonth
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }

    @Test
    func testCurrentBudgetReturnsNilForMonthWithNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.currentBudget == nil)
    }

    @Test
    func testCurrentBudgetMatchesYearAndMonth() {
        let vm = makeVM()
        let budget = MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: 500)
        let otherBudget = MonthlyBudget(year: Self.fixedYear - 1, month: Self.fixedMonth, limit: 200)
        vm.configure(allTransactions: [], budgets: [budget, otherBudget], modelContext: nil)
        #expect(vm.currentBudget?.limit == 500)
    }
}
