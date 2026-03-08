import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct TransactionDetailViewModelTests {
    
    @Test
    func testIsGroupExpenseReturnsTrueWhenGroupIdAndNamePresent() {
        let expense = Expense(amount: 100, category: "Food", date: Date(), groupId: UUID(), groupName: "Trip")
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.isGroupExpense == true)
    }
    
    @Test
    func testIsGroupExpenseReturnsFalseWhenNoGroupId() {
        let expense = Expense(amount: 100, category: "Food", date: Date(), groupName: "Trip")
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.isGroupExpense == false)
    }
    
    @Test
    func testIsGroupExpenseReturnsFalseWhenNoGroupName() {
        let expense = Expense(amount: 100, category: "Food", date: Date(), groupId: UUID())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.isGroupExpense == false)
    }
    
    @Test
    func testCategoryReturnsCorrectPredefinedCategory() {
        let expense = Expense(amount: 100, category: "Food & Dining", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.category == .foodDining)
    }
    
    @Test
    func testCategoryReturnsNilForNonMatching() {
        let expense = Expense(amount: 100, category: "Unknown Category", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        #expect(viewModel.category == nil)
    }
    
    @Test
    func testFormatAmountWithDecimalPlaces() {
        let expense = Expense(amount: 1234.56, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.formatAmount(1234.56)
        
        #expect(result.contains("1,234") || result.contains("1234"))
    }
    
    @Test
    func testFormatAmountWithWholeNumber() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.formatAmount(100)
        
        #expect(result.contains("100"))
    }
    
    @Test
    func testFormatDateAndTimeWithTimeIncluded() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.formatDateAndTime(Date(), time: Date())
        
        #expect(!result.isEmpty)
    }
    
    @Test
    func testFormatDateAndTimeWithoutTime() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.formatDateAndTime(Date(), time: nil)
        
        #expect(!result.isEmpty)
    }
    
    @Test
    func testFormatFullDateReturnsNonEmptyString() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.formatFullDate(Date())
        
        #expect(!result.isEmpty)
    }
    
    @Test
    func testDeleteExpenseSetsIsDeletedToTrue() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        var deleted = false
        viewModel.deleteExpense { 
            deleted = true
        }
        
        #expect(expense.isDeleted == true)
    }
    
    // MARK: - Commented out: group navigation removed in offline-v1
    /*
    @Test
    func testGetGroupForNavigationReturnsGroup() {
        let groupId = UUID()
        let expense = Expense(amount: 100, category: "Food", date: Date(), groupId: groupId, groupName: "Trip")
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.getGroupForNavigation()
        
        #expect(result != nil)
        #expect(result?.id == groupId)
        #expect(result?.name == "Trip")
    }
    */
    
    // MARK: - Commented out: group navigation removed in offline-v1
    /*
    @Test
    func testGetGroupForNavigationReturnsNilWhenNoGroup() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.getGroupForNavigation()
        
        #expect(result == nil)
    }
    */
    
    @Test
    func testFormatDateAndTimeWithSpecificTimeContainsTime() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: Date())
        let time = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: date)!
        
        let result = viewModel.formatDateAndTime(date, time: time)
        
        #expect(result.contains("2:30") || result.contains("14:30"))
    }
    
    @Test
    func testFormatDateAndTimeWithNilTimeContainsNoTime() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: Date())
        
        let result = viewModel.formatDateAndTime(date, time: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let expectedDateOnly = dateFormatter.string(from: date)
        
        #expect(result == expectedDateOnly)
    }
    
    @Test
    func testFormatDateAndTimeKnownDateAndTimeContainsBoth() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 1
        dateComponents.day = 15
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        
        let time = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: date)!
        
        let result = viewModel.formatDateAndTime(date, time: time)
        
        #expect(result.contains("Jan") || result.contains("January"))
        #expect(result.contains("15"))
        #expect(result.contains("2026"))
        #expect(result.contains("2:30") || result.contains("14:30"))
    }
}
