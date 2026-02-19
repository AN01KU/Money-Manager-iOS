import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct AddExpenseViewModelTests {
    
    @Test
    func testEqualShareTextCalculatesCorrectly() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "1000"
        let userId = UUID()
        viewModel.selectedMembers = [userId]
        
        let result = viewModel.equalShareText
        
        #expect(result.contains("1,000") || result.contains("₹1,000"))
    }
    
    @Test
    func testEqualShareTextWithMultipleMembers() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "300"
        viewModel.selectedMembers = [UUID(), UUID(), UUID()]
        
        let result = viewModel.equalShareText
        
        #expect(result.contains("100"))
    }
    
    @Test
    func testEqualShareTextReturnsZeroWhenNoMembers() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "1000"
        viewModel.selectedMembers = []
        
        let result = viewModel.equalShareText
        
        #expect(result.contains("0"))
    }
    
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
    
    @Test
    func testSplitMatchesTotalReturnsFalseForInvalidAmount() {
        let viewModel = AddExpenseViewModel(mode: .personal())
        viewModel.amount = "invalid"
        
        let result = viewModel.splitMatchesTotal
        
        #expect(result == false)
    }
    
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
}
