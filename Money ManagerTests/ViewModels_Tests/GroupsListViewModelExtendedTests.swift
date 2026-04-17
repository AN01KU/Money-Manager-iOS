import Foundation
import Testing
@testable import Money_Manager

/// Tests for GroupsListViewModel covering setCurrentUser, netBalance with a user,
/// groupedActivity, userBalance with a user, and ActivityItem.id.
@MainActor
struct GroupsListViewModelExtendedTests {

    // MARK: - Helpers

    private func makeGroup(
        id: UUID = UUID(),
        name: String = "Test Group",
        createdBy: UUID = UUID(),
        balances: [APIGroupBalance] = []
    ) -> APIGroupWithDetails {
        APIGroupWithDetails(id: id, name: name, createdBy: createdBy, createdAt: Date(), members: [], balances: balances)
    }

    private func makeBalance(userId: UUID, amount: Double) -> APIGroupBalance {
        APIGroupBalance(userId: userId, amount: amount)
    }

    private func makeTransaction(id: UUID = UUID(), description: String = "tx", date: Date = Date()) -> APIGroupTransaction {
        APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: UUID(),
            totalAmount: 10, category: "Food", date: date,
            description: description, notes: nil, isDeleted: false,
            createdAt: date, updatedAt: Date(), splits: []
        )
    }

    private func makeSettlement(id: UUID = UUID(), fromUser: UUID = UUID(), toUser: UUID = UUID(), date: Date = Date()) -> APISettlement {
        APISettlement(id: id, groupId: UUID(), fromUser: fromUser, toUser: toUser, amount: 20, notes: nil, createdAt: date)
    }

    // MARK: - setCurrentUser

    @Test func testSetCurrentUserUpdatesCurrentUserId() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let uid = UUID()
        vm.setCurrentUser(uid)
        // netBalance should now use this user ID
        vm.groups = [makeGroup(balances: [makeBalance(userId: uid, amount: 42)])]
        #expect(abs(vm.netBalance - 42) < 0.01)
    }

    @Test func testSetCurrentUserToNilResetsToZeroBalance() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let uid = UUID()
        vm.setCurrentUser(uid)
        vm.setCurrentUser(nil)
        vm.groups = [makeGroup(balances: [makeBalance(userId: uid, amount: 42)])]
        #expect(vm.netBalance == 0)
    }

    // MARK: - netBalance with current user

    @Test func testNetBalanceSumsAcrossMultipleGroups() {
        let uid = UUID()
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh(), currentUserId: uid)
        vm.groups = [
            makeGroup(balances: [makeBalance(userId: uid, amount: 30)]),
            makeGroup(balances: [makeBalance(userId: uid, amount: -10)]),
            makeGroup(balances: [makeBalance(userId: uid, amount: 20)])
        ]
        #expect(abs(vm.netBalance - 40) < 0.01)
    }

    @Test func testNetBalanceIgnoresOtherUsersBalances() {
        let uid = UUID()
        let other = UUID()
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh(), currentUserId: uid)
        vm.groups = [makeGroup(balances: [makeBalance(userId: other, amount: 100)])]
        #expect(vm.netBalance == 0)
    }

    @Test func testNetBalanceReturnsZeroWhenGroupHasNoBalanceForUser() {
        let uid = UUID()
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh(), currentUserId: uid)
        vm.groups = [makeGroup(balances: [])]
        #expect(vm.netBalance == 0)
    }

    // MARK: - userBalance(for:) with current user

    @Test func testUserBalanceReturnsCorrectAmountForCurrentUser() {
        let uid = UUID()
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh(), currentUserId: uid)
        let group = makeGroup(balances: [makeBalance(userId: uid, amount: 75)])
        #expect(abs(vm.userBalance(for: group) - 75) < 0.01)
    }

    @Test func testUserBalanceReturnsNegativeAmountWhenOwing() {
        let uid = UUID()
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh(), currentUserId: uid)
        let group = makeGroup(balances: [makeBalance(userId: uid, amount: -30)])
        #expect(abs(vm.userBalance(for: group) - (-30)) < 0.01)
    }

    // MARK: - ActivityItem.id

    @Test func testActivityItemTransactionIdMatchesTransactionId() {
        let txId = UUID()
        let tx = makeTransaction(id: txId)
        let item = ActivityItem.transaction(tx, groupName: "Trip")
        #expect(item.id == txId)
    }

    @Test func testActivityItemSettlementIdMatchesSettlementId() {
        let sid = UUID()
        let settlement = makeSettlement(id: sid)
        let item = ActivityItem.settlement(settlement, groupName: "Trip", memberMap: [:])
        #expect(item.id == sid)
    }

    // MARK: - groupedActivity

    @Test func testGroupedActivityGroupsByDayKey() {
        let uid = UUID()
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh(), currentUserId: uid)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        let tx1 = makeTransaction(date: yesterday)
        let tx2 = makeTransaction(date: yesterday)
        vm.recentActivity = [
            .transaction(tx1, groupName: "A"),
            .transaction(tx2, groupName: "B")
        ]

        let sections = vm.groupedActivity
        // Both items have the same day → one section
        #expect(sections.count == 1)
        #expect(sections[0].items.count == 2)
    }

    @Test func testGroupedActivityTodaySection() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let tx = makeTransaction(date: Date())
        vm.recentActivity = [.transaction(tx, groupName: "Trip")]
        let sections = vm.groupedActivity
        #expect(sections.count == 1)
        #expect(sections[0].id == "TODAY")
    }

    @Test func testGroupedActivityTodaySectionSortedFirst() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let txToday = makeTransaction(date: Date())
        let txYesterday = makeTransaction(date: yesterday)
        vm.recentActivity = [
            .transaction(txYesterday, groupName: "Old"),
            .transaction(txToday, groupName: "New")
        ]
        let sections = vm.groupedActivity
        #expect(sections.first?.id == "TODAY")
    }

    @Test func testGroupedActivityEmptyWhenNoActivity() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        vm.recentActivity = []
        #expect(vm.groupedActivity.isEmpty)
    }

    // MARK: - filteredActivity - settlement matching

    @Test func testFilteredActivityDoesNotMatchSettlementByNonGroupName() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let settlement = makeSettlement()
        vm.recentActivity = [.settlement(settlement, groupName: "Trip", memberMap: [:])]
        vm.searchText = "zzz"
        #expect(vm.filteredActivity.isEmpty)
    }

    @Test func testFilteredActivityMatchesSettlementByGroupName() {
        let vm = GroupsListViewModel(groupService: MockGroupService.fresh())
        let settlement = makeSettlement()
        vm.recentActivity = [.settlement(settlement, groupName: "Vacation", memberMap: [:])]
        vm.searchText = "vacation"
        #expect(vm.filteredActivity.count == 1)
    }
}
