import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for BudgetsViewModel: insightIcon, insightColor,
/// projectedMonthEnd, daysRemaining and dailyAverage behaviors.
@MainActor
struct BudgetsViewModelInsightTests {

    private func currentYearMonth() -> (year: Int, month: Int) {
        let calendar = Calendar.current
        let now = Date()
        return (calendar.component(.year, from: now), calendar.component(.month, from: now))
    }

    private func makeBudget(limit: Double) -> MonthlyBudget {
        let (year, month) = currentYearMonth()
        return MonthlyBudget(year: year, month: month, limit: limit)
    }

    // MARK: - insightIcon

    @Test func testInsightIconIsCheckmarkWhenNoBudgetSet() {
        let vm = BudgetsViewModel()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.insightIcon == "checkmark.circle.fill")
    }

    @Test func testInsightIconIsExclamationWhenOverBudget() {
        let vm = BudgetsViewModel()
        let budget = makeBudget(limit: 500)
        let tx = Transaction(amount: 600, category: "Food", date: Date())
        vm.configure(allTransactions: [tx], budgets: [budget], modelContext: nil)
        #expect(vm.insightIcon == "exclamationmark.triangle.fill")
    }

    @Test func testInsightIconIsCheckmarkWhenOnTrack() {
        // No transactions — projected spend is 0, well under any limit
        let vm = BudgetsViewModel()
        let budget = makeBudget(limit: 5000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.insightIcon == "checkmark.circle.fill")
    }

    // MARK: - insightColor

    @Test func testInsightColorIsPositiveWhenNoBudgetSet() {
        let vm = BudgetsViewModel()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.insightColor == AppColors.positive)
    }

    @Test func testInsightColorIsExpenseWhenOverBudget() {
        let vm = BudgetsViewModel()
        let budget = makeBudget(limit: 200)
        let tx = Transaction(amount: 300, category: "Food", date: Date())
        vm.configure(allTransactions: [tx], budgets: [budget], modelContext: nil)
        #expect(vm.insightColor == AppColors.expense)
    }

    @Test func testInsightColorIsPositiveWhenOnTrack() {
        let vm = BudgetsViewModel()
        let budget = makeBudget(limit: 10000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.insightColor == AppColors.positive)
    }

    // MARK: - daysRemaining

    @Test func testDaysRemainingIsPositiveInCurrentMonth() {
        let vm = BudgetsViewModel()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        // daysRemaining should be non-negative
        #expect(vm.daysRemaining >= 0)
    }

    // MARK: - dailyAverage

    @Test func testDailyAverageIsZeroWhenNoBudget() {
        let vm = BudgetsViewModel()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        // No budget → remainingBudget is 0 → daysRemaining irrelevant
        #expect(vm.dailyAverage == 0)
    }

    @Test func testDailyAverageIsPositiveWhenBudgetRemainsAndDaysLeft() {
        let vm = BudgetsViewModel()
        let budget = makeBudget(limit: 3000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        // If we're not at month end, daysRemaining > 0 and dailyAverage > 0
        if vm.daysRemaining > 0 {
            #expect(vm.dailyAverage > 0)
        }
    }
}
