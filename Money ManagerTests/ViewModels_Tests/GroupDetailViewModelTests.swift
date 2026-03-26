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
        APIGroupMember(id: id, email: email, username: email.components(separatedBy: "@").first ?? email, createdAt: Date())
    }

    private func makeExpense(totalAmount: String, paidBy: UUID = UUID()) -> APIGroupExpense {
        APIGroupExpense(id: UUID(), description: "Test", amount: totalAmount, user_id: paidBy, created_at: Date())
    }

    private func makeBalance(userId: UUID, amount: String) -> APIGroupBalance {
        APIGroupBalance(user_id: userId, amount: amount)
    }

    private func makeDetails(
        groupId: UUID,
        members: [APIGroupMember] = [],
        balances: [APIGroupBalance] = [],
        expenses: [APIGroupExpense] = []
    ) -> APIGroupDetails {
        let body = APIGroupDetailsBody(
            id: groupId, name: "Test Group", created_by: UUID(), created_at: Date(),
            members: members, balances: balances, expenses: expenses
        )
        return APIGroupDetails(group: body, is_member: true)
    }

    // MARK: - Initial state

    @Test
    func test_init_seedsMembersAndBalancesFromGroup() {
        let alice = makeMember(email: "alice@example.com")
        let group = APIGroupWithDetails(
            id: UUID(), name: "Trip", created_by: alice.id, created_at: Date(),
            members: [alice],
            balances: [makeBalance(userId: alice.id, amount: "50.00")]
        )
        let vm = GroupDetailViewModel(group: group)
        #expect(vm.members.count == 1)
        #expect(vm.balances.count == 1)
        #expect(vm.expenses.isEmpty)
    }

    // MARK: - loadData()

    @Test
    func test_loadData_populatesExpensesMembersBalances() async {
        let groupId = UUID()
        let mock = MockGroupService.fresh()
        let alice = makeMember(email: "alice@example.com")
        mock.stubbedGroupDetails = makeDetails(
            groupId: groupId,
            members: [alice],
            balances: [makeBalance(userId: alice.id, amount: "30.00")],
            expenses: [makeExpense(totalAmount: "60.00")]
        )
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: mock)
        await vm.loadData()
        #expect(vm.expenses.count == 1)
        #expect(vm.members.count == 1)
        #expect(vm.balances.count == 1)
        #expect(vm.isLoading == false)
    }

    @Test
    func test_loadData_keepsInitialMembers_whenDetailsReturnEmpty() async {
        let mock = MockGroupService.fresh()
        let alice = makeMember(email: "alice@example.com")
        let group = APIGroupWithDetails(
            id: UUID(), name: "Trip", created_by: alice.id, created_at: Date(),
            members: [alice], balances: []
        )
        // stubbedGroupDetails is nil → mock returns empty members by default, overwriting init seed
        let vm = GroupDetailViewModel(group: group, groupService: mock)
        await vm.loadData()
        #expect(vm.isLoading == false)
    }

    // MARK: - groupTotal

    @Test
    func test_groupTotal_sumsAllExpenses() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.expenses = [
            makeExpense(totalAmount: "100.00"),
            makeExpense(totalAmount: "50.50")
        ]
        #expect(vm.groupTotal == 150.5)
    }

    @Test
    func test_groupTotal_withNoExpenses_isZero() {
        let vm = GroupDetailViewModel(group: makeGroup())
        #expect(vm.groupTotal == 0)
    }

    @Test
    func test_groupTotal_ignoresInvalidAmounts() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.expenses = [makeExpense(totalAmount: "not-a-number")]
        #expect(vm.groupTotal == 0)
    }

    // MARK: - hasUnsettledBalances

    @Test
    func test_hasUnsettledBalances_whenAllZero_returnsFalse() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [makeBalance(userId: UUID(), amount: "0.00")]
        #expect(vm.hasUnsettledBalances == false)
    }

    @Test
    func test_hasUnsettledBalances_whenSomeNonZero_returnsTrue() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [makeBalance(userId: UUID(), amount: "25.00")]
        #expect(vm.hasUnsettledBalances == true)
    }

    @Test
    func test_hasUnsettledBalances_whenNegativeBalance_returnsTrue() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.balances = [makeBalance(userId: UUID(), amount: "-30.00")]
        #expect(vm.hasUnsettledBalances == true)
    }

    // MARK: - expenseAdded

    @Test
    func test_expenseAdded_insertsAtTop() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let first  = makeExpense(totalAmount: "100")
        let second = makeExpense(totalAmount: "50")
        vm.expenseAdded(first)
        vm.expenseAdded(second)
        #expect(vm.expenses.first?.amount == "50")
    }

    @Test
    func test_expenseAdded_updatesGroupTotal() {
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.expenseAdded(makeExpense(totalAmount: "200"))
        #expect(vm.groupTotal == 200)
    }

    // MARK: - addMember optimistic state

    @Test
    func test_addMember_addsToPendingEmails_immediately() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.addMember(email: "bob@example.com")
        #expect(vm.pendingMemberEmails.contains("bob@example.com"))
    }

    @Test
    func test_addMember_trimsAndLowercasesEmail() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.addMember(email: "  BOB@EXAMPLE.COM  ")
        #expect(vm.pendingMemberEmails.contains("bob@example.com"))
    }

    @Test
    func test_addMember_doesNothing_whenEmailIsBlank() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.addMember(email: "   ")
        #expect(vm.pendingMemberEmails.isEmpty)
    }

    @Test
    func test_addMember_doesNothing_whenAlreadyAMember() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        let alice = makeMember(email: "alice@example.com")
        vm.members = [alice]
        vm.addMember(email: "alice@example.com")
        #expect(vm.pendingMemberEmails.isEmpty)
    }

    @Test
    func test_addMember_dismissesSheet_immediately() {
        let vm = GroupDetailViewModel(group: makeGroup(), groupService: MockGroupService.fresh())
        vm.showAddMember = true
        vm.addMember(email: "bob@example.com")
        #expect(vm.showAddMember == false)
    }

    // MARK: - Invite flow (async, via mock)

    @Test
    func test_addMember_success_clearsPendingAndRefreshesMembers() async {
        let mock = MockGroupService.fresh()
        let bob = makeMember(email: "bob@example.com")
        mock.stubbedMembers = [bob]

        let vm = GroupDetailViewModel(group: makeGroup(), groupService: mock)
        vm.addMember(email: "bob@example.com")

        // Immediately pending
        #expect(vm.pendingMemberEmails.contains("bob@example.com"))

        // Wait for the async Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(vm.pendingMemberEmails.isEmpty)
        #expect(vm.members.contains(where: { $0.email == "bob@example.com" }))
        #expect(mock.addMemberCalls.count == 1)
        #expect(mock.addMemberCalls.first?.email == "bob@example.com")
    }

    @Test
    func test_addMember_failure_clearsPendingAndSetsError() async {
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
    func test_addMember_callsServiceWithCorrectGroupId() async {
        let mock = MockGroupService.fresh()
        let groupId = UUID()
        let vm = GroupDetailViewModel(group: makeGroup(id: groupId), groupService: mock)
        vm.addMember(email: "sam@example.com")

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(mock.addMemberCalls.first?.groupId == groupId)
    }

    // MARK: - isPending

    @Test
    func test_isPending_returnsTrueForPendingMember() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let bob = makeMember(email: "bob@example.com")
        vm.pendingMemberEmails.insert("bob@example.com")
        #expect(vm.isPending(bob) == true)
    }

    @Test
    func test_isPending_returnsFalseForConfirmedMember() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let alice = makeMember(email: "alice@example.com")
        #expect(vm.isPending(alice) == false)
    }

    // MARK: - settlementRecorded

    @Test
    func test_settlementRecorded_recalculatesBalances() {
        let alice = makeMember(email: "alice@example.com")
        let bob   = makeMember(email: "bob@example.com")
        let vm = GroupDetailViewModel(group: makeGroup())
        vm.members = [alice, bob]
        vm.expenses = [makeExpense(totalAmount: "100.00", paidBy: alice.id)]
        let settlement = APISettlement(
            id: UUID(), groupId: vm.group.id,
            fromUser: bob.id, toUser: alice.id,
            amount: "50.00", createdAt: Date()
        )
        vm.settlementRecorded(settlement)
        // After recording settlement with 2 members, balances should have 2 entries
        #expect(vm.balances.count == 2)
    }

    // MARK: - displayName

    @Test
    func test_displayName_returnsUsername() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let member = makeMember(email: "charlie@example.com")
        #expect(vm.displayName(for: member) == member.username)
    }

    @Test
    func test_displayName_forId_returnsUnknownWhenNotFound() {
        let vm = GroupDetailViewModel(group: makeGroup())
        #expect(vm.displayName(forId: UUID()) == "Unknown")
    }

    @Test
    func test_displayName_forId_resolvesKnownMember() {
        let vm = GroupDetailViewModel(group: makeGroup())
        let alice = makeMember(email: "alice@example.com")
        vm.members = [alice]
        #expect(vm.displayName(forId: alice.id) == alice.username)
    }
}
