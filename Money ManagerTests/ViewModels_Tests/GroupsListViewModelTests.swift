import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct GroupsListViewModelTests {

    // MARK: - Helpers

    private func makeGroup(
        id: UUID = UUID(),
        name: String = "Test Group",
        createdBy: UUID = UUID(),
        balances: [APIGroupBalance] = [],
        members: [APIGroupMember] = []
    ) -> APIGroupWithDetails {
        APIGroupWithDetails(
            id: id,
            name: name,
            created_by: createdBy,
            created_at: Date(),
            members: members,
            balances: balances
        )
    }

    private func makeBalance(userId: UUID, amount: String) -> APIGroupBalance {
        APIGroupBalance(user_id: userId, amount: amount)
    }

    private func makeExpense(description: String = "Test", totalAmount: String = "10.00", paidBy: UUID = UUID(), createdAt: Date = Date()) -> APIGroupExpense {
        APIGroupExpense(
            id: UUID(), group_id: UUID(), paid_by_user_id: paidBy,
            total_amount: totalAmount, category: "Food", date: Date(),
            description: description, notes: nil, is_deleted: false,
            created_at: createdAt, updated_at: Date(), splits: []
        )
    }

    private func makeDetails(groupId: UUID, groupName: String) -> APIGroupDetails {
        let body = APIGroupDetailsBody(
            id: groupId, name: groupName, created_by: UUID(), created_at: Date(),
            members: [], balances: []
        )
        return APIGroupDetails(group: body, is_member: true)
    }

    // MARK: - Initial state

    @Test
    func test_initialState_isEmpty() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        #expect(vm.groups.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.searchText.isEmpty)
        #expect(vm.selectedTab == .groups)
        #expect(vm.recentActivity.isEmpty)
    }

    // MARK: - load()

    @Test
    func test_load_populatesGroups() async {
        let mock = MockGroupService.fresh()
        mock.stubbedGroups = [makeGroup(name: "Trip"), makeGroup(name: "Office")]
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.groups.count == 2)
        #expect(vm.isLoading == false)
    }

    @Test
    func test_load_populatesRecentActivity_fromGroupDetails() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let group = makeGroup(id: groupId, name: "Weekend Trip")
        mock.stubbedGroups = [group]
        mock.stubbedGroupDetails = makeDetails(groupId: groupId, groupName: "Weekend Trip")
        mock.stubbedTransactions = [makeExpense(description: "Dinner"), makeExpense(description: "Taxi")]
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.recentActivity.count == 2)
        #expect(vm.recentActivity.allSatisfy { $0.groupName == "Weekend Trip" })
    }

    @Test
    func test_load_recentActivity_sortedNewestFirst() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let older = makeExpense(description: "Old", totalAmount: "10", createdAt: Date(timeIntervalSinceNow: -3600))
        let newer = makeExpense(description: "New", totalAmount: "20", createdAt: Date(timeIntervalSinceNow: -60))
        mock.stubbedGroups = [makeGroup(id: groupId)]
        mock.stubbedTransactions = [older, newer]
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.recentActivity.first?.expense.description == "New")
    }

    @Test
    func test_load_recentActivity_emptyWhenNoExpenses() async {
        let mock = MockGroupService.fresh()
        mock.stubbedGroups = [makeGroup()]
        // stubbedGroupDetails is nil → mock returns empty expenses by default
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.recentActivity.isEmpty)
    }

    // MARK: - filteredGroups

    @Test
    func test_filteredGroups_withEmptySearch_returnsAll() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "Trip"), makeGroup(name: "Flatmates")]
        vm.searchText = ""
        #expect(vm.filteredGroups.count == 2)
    }

    @Test
    func test_filteredGroups_withSearch_filtersByName() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "Weekend Trip"), makeGroup(name: "Flatmates")]
        vm.searchText = "trip"
        #expect(vm.filteredGroups.count == 1)
        #expect(vm.filteredGroups.first?.name == "Weekend Trip")
    }

    @Test
    func test_filteredGroups_withSearch_caseInsensitive() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "FLAT"), makeGroup(name: "Office")]
        vm.searchText = "flat"
        #expect(vm.filteredGroups.count == 1)
    }

    @Test
    func test_filteredGroups_withNoMatch_returnsEmpty() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "Trip"), makeGroup(name: "Office")]
        vm.searchText = "xyz"
        #expect(vm.filteredGroups.isEmpty)
    }

    // MARK: - filteredActivity

    @Test
    func test_filteredActivity_withEmptySearch_returnsAll() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.recentActivity = [
            (expense: makeExpense(description: "Dinner"), groupName: "Trip"),
            (expense: makeExpense(description: "Taxi"),   groupName: "Work")
        ]
        vm.searchText = ""
        #expect(vm.filteredActivity.count == 2)
    }

    @Test
    func test_filteredActivity_matchesExpenseDescription() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.recentActivity = [
            (expense: makeExpense(description: "Dinner"), groupName: "Trip"),
            (expense: makeExpense(description: "Hotel"),  groupName: "Trip")
        ]
        vm.searchText = "dinner"
        #expect(vm.filteredActivity.count == 1)
        #expect(vm.filteredActivity.first?.expense.description == "Dinner")
    }

    @Test
    func test_filteredActivity_matchesGroupName() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.recentActivity = [
            (expense: makeExpense(description: "Dinner"), groupName: "Weekend Trip"),
            (expense: makeExpense(description: "Lunch"),  groupName: "Office")
        ]
        vm.searchText = "weekend"
        #expect(vm.filteredActivity.count == 1)
        #expect(vm.filteredActivity.first?.groupName == "Weekend Trip")
    }

    // MARK: - netBalance

    @Test
    func test_netBalance_withNoCurrentUser_returnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let uid = UUID()
        vm.groups = [makeGroup(balances: [makeBalance(userId: uid, amount: "50.00")])]
        #expect(vm.netBalance == 0)
    }

    @Test
    func test_netBalance_withNoGroups_returnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = []
        #expect(vm.netBalance == 0)
    }

    // MARK: - userBalance(for:)

    @Test
    func test_userBalance_withNoCurrentUser_returnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let uid = UUID()
        let group = makeGroup(balances: [makeBalance(userId: uid, amount: "75.00")])
        #expect(vm.userBalance(for: group) == 0)
    }

    @Test
    func test_userBalance_withNoBalanceEntry_returnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let group = makeGroup(balances: [])
        #expect(vm.userBalance(for: group) == 0)
    }

    // MARK: - displayName(for:)

    @Test
    func test_displayName_returnsUsername() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let member = APIGroupMember(id: UUID(), email: "alice@example.com", username: "alice", joined_at: Date())
        #expect(vm.displayName(for: member) == "alice")
    }

    @Test
    func test_displayName_withNoAtSign_returnsUsername() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let member = APIGroupMember(id: UUID(), email: "noatsign", username: "noatsign", joined_at: Date())
        #expect(vm.displayName(for: member) == "noatsign")
    }

    // MARK: - createGroup

    @Test
    func test_createGroup_insertsAtTopOfList() async throws {
        let mock = MockGroupService.fresh()
        let vm = GroupsListViewModel(groupService: mock)
        vm.groups = [makeGroup(name: "Existing")]
        _ = try await vm.createGroup(name: "New Group")
        #expect(vm.groups.count == 2)
        #expect(vm.groups.first?.name == "New Group")
    }

    @Test
    func test_createGroup_callsServiceWithName() async throws {
        let mock = MockGroupService.fresh()
        let vm = GroupsListViewModel(groupService: mock)
        _ = try await vm.createGroup(name: "Trip")
        #expect(mock.createGroupCalls == ["Trip"])
    }
}
