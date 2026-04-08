import Foundation
import SwiftUI
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct TransactionDetailViewModelTests {

    // MARK: - Initial State

    @Test
    func testInitialState() {
        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        #expect(viewModel.showEditSheet == false)
        #expect(viewModel.showDeleteAlert == false)
        #expect(viewModel.customCategories.isEmpty)
        #expect(viewModel.transaction.amount == 100)
    }

    // MARK: - isGroupTransaction

    @Test
    func testIsGroupTransactionWhenGroupTransactionIdPresent() {
        let transaction = Transaction(amount: 100, category: "Food", date: Date(), groupTransactionId: UUID())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        #expect(viewModel.isGroupTransaction == true)
    }

    @Test
    func testIsGroupTransactionWhenGroupTransactionIdNil() {
        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        #expect(viewModel.isGroupTransaction == false)
    }

    // MARK: - categoryIcon

    @Test
    func testCategoryIconForPredefinedCategory() {
        let transaction = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        #expect(viewModel.categoryIcon == "fork.knife.circle.fill")
    }

    @Test
    func testCategoryIconFallbackForUnknownCategory() {
        let transaction = Transaction(amount: 100, category: "Unknown Category", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        #expect(viewModel.categoryIcon == "ellipsis.circle.fill")
    }

    @Test
    func testCategoryIconPrefersCustomCategory() {
        let transaction = Transaction(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        viewModel.customCategories = [custom]

        #expect(viewModel.categoryIcon == "pawprint.fill")
    }

    @Test
    func testCategoryIconIgnoresHiddenCustomCategory() {
        let transaction = Transaction(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        custom.isHidden = true
        viewModel.customCategories = [custom]

        #expect(viewModel.categoryIcon == "ellipsis.circle.fill")
    }

    // MARK: - categoryColor

    @Test
    func testCategoryColorForPredefinedCategory() {
        let transaction = Transaction(amount: 100, category: "Food & Dining", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        #expect(viewModel.categoryColor == PredefinedCategory.foodDining.color)
    }

    @Test
    func testCategoryColorFallbackForUnknownCategory() {
        let transaction = Transaction(amount: 100, category: "Unknown Category", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        #expect(viewModel.categoryColor == .gray)
    }

    @Test
    func testCategoryColorPrefersCustomCategory() {
        let transaction = Transaction(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        viewModel.customCategories = [custom]

        #expect(viewModel.categoryColor == Color(hex: "#FF0000"))
    }

    @Test
    func testCategoryColorIgnoresHiddenCustomCategory() {
        let transaction = Transaction(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        custom.isHidden = true
        viewModel.customCategories = [custom]

        #expect(viewModel.categoryColor == .gray)
    }

    // MARK: - configure

    @Test
    func testConfigureWithSwiftDataContext() throws {
        let context = ModelContext(try makeTestContainer())

        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(transaction: transaction)
        viewModel.modelContext = context

        var completionCalled = false
        viewModel.deleteTransaction {
            completionCalled = true
        }
        #expect(completionCalled == true)
        #expect(transaction.isSoftDeleted == true)
    }

    // MARK: - deleteTransaction

    @Test
    func testDeleteTransactionSetsIsDeletedAndUpdatedAt() {
        let transaction = Transaction(amount: 100, category: "Food", date: Date())
        let originalUpdatedAt = transaction.updatedAt
        let viewModel = TransactionDetailViewModel(transaction: transaction)

        var completionCalled = false
        viewModel.deleteTransaction {
            completionCalled = true
        }

        #expect(transaction.isSoftDeleted == true)
        #expect(transaction.updatedAt >= originalUpdatedAt)
        #expect(completionCalled == true)
    }

    // MARK: - formatAmount

    @Test
    func testFormatAmountWithDecimals() {
        let viewModel = TransactionDetailViewModel(transaction: Transaction(amount: 0, category: "Food", date: Date()))

        let result = viewModel.formatAmount(1234.56)
        #expect(result.contains("1,234") || result.contains("1234"))
        #expect(result.contains("56"))
    }

    @Test
    func testFormatAmountWholeNumber() {
        let viewModel = TransactionDetailViewModel(transaction: Transaction(amount: 0, category: "Food", date: Date()))

        let result = viewModel.formatAmount(100)
        #expect(result.contains("100"))
    }

    // MARK: - formatDateAndTime

    @Test
    func testFormatDateAndTimeWithTime() {
        let viewModel = TransactionDetailViewModel(transaction: Transaction(amount: 0, category: "Food", date: Date()))
        let calendar = Calendar.current

        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 1
        dateComponents.day = 15
        let date = calendar.date(from: dateComponents)!
        let time = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: date)!

        let result = viewModel.formatDateAndTime(date, time: time)

        #expect(result.contains("Jan") || result.contains("January"))
        #expect(result.contains("15"))
        #expect(result.contains("2:30") || result.contains("14:30"))
    }

    @Test
    func testFormatDateAndTimeWithoutTime() {
        let viewModel = TransactionDetailViewModel(transaction: Transaction(amount: 0, category: "Food", date: Date()))
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: Date())

        let result = viewModel.formatDateAndTime(date, time: nil)

        let expectedDateOnly = date.formatted(date: .abbreviated, time: .omitted)

        #expect(result == expectedDateOnly)
    }

    // MARK: - formatFullDate

    @Test
    func testFormatFullDateReturnsFormattedString() {
        let viewModel = TransactionDetailViewModel(transaction: Transaction(amount: 0, category: "Food", date: Date()))

        let result = viewModel.formatFullDate(Date())
        #expect(!result.isEmpty)
    }
}
