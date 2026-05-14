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

    private func makeVM() -> BudgetsViewModel {
        let vm = BudgetsViewModel()
        vm.referenceDate = Self.fixedRef
        vm.selectedMonth = Self.fixedRef
        return vm
    }

    private func budget(limit: Double) -> UserBudget { UserBudget(limit: limit) }

    // MARK: - insightIcon

    @Test func testInsightIconIsCheckmarkWhenNoBudgetSet() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.insightIcon == "checkmark.circle.fill")
    }

    @Test func testInsightIconIsExclamationWhenOverBudget() {
        let vm = makeVM()
        let tx = Transaction(amount: 600, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [tx], userBudget: budget(limit: 500), modelContext: nil)
        #expect(vm.insightIcon == "exclamationmark.triangle.fill")
    }

    @Test func testInsightIconIsCheckmarkWhenOnTrack() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: budget(limit: 5000), modelContext: nil)
        #expect(vm.insightIcon == "checkmark.circle.fill")
    }

    // MARK: - insightColor

    @Test func testInsightColorIsPositiveWhenNoBudgetSet() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.insightColor == AppColors.positive)
    }

    @Test func testInsightColorIsExpenseWhenOverBudget() {
        let vm = makeVM()
        let tx = Transaction(amount: 300, category: "Food", date: Self.fixedRef)
        vm.configure(allTransactions: [tx], userBudget: budget(limit: 200), modelContext: nil)
        #expect(vm.insightColor == AppColors.expense)
    }

    @Test func testInsightColorIsPositiveWhenOnTrack() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: budget(limit: 10000), modelContext: nil)
        #expect(vm.insightColor == AppColors.positive)
    }

    // MARK: - daysRemaining

    @Test func testDaysRemainingIsPositiveInCurrentMonth() {
        // Fixed reference: Jan 15. Jan has 31 days → 17 days remain (Jan 15 to Feb 1).
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.daysRemaining == 17)
    }

    // MARK: - dailyAverage

    @Test func testDailyAverageIsZeroWhenNoBudget() {
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: nil, modelContext: nil)
        #expect(vm.dailyAverage == 0)
    }

    @Test func testDailyAverageIsPositiveWhenBudgetRemainsAndDaysLeft() {
        // Fixed mid-month reference guarantees daysRemaining > 0
        let vm = makeVM()
        vm.configure(allTransactions: [], userBudget: budget(limit: 3000), modelContext: nil)
        #expect(vm.dailyAverage > 0)
    }
}
