// MARK: - Commented out: backend/auth/groups code removed in offline-v1
/*
import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct TestDataTests {
    
    // MARK: - Dynamic Dates
    
    @Test
    func testSharedExpenseDatesAreNotHardcoded() {
        let formatter = ISO8601DateFormatter()
        let today = Date()
        
        for (_, expenses) in TestData.testSharedExpenses {
            for expense in expenses {
                let date = formatter.date(from: expense.createdAt)!
                let interval = today.timeIntervalSince(date)
                #expect(interval >= -86400 && interval < 12 * 86400, "Expense '\(expense.description)' should be within the last ~11 days from today")
            }
        }
    }
    
    @Test
    func testGeneratePersonalExpensesSortedByDateDescending() {
        let expenses = TestData.generatePersonalExpenses()
        
        for i in 0..<(expenses.count - 1) {
            #expect(expenses[i].date >= expenses[i + 1].date)
        }
    }
    
    @Test
    func testGeneratePersonalExpensesHaveValidCategories() {
        let expenses = TestData.generatePersonalExpenses()
        
        for expense in expenses {
            let category = Category.fromString(expense.category)
            #expect(category != .other || expense.category == "Other", "Category '\(expense.category)' should map to a known category")
        }
    }
    
    // MARK: - Test Data Completeness
    
    @Test
    func testAllGroupsHaveMembers() {
        for group in TestData.testGroups {
            let members = TestData.testGroupMembers[group.id]
            #expect(members != nil && !members!.isEmpty, "Group '\(group.name)' should have members")
        }
    }
    
    @Test
    func testAllGroupsHaveExpenses() {
        for group in TestData.testGroups {
            let expenses = TestData.testSharedExpenses[group.id]
            #expect(expenses != nil && !expenses!.isEmpty, "Group '\(group.name)' should have expenses")
        }
    }
    
    @Test
    func testAllGroupsHaveBalances() {
        for group in TestData.testGroups {
            let balances = TestData.testBalances[group.id]
            #expect(balances != nil && !balances!.isEmpty, "Group '\(group.name)' should have balances")
        }
    }
    
    @Test
    func testExpenseSplitsIncludeOnlyGroupMembers() {
        for group in TestData.testGroups {
            let members = TestData.testGroupMembers[group.id] ?? []
            let memberIds = Set(members.map { $0.id })
            let expenses = TestData.testSharedExpenses[group.id] ?? []
            
            for expense in expenses {
                for split in expense.splits ?? [] {
                    #expect(memberIds.contains(split.userId), "Split user \(split.userId) in '\(expense.description)' should be a member of group '\(group.name)'")
                }
            }
        }
    }
    
    @Test
    func testExpenseSplitsSumToTotalAmount() {
        for (_, expenses) in TestData.testSharedExpenses {
            for expense in expenses {
                guard let splits = expense.splits else { continue }
                let splitsSum = splits.compactMap { Double($0.amount) }.reduce(0, +)
                let total = Double(expense.totalAmount) ?? 0
                #expect(abs(splitsSum - total) < 0.02, "Splits for '\(expense.description)' should sum to total \(total), got \(splitsSum)")
            }
        }
    }
    
    // MARK: - Group Expenses for Overview
    
    @Test
    func testGetGroupExpensesForOverviewReturnsOnlyCurrentUserExpenses() {
        let expenses = TestData.getGroupExpensesForOverview()
        
        #expect(!expenses.isEmpty)
        for expense in expenses {
            #expect(expense.groupId != nil)
            #expect(expense.groupName != nil)
        }
    }
    
    // MARK: - Budgets
    
    @Test
    func testGenerateBudgetsCoversCurrentAndPreviousMonths() {
        let budgets = TestData.generateBudgets()
        
        #expect(budgets.count == 3)
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        #expect(budgets[0].year == currentYear)
        #expect(budgets[0].month == currentMonth)
    }
    
    // MARK: - Recurring Expenses
    
    @Test
    func testGenerateRecurringExpensesAllMarkedRecurring() {
        let recurring = TestData.generateRecurringExpenses()
        
        #expect(!recurring.isEmpty)
        for expense in recurring {
            #expect(expense.isRecurring == true)
            #expect(expense.frequency != nil)
        }
    }
    
    // MARK: - Helper Functions
    
    @Test
    func testNameForUserReturnsCorrectName() {
        #expect(TestData.nameForUser(TestData.currentUser.id) == "Ankush")
    }
    
    @Test
    func testNameForUserReturnsUnknownForInvalidId() {
        #expect(TestData.nameForUser(UUID()) == "Unknown")
    }
    
    @Test
    func testEmailForUserReturnsCorrectEmail() {
        #expect(TestData.emailForUser(TestData.currentUser.id) == "ankush@example.com")
    }
    
    @Test
    func testEmailForUserReturnsUnknownForInvalidId() {
        #expect(TestData.emailForUser(UUID()) == "Unknown")
    }
}
*/
