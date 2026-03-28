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

    private func makeTransaction(description: String = "Test", totalAmount: String = "10.00", paidBy: UUID = UUID(), createdAt: Date = Date()) -> APIGroupTransaction {
        APIGroupTransaction(
            id: UUID(), group_id: UUID(), paid_by_user_id: paidBy,
            total_amount: totalAmount, category: "Food", date: createdAt,
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
    func testInitialStateIsEmpty() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        #expect(vm.groups.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.searchText.isEmpty)
        #expect(vm.selectedTab == .groups)
        #expect(vm.recentActivity.isEmpty)
    }

    // MARK: - load()

    @Test
    func testLoadPopulatesGroups() async {
        let mock = MockGroupService.fresh()
        mock.stubbedGroups = [makeGroup(name: "Trip"), makeGroup(name: "Office")]
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.groups.count == 2)
        #expect(vm.isLoading == false)
    }

    @Test
    func testLoadPopulatesRecentActivityFromGroupDetails() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let group = makeGroup(id: groupId, name: "Weekend Trip")
        mock.stubbedGroups = [group]
        mock.stubbedGroupDetails = makeDetails(groupId: groupId, groupName: "Weekend Trip")
        mock.stubbedTransactions = [makeTransaction(description: "Dinner"), makeTransaction(description: "Taxi")]
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.recentActivity.count == 2)
        #expect(vm.recentActivity.allSatisfy { $0.groupName == "Weekend Trip" })
    }

    @Test
    func testLoadRecentActivitySortedNewestFirst() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let older = makeTransaction(description: "Old", totalAmount: "10", createdAt: Date(timeIntervalSinceNow: -3600))
        let newer = makeTransaction(description: "New", totalAmount: "20", createdAt: Date(timeIntervalSinceNow: -60))
        mock.stubbedGroups = [makeGroup(id: groupId)]
        mock.stubbedTransactions = [older, newer]
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.recentActivity.first?.transaction.description == "New")
    }

    @Test
    func testLoadRecentActivityEmptyWhenNoTransactions() async {
        let mock = MockGroupService.fresh()
        mock.stubbedGroups = [makeGroup()]
        let vm = GroupsListViewModel(groupService: mock)
        await vm.load()
        #expect(vm.recentActivity.isEmpty)
    }

    // MARK: - filteredGroups

    @Test
    func testFilteredGroupsWithEmptySearchReturnsAll() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "Trip"), makeGroup(name: "Flatmates")]
        vm.searchText = ""
        #expect(vm.filteredGroups.count == 2)
    }

    @Test
    func testFilteredGroupsWithSearchFiltersByName() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "Weekend Trip"), makeGroup(name: "Flatmates")]
        vm.searchText = "trip"
        #expect(vm.filteredGroups.count == 1)
        #expect(vm.filteredGroups.first?.name == "Weekend Trip")
    }

    @Test
    func testFilteredGroupsWithSearchCaseInsensitive() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "FLAT"), makeGroup(name: "Office")]
        vm.searchText = "flat"
        #expect(vm.filteredGroups.count == 1)
    }

    @Test
    func testFilteredGroupsWithNoMatchReturnsEmpty() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = [makeGroup(name: "Trip"), makeGroup(name: "Office")]
        vm.searchText = "xyz"
        #expect(vm.filteredGroups.isEmpty)
    }

    // MARK: - filteredActivity

    @Test
    func testFilteredActivityWithEmptySearchReturnsAll() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.recentActivity = [
            (transaction: makeTransaction(description: "Dinner"), groupName: "Trip"),
            (transaction: makeTransaction(description: "Taxi"),   groupName: "Work")
        ]
        vm.searchText = ""
        #expect(vm.filteredActivity.count == 2)
    }

    @Test
    func testFilteredActivityMatchesExpenseDescription() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.recentActivity = [
            (transaction: makeTransaction(description: "Dinner"), groupName: "Trip"),
            (transaction: makeTransaction(description: "Hotel"),  groupName: "Trip")
        ]
        vm.searchText = "dinner"
        #expect(vm.filteredActivity.count == 1)
        #expect(vm.filteredActivity.first?.transaction.description == "Dinner")
    }

    @Test
    func testFilteredActivityMatchesGroupName() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.recentActivity = [
            (transaction: makeTransaction(description: "Dinner"), groupName: "Weekend Trip"),
            (transaction: makeTransaction(description: "Lunch"),  groupName: "Office")
        ]
        vm.searchText = "weekend"
        #expect(vm.filteredActivity.count == 1)
        #expect(vm.filteredActivity.first?.groupName == "Weekend Trip")
    }

    // MARK: - netBalance

    @Test
    func testNetBalanceWithNoCurrentUserReturnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let uid = UUID()
        vm.groups = [makeGroup(balances: [makeBalance(userId: uid, amount: "50.00")])]
        #expect(vm.netBalance == 0)
    }

    @Test
    func testNetBalanceWithNoGroupsReturnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.groups = []
        #expect(vm.netBalance == 0)
    }

    // MARK: - userBalance(for:)

    @Test
    func testUserBalanceWithNoCurrentUserReturnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let uid = UUID()
        let group = makeGroup(balances: [makeBalance(userId: uid, amount: "75.00")])
        #expect(vm.userBalance(for: group) == 0)
    }

    @Test
    func testUserBalanceWithNoBalanceEntryReturnsZero() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let group = makeGroup(balances: [])
        #expect(vm.userBalance(for: group) == 0)
    }

    // MARK: - displayName(for:)

    @Test
    func testDisplayNameReturnsUsername() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let member = APIGroupMember(id: UUID(), email: "alice@example.com", username: "alice", joined_at: Date())
        #expect(vm.displayName(for: member) == "alice")
    }

    @Test
    func testDisplayNameWithNoAtSignReturnsUsername() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let member = APIGroupMember(id: UUID(), email: "noatsign", username: "noatsign", joined_at: Date())
        #expect(vm.displayName(for: member) == "noatsign")
    }

    // MARK: - createGroup

    @Test
    func testCreateGroupInsertsAtTopOfList() async throws {
        let mock = MockGroupService.fresh()
        let vm = GroupsListViewModel(groupService: mock)
        vm.groups = [makeGroup(name: "Existing")]
        _ = try await vm.createGroup(name: "New Group")
        #expect(vm.groups.count == 2)
        #expect(vm.groups.first?.name == "New Group")
    }

    @Test
    func testCreateGroupCallsServiceWithName() async throws {
        let mock = MockGroupService.fresh()
        let vm = GroupsListViewModel(groupService: mock)
        _ = try await vm.createGroup(name: "Trip")
        #expect(mock.createGroupCalls == ["Trip"])
    }
}
