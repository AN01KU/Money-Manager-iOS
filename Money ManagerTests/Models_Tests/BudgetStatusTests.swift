import Testing
@testable import Money_Manager

@MainActor
struct BudgetStatusTests {

    // MARK: - BudgetStatus(spent:limit:)

    @Test func testSpentZeroLimitZero_returnsSafe() {
        #expect(BudgetStatus(spent: 0, limit: 0) == .safe)
    }

    @Test func testSpentZeroPositiveLimit_returnsSafe() {
        #expect(BudgetStatus(spent: 0, limit: 1000) == .safe)
    }

    @Test func testSpentAt79Percent_returnsSafe() {
        #expect(BudgetStatus(spent: 790, limit: 1000) == .safe)
    }

    @Test func testSpentAt80Percent_returnsCaution() {
        #expect(BudgetStatus(spent: 800, limit: 1000) == .caution)
    }

    @Test func testSpentAt99Percent_returnsCaution() {
        #expect(BudgetStatus(spent: 990, limit: 1000) == .caution)
    }

    @Test func testSpentAt100Percent_returnsDanger() {
        #expect(BudgetStatus(spent: 1000, limit: 1000) == .danger)
    }

    @Test func testSpentOverLimit_returnsDanger() {
        #expect(BudgetStatus(spent: 1500, limit: 1000) == .danger)
    }

    @Test func testNegativeLimit_returnsSafe() {
        // Guard against division by negative limit — treat as no limit
        #expect(BudgetStatus(spent: 1000, limit: -500) == .safe)
    }

    // MARK: - BudgetStatus(percentage:)

    @Test func testPercentage0_returnsSafe() {
        #expect(BudgetStatus(percentage: 0) == .safe)
    }

    @Test func testPercentage79_returnsSafe() {
        #expect(BudgetStatus(percentage: 79) == .safe)
    }

    @Test func testPercentage80_returnsCaution() {
        #expect(BudgetStatus(percentage: 80) == .caution)
    }

    @Test func testPercentage99_returnsCaution() {
        #expect(BudgetStatus(percentage: 99) == .caution)
    }

    @Test func testPercentage100_returnsDanger() {
        #expect(BudgetStatus(percentage: 100) == .danger)
    }

    @Test func testPercentage150_returnsDanger() {
        #expect(BudgetStatus(percentage: 150) == .danger)
    }

    // MARK: - Computed properties

    @Test func testSafe_hasCorrectIcon() {
        #expect(BudgetStatus.safe.icon == "checkmark.circle.fill")
    }

    @Test func testCaution_hasCorrectIcon() {
        #expect(BudgetStatus.caution.icon == "exclamationmark.circle.fill")
    }

    @Test func testDanger_hasCorrectIcon() {
        #expect(BudgetStatus.danger.icon == "exclamationmark.triangle.fill")
    }

    @Test func testSafe_hasCorrectTitle() {
        #expect(BudgetStatus.safe.title == "Within Budget")
    }

    @Test func testCaution_hasCorrectTitle() {
        #expect(BudgetStatus.caution.title == "Approaching Limit")
    }

    @Test func testDanger_hasCorrectTitle() {
        #expect(BudgetStatus.danger.title == "Over Budget")
    }

    // MARK: - message(spent:limit:)

    @Test func testMessage_safe_showsRemainingThisMonth() {
        let msg = BudgetStatus.safe.message(spent: 300, limit: 1000)
        #expect(msg.contains("remaining this month"))
    }

    @Test func testMessage_caution_showsRemaining() {
        let msg = BudgetStatus.caution.message(spent: 850, limit: 1000)
        #expect(msg.contains("remaining"))
        #expect(!msg.contains("this month"))
    }

    @Test func testMessage_danger_showsExceededAmount() {
        let msg = BudgetStatus.danger.message(spent: 1200, limit: 1000)
        #expect(msg.contains("exceeded by"))
    }
}
