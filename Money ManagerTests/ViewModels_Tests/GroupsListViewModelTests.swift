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
        let userId = UUID()
        let groupId = UUID()
        let balance1 = UserBalance(userId: userId, amount: "100.00")
        let balance2 = UserBalance(userId: userId, amount: "-50.00")
        let group = SplitGroup(id: groupId, name: "Test", createdBy: UUID(), createdAt: "2026-01-01")
        
        let viewModel = GroupsListViewModel(groups: [group], balances: [groupId: [balance1, balance2]])
        
        let result = viewModel.netBalance
        
        #expect(result == 50.0)
    }
    
    @Test
    func testNetBalanceReturnsZeroWhenNoGroups() {
        let viewModel = GroupsListViewModel()
        
        #expect(viewModel.netBalance == 0)
    }
    
    @Test
    func testUserBalanceReturnsCorrectValue() {
        let userId = UUID()
        let groupId = UUID()
        let balance = UserBalance(userId: userId, amount: "250.50")
        
        let viewModel = GroupsListViewModel(balances: [groupId: [balance]])
        
        let result = viewModel.userBalance(for: groupId)
        
        #expect(result == 250.50)
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
    func testNameForUserReturnsCapitalizedName() {
        let userId = UUID()
        let user = APIUser(id: userId, email: "john@example.com", createdAt: "2026-01-01")
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
}
