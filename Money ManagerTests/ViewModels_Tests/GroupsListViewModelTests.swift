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
        balances: [GroupBalance] = [],
        members: [GroupMember] = []
    ) -> SplitGroup {
        SplitGroup(id: id, name: name, createdBy: createdBy, createdAt: Date(), members: members, balances: balances, settlements: [])
    }

    private func makeBalance(userId: UUID, amount: Double) -> GroupBalance {
        GroupBalance(from: APIGroupBalance(userId: userId, amount: amount))
    }

    private func makeTransaction(description: String = "Test", totalAmount: Double = 10.0, paidBy: UUID = UUID(), createdAt: Date = Date()) -> GroupTransaction {
        let dto = APIGroupTransaction(
            id: UUID(), groupId: UUID(), paidByUserId: paidBy,
            totalAmount: totalAmount, category: "Food", date: createdAt,
            description: description, notes: nil, isDeleted: false,
            createdAt: createdAt, updatedAt: Date(), splits: []
        )
        return try! GroupTransaction(from: dto)
    }

    private func makeActivityTransaction(description: String = "Test", totalAmount: Double = 10.0, createdAt: Date = Date()) -> ActivityTransaction {
        ActivityTransaction(id: UUID(), date: createdAt, description: description, category: "Food", totalAmount: totalAmount, paidByUserId: UUID())
    }

    private func makeDetails(groupId: UUID, groupName: String) -> SplitGroup {
        SplitGroup(id: groupId, name: groupName, createdBy: UUID(), createdAt: Date(), members: [], balances: [], settlements: [])
    }

    /// Creates a GroupService backed by a MockAPIClient configured with the given stubs.
    /// - groupsResponse: returned for GET .groups
    /// - groupDetailsResponse: returned for GET .group(:id) — used by fetchGroupDetails
    /// - transactionsResponse: returned for GET .groupTransactions(:id)
    private func makeService(
        groups: [APIGroupWithDetails] = [],
        groupDetails: APIGroupDetailsBody? = nil,
        transactions: [APIGroupTransaction] = [],
        createResult: APIGroup? = nil
    ) -> (GroupService, MockAPIClient) {
        let client = MockAPIClient()
        let groupDetailsBody = groupDetails
        let createBody = createResult
        client.getHandler = { endpoint in
            switch endpoint {
            case .groups:
                return APIListResponse(data: groups)
            case .group(let id):
                let body = groupDetailsBody ?? APIGroupDetailsBody(
                    id: id, name: "Mock Group", createdBy: UUID(), createdAt: Date(),
                    members: [], balances: [], settlements: nil
                )
                return APIGroupDetails(group: body, isMember: true)
            case .groupTransactions:
                return APIListResponse(data: transactions)
            default:
                throw MockAPIClient.MockError.notConfigured
            }
        }
        client.postHandler = { endpoint, _ in
            switch endpoint {
            case .groups:
                if let result = createBody {
                    return result
                }
                return APIGroup(id: UUID(), name: "New Group", createdBy: UUID(), createdAt: Date())
            default:
                throw MockAPIClient.MockError.notConfigured
            }
        }
        return (GroupService(apiClient: client), client)
    }

    // MARK: - Initial state

    @Test
    func testInitialStateIsEmpty() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        #expect(vm.groups.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.searchText.isEmpty)
        #expect(vm.selectedTab == .groups)
        #expect(vm.recentActivity.isEmpty)
    }

    // MARK: - load()

    @Test
    func testLoadPopulatesGroups() async {
        let (service, _) = makeService(groups: [
            APIGroupWithDetails(id: UUID(), name: "Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: []),
            APIGroupWithDetails(id: UUID(), name: "Office", createdBy: UUID(), createdAt: Date(), members: [], balances: [])
        ])
        let vm = GroupsListViewModel(groupService: service)
        await vm.load()
        #expect(vm.groups.count == 2)
        #expect(vm.isLoading == false)
    }

    @Test
    func testLoadPopulatesRecentActivityFromGroupDetails() async {
        let groupId = UUID()
        let txDto = APIGroupTransaction(
            id: UUID(), groupId: groupId, paidByUserId: UUID(),
            totalAmount: 10, category: "Food", date: Date(),
            description: "Dinner", notes: nil, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: []
        )
        let txDto2 = APIGroupTransaction(
            id: UUID(), groupId: groupId, paidByUserId: UUID(),
            totalAmount: 5, category: "Food", date: Date(),
            description: "Taxi", notes: nil, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: []
        )
        let detailsBody = APIGroupDetailsBody(
            id: groupId, name: "Weekend Trip", createdBy: UUID(), createdAt: Date(),
            members: [], balances: [], settlements: nil
        )
        let (service, _) = makeService(
            groups: [APIGroupWithDetails(id: groupId, name: "Weekend Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: [])],
            groupDetails: detailsBody,
            transactions: [txDto, txDto2]
        )
        let vm = GroupsListViewModel(groupService: service)
        await vm.load()
        #expect(vm.recentActivity.count == 2)
        #expect(vm.recentActivity.allSatisfy { $0.groupName == "Weekend Trip" })
    }

    @Test
    func testLoadRecentActivitySortedNewestFirst() async {
        let groupId = UUID()
        let older = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -60)
        let oldDto = APIGroupTransaction(
            id: UUID(), groupId: groupId, paidByUserId: UUID(),
            totalAmount: 10, category: "Food", date: older,
            description: "Old", notes: nil, isDeleted: false,
            createdAt: older, updatedAt: older, splits: []
        )
        let newDto = APIGroupTransaction(
            id: UUID(), groupId: groupId, paidByUserId: UUID(),
            totalAmount: 20, category: "Food", date: newer,
            description: "New", notes: nil, isDeleted: false,
            createdAt: newer, updatedAt: newer, splits: []
        )
        let (service, _) = makeService(
            groups: [APIGroupWithDetails(id: groupId, name: "Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: [])],
            transactions: [oldDto, newDto]
        )
        let vm = GroupsListViewModel(groupService: service)
        await vm.load()
        if case .transaction(let tx, _) = vm.recentActivity.first {
            #expect(tx.description == "New")
        } else {
            Issue.record("Expected .transaction as first activity item")
        }
    }

    @Test
    func testLoadRecentActivityEmptyWhenNoTransactions() async {
        let groupId = UUID()
        let (service, _) = makeService(
            groups: [APIGroupWithDetails(id: groupId, name: "Trip", createdBy: UUID(), createdAt: Date(), members: [], balances: [])]
        )
        let vm = GroupsListViewModel(groupService: service)
        await vm.load()
        #expect(vm.recentActivity.isEmpty)
    }

    // MARK: - filteredGroups

    @Test
    func testFilteredGroupsWithEmptySearchReturnsAll() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.groups = [makeGroup(name: "Trip"), makeGroup(name: "Flatmates")]
        vm.searchText = ""
        #expect(vm.filteredGroups.count == 2)
    }

    @Test
    func testFilteredGroupsWithSearchFiltersByName() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.groups = [makeGroup(name: "Weekend Trip"), makeGroup(name: "Flatmates")]
        vm.searchText = "trip"
        #expect(vm.filteredGroups.count == 1)
        #expect(vm.filteredGroups.first?.name == "Weekend Trip")
    }

    @Test
    func testFilteredGroupsWithSearchCaseInsensitive() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.groups = [makeGroup(name: "FLAT"), makeGroup(name: "Office")]
        vm.searchText = "flat"
        #expect(vm.filteredGroups.count == 1)
    }

    @Test
    func testFilteredGroupsWithNoMatchReturnsEmpty() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.groups = [makeGroup(name: "Trip"), makeGroup(name: "Office")]
        vm.searchText = "xyz"
        #expect(vm.filteredGroups.isEmpty)
    }

    // MARK: - filteredActivity

    @Test
    func testFilteredActivityWithEmptySearchReturnsAll() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.recentActivity = [
            .transaction(makeActivityTransaction(description: "Dinner"), groupName: "Trip"),
            .transaction(makeActivityTransaction(description: "Taxi"),   groupName: "Work")
        ]
        vm.searchText = ""
        #expect(vm.filteredActivity.count == 2)
    }

    @Test
    func testFilteredActivityMatchesTransactionDescription() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.recentActivity = [
            .transaction(makeActivityTransaction(description: "Dinner"), groupName: "Trip"),
            .transaction(makeActivityTransaction(description: "Hotel"),  groupName: "Trip")
        ]
        vm.searchText = "dinner"
        #expect(vm.filteredActivity.count == 1)
        if case .transaction(let tx, _) = vm.filteredActivity.first {
            #expect(tx.description == "Dinner")
        } else {
            Issue.record("Expected .transaction as first filtered activity item")
        }
    }

    @Test
    func testFilteredActivityMatchesGroupName() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.recentActivity = [
            .transaction(makeActivityTransaction(description: "Dinner"), groupName: "Weekend Trip"),
            .transaction(makeActivityTransaction(description: "Lunch"),  groupName: "Office")
        ]
        vm.searchText = "weekend"
        #expect(vm.filteredActivity.count == 1)
        #expect(vm.filteredActivity.first?.groupName == "Weekend Trip")
    }

    // MARK: - netBalance

    @Test
    func testNetBalanceWithNoCurrentUserReturnsZero() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        let uid = UUID()
        vm.groups = [makeGroup(balances: [makeBalance(userId: uid, amount: 50.0)])]
        #expect(vm.netBalance == 0)
    }

    @Test
    func testNetBalanceWithNoGroupsReturnsZero() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.groups = []
        #expect(vm.netBalance == 0)
    }

    // MARK: - userBalance(for:)

    @Test
    func testUserBalanceWithNoCurrentUserReturnsZero() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        let uid = UUID()
        let group = makeGroup(balances: [makeBalance(userId: uid, amount: 75.0)])
        #expect(vm.userBalance(for: group) == 0)
    }

    @Test
    func testUserBalanceWithNoBalanceEntryReturnsZero() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        let group = makeGroup(balances: [])
        #expect(vm.userBalance(for: group) == 0)
    }

    // MARK: - displayName(for:)

    @Test
    func testDisplayNameReturnsUsername() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        let member = GroupMember(from: APIGroupMember(id: UUID(), email: "alice@example.com", username: "alice", joinedAt: Date()))
        #expect(vm.displayName(for: member) == "alice")
    }

    @Test
    func testDisplayNameWithNoAtSignReturnsUsername() {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        let member = GroupMember(from: APIGroupMember(id: UUID(), email: "noatsign", username: "noatsign", joinedAt: Date()))
        #expect(vm.displayName(for: member) == "noatsign")
    }

    // MARK: - createGroup

    @Test
    func testCreateGroupInsertsAtTopOfList() async throws {
        let (service, _) = makeService()
        let vm = GroupsListViewModel(groupService: service)
        vm.groups = [makeGroup(name: "Existing")]
        _ = try await vm.createGroup(name: "New Group")
        #expect(vm.groups.count == 2)
        #expect(vm.groups.first?.name == "New Group")
    }

    @Test
    func testCreateGroupCallsServiceWithName() async throws {
        let client = MockAPIClient()
        var capturedName: String?
        client.postHandler = { endpoint, data in
            if case .groups = endpoint, let d = data {
                // APICreateGroupRequest encodes only a plain string "name" field — use a simple decoder
                struct NameOnly: Decodable { let name: String }
                capturedName = (try? JSONDecoder().decode(NameOnly.self, from: d))?.name
            }
            return APIGroup(id: UUID(), name: capturedName ?? "", createdBy: UUID(), createdAt: Date())
        }
        let service = GroupService(apiClient: client)
        let vm = GroupsListViewModel(groupService: service)
        _ = try await vm.createGroup(name: "Trip")
        #expect(capturedName == "Trip")
    }
}
