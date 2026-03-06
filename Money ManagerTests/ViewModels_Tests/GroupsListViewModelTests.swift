import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct GroupsListViewModelTests {
    
    @Test
    func testFilteredGroupsReturnsAllWhenSearchEmpty() {
        let group1 = SplitGroup(id: UUID(), name: "Goa Trip", createdBy: UUID(), createdAt: "2026-01-01")
        let group2 = SplitGroup(id: UUID(), name: "Office Lunch", createdBy: UUID(), createdAt: "2026-01-02")
        let viewModel = GroupsListViewModel(groups: [group1, group2])
        
        viewModel.searchText = ""
        
        #expect(viewModel.filteredGroups.count == 2)
    }
    
    @Test
    func testFilteredGroupsFiltersByName() {
        let group1 = SplitGroup(id: UUID(), name: "Goa Trip", createdBy: UUID(), createdAt: "2026-01-01")
        let group2 = SplitGroup(id: UUID(), name: "Office Lunch", createdBy: UUID(), createdAt: "2026-01-02")
        let viewModel = GroupsListViewModel(groups: [group1, group2])
        
        viewModel.searchText = "Goa"
        
        #expect(viewModel.filteredGroups.count == 1)
        #expect(viewModel.filteredGroups.first?.name == "Goa Trip")
    }
    
    @Test
    func testFilteredGroupsSearchIsCaseInsensitive() {
        let group1 = SplitGroup(id: UUID(), name: "Goa Trip", createdBy: UUID(), createdAt: "2026-01-01")
        let viewModel = GroupsListViewModel(groups: [group1])
        
        viewModel.searchText = "goa"
        
        #expect(viewModel.filteredGroups.count == 1)
    }
    
    @Test
    func testFilteredGroupsReturnsEmptyForNoMatch() {
        let group1 = SplitGroup(id: UUID(), name: "Goa Trip", createdBy: UUID(), createdAt: "2026-01-01")
        let viewModel = GroupsListViewModel(groups: [group1])
        
        viewModel.searchText = "Birthday"
        
        #expect(viewModel.filteredGroups.isEmpty)
    }
    
    @Test
    func testNetBalanceCalculatesCorrectly() {
        let currentUserId = TestData.currentUser.id
        let groupId1 = UUID()
        let groupId2 = UUID()
        let group1 = SplitGroup(id: groupId1, name: "Trip", createdBy: UUID(), createdAt: "2026-01-01")
        let group2 = SplitGroup(id: groupId2, name: "Flat", createdBy: UUID(), createdAt: "2026-01-02")
        
        let viewModel = GroupsListViewModel(
            groups: [group1, group2],
            balances: [
                groupId1: [UserBalance(userId: currentUserId, amount: "100.00"), UserBalance(userId: UUID(), amount: "-100.00")],
                groupId2: [UserBalance(userId: currentUserId, amount: "-50.00"), UserBalance(userId: UUID(), amount: "50.00")]
            ]
        )
        
        #expect(viewModel.netBalance == 50.0)
    }
    
    @Test
    func testNetBalanceReturnsZeroWhenNoGroups() {
        let viewModel = GroupsListViewModel()
        
        #expect(viewModel.netBalance == 0)
    }
    
    @Test
    func testUserBalanceReturnsCorrectValue() {
        let currentUserId = TestData.currentUser.id
        let groupId = UUID()
        let group = SplitGroup(id: groupId, name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let balances = [
            UserBalance(userId: currentUserId, amount: "250.50"),
            UserBalance(userId: UUID(), amount: "-250.50")
        ]
        
        let viewModel = GroupsListViewModel(groups: [group], balances: [groupId: balances])
        
        #expect(viewModel.userBalance(for: groupId) == 250.50)
    }
    
    @Test
    func testUserBalanceReturnsZeroWhenNoBalance() {
        let groupId = UUID()
        
        let viewModel = GroupsListViewModel()
        
        let result = viewModel.userBalance(for: groupId)
        
        #expect(result == 0)
    }
    
    @Test
    func testRelativeTimeReturnsNowForRecent() {
        let viewModel = GroupsListViewModel()
        let now = ISO8601DateFormatter().string(from: Date())
        
        let result = viewModel.relativeTime(from: now)
        
        #expect(result == "now")
    }
    
    @Test
    func testRelativeTimeReturnsMinutesAgo() {
        let viewModel = GroupsListViewModel()
        let date = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300))
        
        let result = viewModel.relativeTime(from: date)
        
        #expect(result.contains("m ago"))
    }
    
    @Test
    func testRelativeTimeReturnsHoursAgo() {
        let viewModel = GroupsListViewModel()
        let date = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200))
        
        let result = viewModel.relativeTime(from: date)
        
        #expect(result.contains("h ago"))
    }
    
    @Test
    func testRelativeTimeReturnsEmptyForInvalidDate() {
        let viewModel = GroupsListViewModel()
        
        let result = viewModel.relativeTime(from: "invalid-date")
        
        #expect(result == "")
    }
    
    @Test
    func testNameForUserReturnsUsername() {
        let userId = UUID()
        let user = APIUser(id: userId, email: "john@example.com", username: "John", createdAt: "2026-01-01")
        let groupId = UUID()
        
        let viewModel = GroupsListViewModel(members: [groupId: [user]])
        
        let result = viewModel.nameForUser(userId)
        
        #expect(result == "John")
    }
    
    @Test
    func testNameForUserReturnsUnknownWhenNotFound() {
        let viewModel = GroupsListViewModel()
        
        let result = viewModel.nameForUser(UUID())
        
        #expect(result == "Unknown")
    }
    
    @Test
    func testAddGroupInsertsAtBeginning() {
        let group1 = SplitGroup(id: UUID(), name: "Old Group", createdBy: UUID(), createdAt: "2026-01-01")
        let group2 = SplitGroup(id: UUID(), name: "New Group", createdBy: UUID(), createdAt: "2026-01-02")
        
        let viewModel = GroupsListViewModel(groups: [group1])
        viewModel.addGroup(group2)
        
        #expect(viewModel.groups.first?.name == "New Group")
    }
    
    @Test
    func testLoadFromDBConvertsGroupModelsToViewModels() {
        let groupId = UUID()
        let createdBy = UUID()
        
        let dbGroup = SplitGroupModel(id: groupId, name: "DB Group", createdBy: createdBy, createdAt: "2026-01-01")
        
        let viewModel = GroupsListViewModel()
        viewModel.loadFromDB(dbGroups: [dbGroup], dbMembers: [], dbExpenses: [], dbBalances: [])
        
        #expect(viewModel.groups.count == 1)
        #expect(viewModel.groups.first?.name == "DB Group")
    }
    
    @Test
    func testLoadFromDBConvertsMemberModels() {
        let groupId = UUID()
        let createdBy = UUID()
        let memberId = UUID()
        
        let dbGroup = SplitGroupModel(id: groupId, name: "Test Group", createdBy: createdBy, createdAt: "2026-01-01")
        let dbMember = GroupMemberModel(id: memberId, email: "test@example.com", username: "testuser", createdAt: "2026-01-01")
        dbMember.group = dbGroup
        
        let viewModel = GroupsListViewModel()
        viewModel.loadFromDB(dbGroups: [dbGroup], dbMembers: [dbMember], dbExpenses: [], dbBalances: [])
        
        #expect(viewModel.groupMembers[groupId]?.count == 1)
        #expect(viewModel.groupMembers[groupId]?.first?.username == "testuser")
    }
    
    @Test
    func testLoadFromDBConvertsExpenseModels() {
        let groupId = UUID()
        let createdBy = UUID()
        let expenseId = UUID()
        
        let dbGroup = SplitGroupModel(id: groupId, name: "Test Group", createdBy: createdBy, createdAt: "2026-01-01")
        let dbExpense = GroupExpenseModel(id: expenseId, description: "Lunch", category: "Food", totalAmount: 500.0, paidBy: createdBy, createdAt: "2026-01-01")
        dbExpense.group = dbGroup
        
        let viewModel = GroupsListViewModel()
        viewModel.loadFromDB(dbGroups: [dbGroup], dbMembers: [], dbExpenses: [dbExpense], dbBalances: [])
        
        #expect(viewModel.groupExpenses[groupId]?.count == 1)
        #expect(viewModel.groupExpenses[groupId]?.first?.description == "Lunch")
    }
    
    @Test
    func testLoadFromDBConvertsBalanceModels() {
        let groupId = UUID()
        let createdBy = UUID()
        let userId = UUID()
        
        let dbGroup = SplitGroupModel(id: groupId, name: "Test Group", createdBy: createdBy, createdAt: "2026-01-01")
        let dbBalance = GroupBalanceModel(userId: userId, amount: 100.0, group: dbGroup)
        
        let viewModel = GroupsListViewModel()
        viewModel.loadFromDB(dbGroups: [dbGroup], dbMembers: [], dbExpenses: [], dbBalances: [dbBalance])
        
        #expect(viewModel.groupBalances[groupId]?.count == 1)
        #expect(viewModel.groupBalances[groupId]?.first?.userId == userId)
    }
    
    @Test
    func testLoadFromDBHandlesEmptyArrays() {
        let viewModel = GroupsListViewModel()
        viewModel.loadFromDB(dbGroups: [], dbMembers: [], dbExpenses: [], dbBalances: [])
        
        #expect(viewModel.groups.isEmpty)
        #expect(viewModel.groupMembers.isEmpty)
        #expect(viewModel.groupExpenses.isEmpty)
        #expect(viewModel.groupBalances.isEmpty)
    }
    
    // MARK: - Net Balance (Current User Only)
    
    @Test
    func testNetBalanceIgnoresOtherUsersBalances() {
        let currentUserId = TestData.currentUser.id
        let otherUserId = UUID()
        let groupId = UUID()
        let group = SplitGroup(id: groupId, name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        
        let viewModel = GroupsListViewModel(
            groups: [group],
            balances: [groupId: [
                UserBalance(userId: currentUserId, amount: "200.00"),
                UserBalance(userId: otherUserId, amount: "-200.00")
            ]]
        )
        
        #expect(viewModel.netBalance == 200.0)
    }
    
    @Test
    func testNetBalanceSumsAcrossMultipleGroups() {
        let currentUserId = TestData.currentUser.id
        let groupId1 = UUID()
        let groupId2 = UUID()
        let groupId3 = UUID()
        let group1 = SplitGroup(id: groupId1, name: "A", createdBy: UUID(), createdAt: "2026-01-01")
        let group2 = SplitGroup(id: groupId2, name: "B", createdBy: UUID(), createdAt: "2026-01-01")
        let group3 = SplitGroup(id: groupId3, name: "C", createdBy: UUID(), createdAt: "2026-01-01")
        
        let viewModel = GroupsListViewModel(
            groups: [group1, group2, group3],
            balances: [
                groupId1: [UserBalance(userId: currentUserId, amount: "100.00")],
                groupId2: [UserBalance(userId: currentUserId, amount: "-300.00")],
                groupId3: [UserBalance(userId: currentUserId, amount: "50.00")]
            ]
        )
        
        #expect(viewModel.netBalance == -150.0)
    }
    
    @Test
    func testNetBalanceReturnsZeroWhenUserNotInBalances() {
        let groupId = UUID()
        let group = SplitGroup(id: groupId, name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        let otherUserId = UUID()
        
        let viewModel = GroupsListViewModel(
            groups: [group],
            balances: [groupId: [UserBalance(userId: otherUserId, amount: "500.00")]]
        )
        
        #expect(viewModel.netBalance == 0)
    }
    
    // MARK: - User Balance Per Group (Current User Only)
    
    @Test
    func testUserBalanceIgnoresOtherUsersInGroup() {
        let currentUserId = TestData.currentUser.id
        let groupId = UUID()
        let group = SplitGroup(id: groupId, name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        
        let viewModel = GroupsListViewModel(
            groups: [group],
            balances: [groupId: [
                UserBalance(userId: currentUserId, amount: "-75.00"),
                UserBalance(userId: UUID(), amount: "75.00")
            ]]
        )
        
        #expect(viewModel.userBalance(for: groupId) == -75.0)
    }
    
    @Test
    func testUserBalanceReturnsZeroWhenUserNotInGroup() {
        let groupId = UUID()
        let group = SplitGroup(id: groupId, name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        
        let viewModel = GroupsListViewModel(
            groups: [group],
            balances: [groupId: [UserBalance(userId: UUID(), amount: "100.00")]]
        )
        
        #expect(viewModel.userBalance(for: groupId) == 0)
    }
}
