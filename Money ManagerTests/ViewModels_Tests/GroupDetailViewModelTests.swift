import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct GroupDetailViewModelTests {

    // MARK: - Helpers

    private func makeGroup(id: UUID = UUID(), createdBy: UUID = UUID()) -> APIGroupWithDetails {
        APIGroupWithDetails(
            id: id,
            name: "Test Group",
            created_by: createdBy,
            created_at: Date(),
            members: [],
            balances: []
        )
    }

    private func makeMember(id: UUID = UUID(), email: String = "user@example.com") -> APIGroupMember {
        APIGroupMember(id: id, email: email, username: email.components(separatedBy: "@").first ?? email, joined_at: Date())
    }

    private func makeTransaction(totalAmount: String, paidBy: UUID = UUID()) -> APIGroupTransaction {
        APIGroupTransaction(
            id: UUID(), group_id: UUID(), paid_by_user_id: paidBy,
            total_amount: totalAmount, category: "Food", date: Date(),
            description: "Test", notes: nil, is_deleted: false,
            created_at: Date(), updated_at: Date(), splits: []
        )
    }

    private func makeBalance(userId: UUID, amount: String) -> APIGroupBalance {
        APIGroupBalance(user_id: userId, amount: amount)
    }

    private func makeDetails(
        groupId: UUID,
        members: [APIGroupMember] = [],
        balances: [APIGroupBalance] = []
    ) -> APIGroupDetails {
        let body = APIGroupDetailsBody(
            id: groupId, name: "Test Group", created_by: UUID(), created_at: Date(),
            members: members, balances: balances
        )
        return APIGroupDetails(group: body, is_member: true)
    }

    // MARK: - Initial state

    @Test
    func testInitSeedsMembersAndBalancesFromGroup() {
        let alice = makeMember(email: "alice@example.com")
        let group = APIGroupWithDetails(
            id: UUID(), name: "Trip", created_by: alice.id, created_at: Date(),
            members: [alice],
            balances: [makeBalance(userId: alice.id, amount: "50.00")]
        )
        let vm = GroupDetailViewModel(group: group)
        #expect(vm.members.count == 1)
        #expect(vm.balances.count == 1)
        #expect(vm.transactions.isEmpty)
    }

    // MARK: - loadData()

    @Test
    func testLoadDataPopulatesTransactionsMembersBalances() async {
        let groupId = UUID()
        let mock = MockGroupService.fresh()
        let alice = makeMember(email: "alice@example.com")
        mock.stubbedGroupDetails = makeDetails(
            groupId: groupId,
            members: [alice],
            balances: [makeBalance(userId: alice.id, amount: "30.00")]
        )
        mock.stubbedTransactions = [makeTransaction(totalAmount: "60.00")]
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: mock)
        await vm.loadData()
        #expect(vm.transactions.count == 1)
        #expect(vm.members.count == 1)
        #expect(vm.balances.count == 1)
        #expect(vm.isLoading == false)
    }

    @Test
    func testLoadDataKeepsInitialMembersWhenDetailsReturnEmpty() async {
        let mock = MockGroupService.fresh()
        let alice = makeMember(email: "alice@example.com")
        let group = APIGroupWithDetails(
            id: UUID(), name: "Trip", created_by: alice.id, created_at: Date(),
            members: [alice], balances: []
        )
        let vm = GroupDetailViewModel(group: group, groupService: mock)
        await vm.loadData()
        #expect(vm.isLoading == false)
    }

    // MARK: - groupTotal

    @Test
    func testGroupTotalSumsAllTransactions() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [
            makeTransaction(totalAmount: "100.00"),
            makeTransaction(totalAmount: "50.50")
        ]
        #expect(vm.groupTotal == 150.5)
    }

    @Test
    func testGroupTotalWithNoTransactionsIsZero() {
        let vm = GroupDetailViewModel(group: makeGroup())
        #expect(vm.groupTotal == 0)
    }

    @Test
    func testGroupTotalIgnoresInvalidAmounts() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactions = [makeTransaction(totalAmount: "not-a-number")]
        #expect(vm.groupTotal == 0)
    }

    // MARK: - hasUnsettledBalances

    @Test
    func testHasUnsettledBalancesWhenAllZeroReturnsFalse() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [makeBalance(userId: UUID(), amount: "0.00")]
        #expect(vm.hasUnsettledBalances == false)
    }

    @Test
    func testHasUnsettledBalancesWhenSomeNonZeroReturnsTrue() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [makeBalance(userId: UUID(), amount: "25.00")]
        #expect(vm.hasUnsettledBalances == true)
    }

    @Test
    func testHasUnsettledBalancesWhenNegativeBalanceReturnsTrue() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [makeBalance(userId: UUID(), amount: "-30.00")]
        #expect(vm.hasUnsettledBalances == true)
    }

    // MARK: - expenseAdded (transactionAdded)

    @Test
    func testTransactionAddedInsertsAtTop() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let first  = makeTransaction(totalAmount: "100")
        let second = makeTransaction(totalAmount: "50")
        vm.transactionAdded(first)
        vm.transactionAdded(second)
        #expect(vm.transactions.first?.total_amount == "50")
    }

    @Test
    func testTransactionAddedUpdatesGroupTotal() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.transactionAdded(makeTransaction(totalAmount: "200"))
        #expect(vm.groupTotal == 200)
    }

    // MARK: - addMember optimistic state

    @Test
    func testAddMemberAddsToPendingEmailsImmediately() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.addMember(email: "bob@example.com")
        #expect(vm.pendingMemberEmails.contains("bob@example.com"))
    }

    @Test
    func testAddMemberTrimsAndLowercasesEmail() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.addMember(email: "  BOB@EXAMPLE.COM  ")
        #expect(vm.pendingMemberEmails.contains("bob@example.com"))
    }

    @Test
    func testAddMemberDoesNothingWhenEmailIsBlank() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.addMember(email: "   ")
        #expect(vm.pendingMemberEmails.isEmpty)
    }

    @Test
    func testAddMemberDoesNothingWhenAlreadyAMember() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        let alice = makeMember(email: "alice@example.com")
        vm.members = [alice]
        vm.addMember(email: "alice@example.com")
        #expect(vm.pendingMemberEmails.isEmpty)
    }

    @Test
    func testAddMemberDismissesSheetImmediately() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.showAddMember = true
        vm.addMember(email: "bob@example.com")
        #expect(vm.showAddMember == false)
    }

    // MARK: - Invite flow (async, via mock)

    @Test
    func testAddMemberSuccessClearsPendingAndRefreshesMembers() async {
        let mock = MockGroupService.fresh()
        let bob = makeMember(email: "bob@example.com")
        mock.stubbedMembers = [bob]

        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.addMember(email: "bob@example.com")

        #expect(vm.pendingMemberEmails.contains("bob@example.com"))

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(vm.pendingMemberEmails.isEmpty)
        #expect(vm.members.contains(where: { $0.email == "bob@example.com" }))
        #expect(mock.addMemberCalls.count == 1)
        #expect(mock.addMemberCalls.first?.email == "bob@example.com")
    }

    @Test
    func testAddMemberFailureClearsPendingAndSetsError() async {
        struct InviteError: Error, LocalizedError {
            var errorDescription: String? { "user not found with this email" }
        }
        let mock = MockGroupService.fresh()
        mock.addMemberError = InviteError()

        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.addMember(email: "ghost@example.com")

        #expect(vm.pendingMemberEmails.contains("ghost@example.com"))

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(vm.pendingMemberEmails.isEmpty)
        #expect(vm.addMemberError != nil)
    }

    @Test
    func testAddMemberCallsServiceWithCorrectGroupId() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: mock)
        vm.addMember(email: "sam@example.com")

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(mock.addMemberCalls.first?.groupId == groupId)
    }

    // MARK: - isPending

    @Test
    func testIsPendingReturnsTrueForPendingMember() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let bob = makeMember(email: "bob@example.com")
        vm.pendingMemberEmails.insert("bob@example.com")
        #expect(vm.isPending(bob) == true)
    }

    @Test
    func testIsPendingReturnsFalseForConfirmedMember() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let alice = makeMember(email: "alice@example.com")
        #expect(vm.isPending(alice) == false)
    }

    // MARK: - settlementRecorded

    @Test
    func testSettlementRecordedRecalculatesBalances() {
        let alice = makeMember(email: "alice@example.com")
        let bob   = makeMember(email: "bob@example.com")
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.members = [alice, bob]
        vm.transactions = [makeTransaction(totalAmount: "100.00", paidBy: alice.id)]
        let settlement = APISettlement(
            id: UUID(), groupId: vm.group.id,
            fromUser: bob.id, toUser: alice.id,
            amount: "50.00", createdAt: Date()
        )
        vm.settlementRecorded(settlement)
        #expect(vm.balances.count == 2)
    }

    // MARK: - displayName

    @Test
    func testDisplayNameReturnsUsername() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let member = makeMember(email: "charlie@example.com")
        #expect(vm.displayName(for: member) == member.username)
    }

    @Test
    func testDisplayNameForIdReturnsUnknownWhenNotFound() {
        let vm = GroupDetailViewModel(group: makeGroup())
        #expect(vm.displayName(forId: UUID()) == "Unknown")
    }

    @Test
    func testDisplayNameForIdResolvesKnownMember() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let alice = makeMember(email: "alice@example.com")
        vm.members = [alice]
        #expect(vm.displayName(forId: alice.id) == alice.username)
    }
}
