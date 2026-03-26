import Foundation
import SwiftUI
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct TransactionDetailViewModelTests {
    
    // MARK: - Initial State
    
    @Test
    func initialState() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.showEditSheet == false)
        #expect(viewModel.showDeleteAlert == false)
        #expect(viewModel.customCategories.isEmpty)
        #expect(viewModel.expense.amount == 100)
    }
    
    // MARK: - isGroupExpense
    
    @Test
    func isGroupExpenseWhenBothPresent() {
        let expense = Expense(amount: 100, category: "Food", date: Date(), groupId: UUID(), groupName: "Trip")
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.isGroupExpense == true)
    }
    
    @Test
    func isGroupExpenseWhenMissingGroupId() {
        let expense = Expense(amount: 100, category: "Food", date: Date(), groupName: "Trip")
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.isGroupExpense == false)
    }
    
    @Test
    func isGroupExpenseWhenMissingGroupName() {
        let expense = Expense(amount: 100, category: "Food", date: Date(), groupId: UUID())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.isGroupExpense == false)
    }
    
    // MARK: - categoryIcon
    
    @Test
    func categoryIconForPredefinedCategory() {
        let expense = Expense(amount: 100, category: "Food & Dining", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.categoryIcon == "fork.knife.circle.fill")
    }
    
    @Test
    func categoryIconFallbackForUnknownCategory() {
        let expense = Expense(amount: 100, category: "Unknown Category", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.categoryIcon == "ellipsis.circle.fill")
    }
    
    @Test
    func categoryIconPrefersCustomCategory() {
        let expense = Expense(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        viewModel.customCategories = [custom]
        
        #expect(viewModel.categoryIcon == "pawprint.fill")
    }
    
    @Test
    func categoryIconIgnoresHiddenCustomCategory() {
        let expense = Expense(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        custom.isHidden = true
        viewModel.customCategories = [custom]
        
        // Falls through to predefined/fallback since custom is hidden
        #expect(viewModel.categoryIcon == "ellipsis.circle.fill")
    }
    
    // MARK: - categoryColor
    
    @Test
    func categoryColorForPredefinedCategory() {
        let expense = Expense(amount: 100, category: "Food & Dining", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.categoryColor == PredefinedCategory.foodDining.color)
    }
    
    @Test
    func categoryColorFallbackForUnknownCategory() {
        let expense = Expense(amount: 100, category: "Unknown Category", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.categoryColor == .gray)
    }
    
    @Test
    func categoryColorPrefersCustomCategory() {
        let expense = Expense(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        viewModel.customCategories = [custom]
        
        #expect(viewModel.categoryColor == Color(hex: "#FF0000"))
    }
    
    @Test
    func categoryColorIgnoresHiddenCustomCategory() {
        let expense = Expense(amount: 100, category: "Pets", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let custom = CustomCategory(name: "Pets", icon: "pawprint.fill", color: "#FF0000")
        custom.isHidden = true
        viewModel.customCategories = [custom]
        
        // Falls through to fallback since custom is hidden
        #expect(viewModel.categoryColor == .gray)
    }
    
    // MARK: - configure
    
    @Test
    func configureWithSwiftDataContext() throws {
        let schema = Schema([Expense.self, RecurringExpense.self, MonthlyBudget.self, CustomCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        viewModel.modelContext = context
        
        // Verify deleteExpense works with a real context (completion called)
        var completionCalled = false
        viewModel.deleteExpense {
            completionCalled = true
        }
        #expect(completionCalled == true)
        #expect(expense.isDeleted == true)
    }
    
    // MARK: - deleteExpense
    
    @Test
    func deleteExpenseSetsIsDeletedAndUpdatedAt() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let originalUpdatedAt = expense.updatedAt
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        var completionCalled = false
        viewModel.deleteExpense {
            completionCalled = true
        }
        
        #expect(expense.isDeleted == true)
        #expect(expense.updatedAt >= originalUpdatedAt)
        #expect(completionCalled == true)
    }
    
    // MARK: - formatAmount
    
    @Test
    func formatAmountWithDecimals() {
        let viewModel = TransactionDetailViewModel(expense: Expense(amount: 0, category: "Food", date: Date()))
        
        let result = viewModel.formatAmount(1234.56)
        #expect(result.contains("1,234") || result.contains("1234"))
        #expect(result.contains("56"))
    }
    
    @Test
    func formatAmountWholeNumber() {
        let viewModel = TransactionDetailViewModel(expense: Expense(amount: 0, category: "Food", date: Date()))
        
        let result = viewModel.formatAmount(100)
        #expect(result.contains("100"))
    }
    
    // MARK: - formatDateAndTime
    
    @Test
    func formatDateAndTimeWithTime() {
        let viewModel = TransactionDetailViewModel(expense: Expense(amount: 0, category: "Food", date: Date()))
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
    func formatDateAndTimeWithoutTime() {
        let viewModel = TransactionDetailViewModel(expense: Expense(amount: 0, category: "Food", date: Date()))
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: Date())
        
        let result = viewModel.formatDateAndTime(date, time: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let expectedDateOnly = dateFormatter.string(from: date)
        
        #expect(result == expectedDateOnly)
    }
    
    // MARK: - formatFullDate
    
    @Test
    func formatFullDateReturnsFormattedString() {
        let viewModel = TransactionDetailViewModel(expense: Expense(amount: 0, category: "Food", date: Date()))
        
        let result = viewModel.formatFullDate(Date())
        #expect(!result.isEmpty)
    }
}
