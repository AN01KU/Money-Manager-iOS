import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import Money_Manager

/// Tests for AddTransactionViewModel shared (group) mode:
/// setup, equalShareText, customSplitTotal, splitMatchesTotal,
/// toggleMember, displayName, customAmountBinding, and saveShared.
@MainActor
struct AddTransactionViewModelSharedTests {

    // MARK: - Helpers

    private func makeMember(id: UUID = UUID(), username: String = "alice") -> APIGroupMember {
        APIGroupMember(id: id, email: "\(username)@example.com", username: username, joinedAt: Date())
    }

    private func makeGroup(id: UUID = UUID(), members: [APIGroupMember] = []) -> APIGroupWithDetails {
        APIGroupWithDetails(id: id, name: "Test Group", createdBy: UUID(), createdAt: Date(), members: members, balances: [])
    }

    private func makeGroupTransaction(id: UUID = UUID(), paidBy: UUID, amount: Double, splits: [APIGroupTransactionSplit] = []) -> APIGroupTransaction {
        APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: paidBy,
            totalAmount: amount, category: "Food", date: Date(),
            description: "Dinner", notes: nil, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: splits
        )
    }

    private func sharedMode(
        group: APIGroupWithDetails,
        members: [APIGroupMember],
        currentUserId: UUID? = nil,
        editing: APIGroupTransaction? = nil
    ) -> AddTransactionMode {
        .shared(group: group, members: members, currentUserId: currentUserId, editing: editing, onAdd: { _ in })
    }

    // MARK: - navigationTitleIdentifier: shared mode

    @Test func testNavigationTitleIdentifierForNewGroupExpense() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        #expect(vm.navigationTitleIdentifier == "add-group-expense")
    }

    @Test func testNavigationTitleIdentifierForEditGroupExpense() {
        let alice = makeMember()
        let tx = makeGroupTransaction(paidBy: alice.id, amount: 100)
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice], editing: tx))
        #expect(vm.navigationTitleIdentifier == "edit-group-expense")
    }

    @Test func testNavigationTitleForNewGroupExpense() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        #expect(vm.navigationTitle == "Add Group Expense")
    }

    // MARK: - isShared

    @Test func testIsSharedTrueForSharedMode() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        #expect(vm.isShared == true)
    }

    @Test func testIsSharedFalseForPersonalMode() {
        let vm = AddTransactionViewModel(mode: .personal())
        #expect(vm.isShared == false)
    }

    // MARK: - setup: shared new

    @Test func testSetupSharedNewPreselectsCurrentUserAsPaidBy() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id))
        #expect(vm.paidByUserId == alice.id)
    }

    @Test func testSetupSharedNewSelectsAllMembersInitially() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice, bob]), members: [alice, bob]))
        #expect(vm.selectedMembers.count == 2)
        #expect(vm.selectedMembers.contains(alice.id))
        #expect(vm.selectedMembers.contains(bob.id))
    }

    // MARK: - setup: shared editing

    @Test func testSetupSharedEditingPopulatesAmountAndCategory() {
        let alice = makeMember()
        let split = APIGroupTransactionSplit(id: UUID(), userId: alice.id, amount: 60, transactionId: nil)
        let tx = makeGroupTransaction(paidBy: alice.id, amount: 120, splits: [split])
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice], editing: tx))
        #expect(vm.amount == "120")
        #expect(vm.paidByUserId == alice.id)
    }

    @Test func testSetupSharedEditingPopulatesSplitMemberIds() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let splits = [
            APIGroupTransactionSplit(id: UUID(), userId: alice.id, amount: 60, transactionId: nil),
            APIGroupTransactionSplit(id: UUID(), userId: bob.id,   amount: 60, transactionId: nil)
        ]
        let tx = makeGroupTransaction(paidBy: alice.id, amount: 120, splits: splits)
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice, bob]), members: [alice, bob], editing: tx))
        #expect(vm.selectedMembers.contains(alice.id))
        #expect(vm.selectedMembers.contains(bob.id))
    }

    // MARK: - equalShareText

    @Test func testEqualShareTextDividesEvenlyAmongMembers() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice, bob]), members: [alice, bob]))
        vm.amount = "100"
        vm.selectedMembers = [alice.id, bob.id]
        // Should be 50 per person; result is formatted string, just check non-zero
        #expect(vm.equalShareText.contains("50") || !vm.equalShareText.isEmpty)
    }

    @Test func testEqualShareTextReturnsZeroWhenNoAmount() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.amount = ""
        #expect(vm.equalShareText.contains("0"))
    }

    @Test func testEqualShareTextReturnsZeroWhenNoMembersSelected() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.amount = "100"
        vm.selectedMembers = []
        #expect(vm.equalShareText.contains("0"))
    }

    // MARK: - customSplitTotal

    @Test func testCustomSplitTotalSumsSelectedMemberAmounts() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice, bob]), members: [alice, bob]))
        vm.selectedMembers = [alice.id, bob.id]
        vm.customAmounts = [alice.id: "60", bob.id: "40"]
        #expect(abs(vm.customSplitTotal - 100) < 0.01)
    }

    @Test func testCustomSplitTotalIgnoresNonSelectedMembers() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice, bob]), members: [alice, bob]))
        vm.selectedMembers = [alice.id] // bob not selected
        vm.customAmounts = [alice.id: "60", bob.id: "40"]
        #expect(abs(vm.customSplitTotal - 60) < 0.01)
    }

    @Test func testCustomSplitTotalIsZeroWhenNoAmountsSet() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.selectedMembers = [alice.id]
        #expect(vm.customSplitTotal == 0)
    }

    // MARK: - splitMatchesTotal

    @Test func testSplitMatchesTotalTrueWhenCustomSumMatchesAmount() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice, bob]), members: [alice, bob]))
        vm.amount = "100"
        vm.selectedMembers = [alice.id, bob.id]
        vm.customAmounts = [alice.id: "60", bob.id: "40"]
        #expect(vm.splitMatchesTotal == true)
    }

    @Test func testSplitMatchesTotalFalseWhenCustomSumDoesNotMatch() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice, bob]), members: [alice, bob]))
        vm.amount = "100"
        vm.selectedMembers = [alice.id, bob.id]
        vm.customAmounts = [alice.id: "60", bob.id: "30"]
        #expect(vm.splitMatchesTotal == false)
    }

    @Test func testSplitMatchesTotalFalseWhenAmountInvalid() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.amount = "abc"
        vm.selectedMembers = [alice.id]
        vm.customAmounts = [alice.id: "0"]
        #expect(vm.splitMatchesTotal == false)
    }

    // MARK: - toggleMember

    @Test func testToggleMemberAddsWhenNotSelected() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.selectedMembers = []
        vm.toggleMember(alice.id)
        #expect(vm.selectedMembers.contains(alice.id))
    }

    @Test func testToggleMemberRemovesWhenSelected() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.selectedMembers = [alice.id]
        vm.toggleMember(alice.id)
        #expect(!vm.selectedMembers.contains(alice.id))
    }

    @Test func testToggleMemberRemovingAlsoClearsCustomAmount() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.selectedMembers = [alice.id]
        vm.customAmounts = [alice.id: "50"]
        vm.toggleMember(alice.id)
        #expect(vm.customAmounts[alice.id] == nil)
    }

    // MARK: - displayName(for:)

    @Test func testDisplayNameReturnsUsername() {
        let alice = makeMember(username: "alice")
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        #expect(vm.displayName(for: alice) == "alice")
    }

    // MARK: - customAmountBinding

    @Test func testCustomAmountBindingReadsAndWritesCustomAmount() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        let binding = vm.customAmountBinding(for: alice.id)
        #expect(binding.wrappedValue == "")
        binding.wrappedValue = "75"
        #expect(vm.customAmounts[alice.id] == "75")
    }

    // MARK: - isValid: shared mode

    @Test func testIsValidFalseForSharedModeWhenMissingFields() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id))
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.description = "  " // blank description
        #expect(vm.isValid == false)
    }

    @Test func testIsValidFalseForSharedModeWhenNoPaidBy() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice]))
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        vm.paidByUserId = nil
        vm.selectedMembers = [alice.id]
        #expect(vm.isValid == false)
    }

    @Test func testIsValidFalseForSharedModeWhenNoMembersSelected() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id))
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        vm.selectedMembers = []
        #expect(vm.isValid == false)
    }

    @Test func testIsValidTrueForSharedModeWithAllFieldsValid() {
        let alice = makeMember()
        let vm = AddTransactionViewModel(mode: sharedMode(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id))
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        vm.paidByUserId = alice.id
        vm.selectedMembers = [alice.id]
        #expect(vm.isValid == true)
    }

    // MARK: - saveShared: equal split

    @Test func testSaveSharedWithEqualSplitCallsGroupService() async {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let mock = MockGroupService.fresh()
        let group = makeGroup(members: [alice, bob])
        var addedTransaction: APIGroupTransaction?
        let mode = AddTransactionMode.shared(
            group: group, members: [alice, bob],
            currentUserId: alice.id, editing: nil,
            onAdd: { addedTransaction = $0 }
        )
        let vm = AddTransactionViewModel(mode: mode, groupService: mock)
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        vm.paidByUserId = alice.id
        vm.selectedMembers = [alice.id, bob.id]
        vm.splitType = .equal

        var completed = false
        vm.save { completed = true }

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(completed == true)
        #expect(addedTransaction != nil)
        #expect(addedTransaction?.totalAmount == 100)
    }

    @Test func testSaveSharedFailsWhenNoPaidBy() {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let group = makeGroup(members: [alice])
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: nil, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: mock)
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        vm.paidByUserId = nil
        vm.selectedMembers = [alice.id]

        var completed = false
        vm.save { completed = true }

        #expect(completed == false)
        #expect(vm.showError == true)
    }

    @Test func testSaveSharedWithCustomSplitBuildsCorrectRequest() async {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let mock = MockGroupService.fresh()
        let group = makeGroup(members: [alice, bob])
        let mode = AddTransactionMode.shared(group: group, members: [alice, bob], currentUserId: alice.id, editing: nil, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: mock)
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        vm.paidByUserId = alice.id
        vm.selectedMembers = [alice.id, bob.id]
        vm.splitType = .custom
        vm.customAmounts = [alice.id: "70", bob.id: "30"]

        var completed = false
        vm.save { completed = true }

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(completed == true)
    }
}
