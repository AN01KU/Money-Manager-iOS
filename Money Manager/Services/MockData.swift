import Foundation

struct MockData {
    // Set to `false` to use the real backend
    // Set to `true` to use mock/dummy data for testing without a backend
    static let useDummyData = true
    
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
