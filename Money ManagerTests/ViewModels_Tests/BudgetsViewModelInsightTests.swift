import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for BudgetsViewModel: insightIcon, insightColor,
/// projectedMonthEnd, daysRemaining and dailyAverage behaviors.
@MainActor
struct BudgetsViewModelInsightTests {

    // Fixed mid-month reference: January 15, 2026
    private static let calendar = Calendar.current
    private static let fixedRef = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
    private static let fixedYear = 2026
    private static let fixedMonth = 1

    private func makeVM() -> BudgetsViewModel {
        let vm = BudgetsViewModel()
        vm.referenceDate = Self.fixedRef
        vm.selectedMonth = Self.fixedRef
        return vm
    }

    private func makeBudget(limit: Double) -> MonthlyBudget {
        MonthlyBudget(year: Self.fixedYear, month: Self.fixedMonth, limit: limit)
    }

    // MARK: - insightIcon

    @Test func testInsightIconIsCheckmarkWhenNoBudgetSet() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.insightIcon == "checkmark.circle.fill")
    }

    @Test func testInsightIconIsExclamationWhenOverBudget() {
        let vm = makeVM()
        let budget = makeBudget(limit: 500)
        let tx = Transaction(amount: 600, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [tx], budgets: [budget], modelContext: nil)
        #expect(vm.insightIcon == "exclamationmark.triangle.fill")
    }

    @Test func testInsightIconIsCheckmarkWhenOnTrack() {
        let vm = makeVM()
        let budget = makeBudget(limit: 5000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.insightIcon == "checkmark.circle.fill")
    }

    // MARK: - insightColor

    @Test func testInsightColorIsPositiveWhenNoBudgetSet() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.insightColor == AppColors.positive)
    }

    @Test func testInsightColorIsExpenseWhenOverBudget() {
        let vm = makeVM()
        let budget = makeBudget(limit: 200)
        let tx = Transaction(amount: 300, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [tx], budgets: [budget], modelContext: nil)
        #expect(vm.insightColor == AppColors.expense)
    }

    @Test func testInsightColorIsPositiveWhenOnTrack() {
        let vm = makeVM()
        let budget = makeBudget(limit: 10000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.insightColor == AppColors.positive)
    }

    // MARK: - daysRemaining

    @Test func testDaysRemainingIsPositiveInCurrentMonth() {
        // Fixed reference: Jan 15. Jan has 31 days → 17 days remain (Jan 15 to Feb 1).
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.daysRemaining == 17)
    }

    // MARK: - dailyAverage

    @Test func testDailyAverageIsZeroWhenNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], budgets: [], modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }

    @Test func testDailyAverageIsPositiveWhenBudgetRemainsAndDaysLeft() {
        // Fixed mid-month reference guarantees daysRemaining > 0
        let vm = makeVM()
        let budget = makeBudget(limit: 3000)
        vm.configure(allTransactions: [], budgets: [budget], modelContext: nil)
        #expect(vm.dailyAverage > 0)
    }
}
