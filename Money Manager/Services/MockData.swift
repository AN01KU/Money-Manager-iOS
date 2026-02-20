import Foundation

struct MockData {
    // Reference TestData for all mock data
    static let currentUser = TestData.currentUser
    static let users = TestData.testUsers
    static let groups = TestData.testGroups
    static let groupMembers = TestData.testGroupMembers
    static let expenses = TestData.testSharedExpenses
    static let balances = TestData.testBalances
    
    static func emailForUser(_ userId: UUID) -> String {
        TestData.emailForUser(userId)
    }
    
    static func nameForUser(_ userId: UUID) -> String {
        TestData.nameForUser(userId)
    }
    
    static func getMockExpensesForOverview() -> [Expense] {
        TestData.getGroupExpensesForOverview()
    }
}
