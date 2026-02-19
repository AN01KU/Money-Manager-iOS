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
    
    @Test
    func testGetGroupForNavigationReturnsNilWhenNoGroup() {
        let expense = Expense(amount: 100, category: "Food", date: Date())
        let viewModel = TransactionDetailViewModel(expense: expense)
        
        let result = viewModel.getGroupForNavigation()
        
        #expect(result == nil)
    }
}
