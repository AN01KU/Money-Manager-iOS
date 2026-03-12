import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct AddExpenseViewModelTests {
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testEqualShareTextCalculatesCorrectly() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "1000"
        let userId = UUID()
        viewModel.selectedMembers = [userId]
        
        let result = viewModel.equalShareText
        
        #expect(result.contains("1,000") || result.contains("₹1,000"))
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testEqualShareTextWithMultipleMembers() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "300"
        viewModel.selectedMembers = [UUID(), UUID(), UUID()]
        
        let result = viewModel.equalShareText
        
        #expect(result.contains("100"))
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testEqualShareTextReturnsZeroWhenNoMembers() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "1000"
        viewModel.selectedMembers = []
        
        let result = viewModel.equalShareText
        
        #expect(result.contains("0"))
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testCustomSplitTotalSumsCorrectly() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        let user1 = UUID()
        let user2 = UUID()
        viewModel.selectedMembers = [user1, user2]
        viewModel.customAmounts = [user1: "250.50", user2: "249.50"]
        
        let result = viewModel.customSplitTotal
        
        #expect(result == 500.0)
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testCustomSplitTotalIgnoresInvalidAmounts() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        let user1 = UUID()
        let user2 = UUID()
        viewModel.selectedMembers = [user1, user2]
        viewModel.customAmounts = [user1: "250", user2: "invalid"]
        
        let result = viewModel.customSplitTotal
        
        #expect(result == 250.0)
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testSplitMatchesTotalReturnsTrueWhenMatching() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "500"
        let user1 = UUID()
        let user2 = UUID()
        viewModel.selectedMembers = [user1, user2]
        viewModel.customAmounts = [user1: "250", user2: "250"]
        
        let result = viewModel.splitMatchesTotal
        
        #expect(result == true)
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testSplitMatchesTotalReturnsFalseWhenNotMatching() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "500"
        let user1 = UUID()
        let user2 = UUID()
        viewModel.selectedMembers = [user1, user2]
        viewModel.customAmounts = [user1: "200", user2: "200"]
        
        let result = viewModel.splitMatchesTotal
        
        #expect(result == false)
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testSplitMatchesTotalReturnsFalseForInvalidAmount() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "invalid"
        
        let result = viewModel.splitMatchesTotal
        
        #expect(result == false)
    }
    */
    
    @Test
    func testIsValidForPersonalExpenseWithValidData() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "500"
        viewModel.selectedCategory = "Food & Dining"
        
        #expect(viewModel.isValid == true)
    }
    
    @Test
    func testIsValidFailsWithInvalidAmount() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "0"
        viewModel.selectedCategory = "Food & Dining"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testIsValidFailsWithNegativeAmount() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "-100"
        viewModel.selectedCategory = "Food & Dining"
        
        #expect(viewModel.isValid == false)
    }
    
    @Test
    func testIsValidFailsWithEmptyCategory() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "500"
        viewModel.selectedCategory = ""
        
        #expect(viewModel.isValid == false)
    }
    
    // MARK: - Format Tests
    
    @Test
    func testFormatDateReturnsNonEmptyString() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        let date = Date()
        let result = viewModel.formatDate(date)
        
        #expect(!result.isEmpty)
    }
    
    @Test
    func testFormatTimeReturnsNonEmptyString() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        let date = Date()
        let result = viewModel.formatTime(date)
        
        #expect(!result.isEmpty)
    }
    
    @Test
    func testFormatDateContainsMonthName() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 15
        let date = Calendar.current.date(from: components)!
        
        let result = viewModel.formatDate(date)
        
        #expect(result.contains("Mar") || result.contains("15"))
    }
    
    // MARK: - Navigation Title Tests
    
    @Test
    func testNavigationTitleForNewExpense() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        
        #expect(viewModel.navigationTitle == "Add Expense")
    }
    
    @Test
    func testNavigationTitleForEditingExpense() {
        let expense = Expense(
            amount: 100,
            category: "Food",
            date: Date(),
            time: nil,
            expenseDescription: nil,
            notes: nil
        )
        let viewModel = AddExpenseViewModel(mode: .personal(editing: expense))
        
        #expect(viewModel.navigationTitle == "Edit Expense")
    }
    
    // MARK: - Setup Tests
    
    @Test
    func testSetupWithEditingExpense() {
        let expense = Expense(
            amount: 250.50,
            category: "Transport",
            date: Date(),
            time: Date(),
            expenseDescription: "Taxi",
            notes: "Airport trip"
        )
        let viewModel = AddExpenseViewModel(mode: .personal(editing: expense))
        
        viewModel.setup()
        
        #expect(viewModel.amount == "250.50")
        #expect(viewModel.selectedCategory == "Transport")
        #expect(viewModel.description == "Taxi")
        #expect(viewModel.notes == "Airport trip")
        #expect(viewModel.hasTime == true)
    }
    
    @Test
    func testSetupWithExpenseWithoutTime() {
        let expense = Expense(
            amount: 100,
            category: "Food",
            date: Date(),
            time: nil,
            expenseDescription: nil,
            notes: nil
        )
        let viewModel = AddExpenseViewModel(mode: .personal(editing: expense))
        
        viewModel.setup()
        
        #expect(viewModel.hasTime == false)
    }
    
    // MARK: - Initial State Tests
    
    @Test
    func testInitialStateHasTimeEnabled() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        
        #expect(viewModel.hasTime == true)
    }
    
    @Test
    func testInitialStateHasEmptyFields() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        
        #expect(viewModel.amount.isEmpty)
        #expect(viewModel.selectedCategory.isEmpty)
        #expect(viewModel.description.isEmpty)
        #expect(viewModel.notes.isEmpty)
    }
    
    @Test
    func testInitialStateShowsPickersFalse() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        
        #expect(viewModel.showCategoryPicker == false)
        #expect(viewModel.showDatePicker == false)
        #expect(viewModel.showTimePicker == false)
        #expect(viewModel.showError == false)
        #expect(viewModel.isSaving == false)
    }
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testBuildSplitsEqualSplitWithRounding() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "100"
        let user1 = UUID()
        let user2 = UUID()
        let user3 = UUID()
        viewModel.selectedMembers = [user1, user2, user3]
        viewModel.splitType = .equal
        
        let splits = viewModel.buildSplits()
        
        #expect(splits.count == 3)
        let total = splits.compactMap { Double($0.amount) }.reduce(0, +)
        #expect(abs(total - 100) < 0.01)
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testBuildSplitsCustomSplit() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "500"
        let user1 = UUID()
        let user2 = UUID()
        viewModel.selectedMembers = [user1, user2]
        viewModel.splitType = .custom
        viewModel.customAmounts = [user1: "300", user2: "200"]
        
        let splits = viewModel.buildSplits()
        
        #expect(splits.count == 2)
    }
    */
    
    // MARK: - Commented out: shared expense feature removed in offline-v1
    /*
    @Test
    func testToggleMemberAddsAndRemoves() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        let userId = UUID()
        
        #expect(viewModel.selectedMembers.isEmpty)
        
        viewModel.toggleMember(userId)
        #expect(viewModel.selectedMembers.contains(userId))
        
        viewModel.toggleMember(userId)
        #expect(!viewModel.selectedMembers.contains(userId))
    }
    */
}
