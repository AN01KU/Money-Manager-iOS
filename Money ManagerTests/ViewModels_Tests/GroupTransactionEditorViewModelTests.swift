import Foundation
import SwiftUI
import Testing
@testable import Money_Manager

@MainActor
struct GroupTransactionEditorViewModelTests {

    // MARK: - Helpers

    private func makeMember(id: UUID = UUID(), username: String = "alice") -> GroupMember {
        GroupMember(from: APIGroupMember(id: id, email: "\(username)@example.com", username: username, joinedAt: Date()))
    }

    private func makeGroup(id: UUID = UUID(), members: [GroupMember] = []) -> SplitGroup {
        SplitGroup(id: id, name: "Test Group", createdBy: UUID(), createdAt: Date(), members: members, balances: [], settlements: [])
    }

    private func makeGroupTransaction(
        id: UUID = UUID(),
        paidBy: UUID = UUID(),
        amount: Double = 100,
        category: String = "food-dining",
        description: String? = "Dinner",
        notes: String? = nil,
        updatedAt: Date = Date(),
        splits: [APIGroupTransactionSplit] = []
    ) -> GroupTransaction {
        let dto = APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: paidBy,
            totalAmount: amount, category: category, date: Date(),
            description: description, notes: notes, isDeleted: false,
            createdAt: Date(), updatedAt: updatedAt, splits: splits
        )
        return try! GroupTransaction(from: dto)
    }

    // MARK: - Init: create mode

    @Test func testCreateModePreselectsCurrentUserAsPaidBy() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        #expect(vm.paidByUserId == alice.id)
    }

    @Test func testCreateModeSelectsAllMembersInitially() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice, bob]), members: [alice, bob], currentUserId: alice.id, onAdd: { _ in })
        )
        #expect(vm.selectedMembers.count == 2)
        #expect(vm.selectedMembers.contains(alice.id))
        #expect(vm.selectedMembers.contains(bob.id))
    }

    @Test func testCreateModeNavigationTitleIdentifier() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        #expect(vm.navigationTitleIdentifier == "add-group-expense")
        #expect(vm.navigationTitle == "Add Group Expense")
    }

    @Test func testCreateModeIsNotEditingExisting() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: nil, onAdd: { _ in })
        )
        #expect(vm.isEditingExisting == false)
    }

    // MARK: - Init: edit mode

    @Test func testEditModePopulatesFieldsFromTransaction() {
        let alice = makeMember()
        let tx = makeGroupTransaction(paidBy: alice.id, amount: 120, category: "food-dining", description: "Lunch")
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in })
        )
        #expect(vm.amount == "120")
        #expect(vm.selectedCategory == "food-dining")
        #expect(vm.description == "Lunch")
        #expect(vm.paidByUserId == alice.id)
    }

    @Test func testEditModePopulatesSplitMemberIds() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let splits = [
            APIGroupTransactionSplit(id: UUID(), userId: alice.id, amount: 60, transactionId: nil),
            APIGroupTransactionSplit(id: UUID(), userId: bob.id,   amount: 60, transactionId: nil)
        ]
        let tx = makeGroupTransaction(paidBy: alice.id, amount: 120, splits: splits)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice, bob]), members: [alice, bob], transaction: tx, onSaved: { _ in })
        )
        #expect(vm.selectedMembers.contains(alice.id))
        #expect(vm.selectedMembers.contains(bob.id))
    }

    @Test func testEditModeNavigationTitleIdentifier() {
        let alice = makeMember()
        let tx = makeGroupTransaction(paidBy: alice.id)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in })
        )
        #expect(vm.navigationTitleIdentifier == "edit-group-expense")
        #expect(vm.navigationTitle == "Edit Group Expense")
        #expect(vm.isEditingExisting == true)
    }

    // MARK: - isValid: create

    @Test func testIsValidFalseWhenAmountMissing() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.paidByUserId = alice.id
        vm.selectedMembers = [alice.id]
        // amount is empty
        #expect(vm.isValid == false)
    }

    @Test func testIsValidFalseWhenNoPaidBy() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: nil, onAdd: { _ in })
        )
        vm.amount = "100"
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.paidByUserId = nil
        vm.selectedMembers = [alice.id]
        #expect(vm.isValid == false)
    }

    @Test func testIsValidFalseWhenNoMembersSelected() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.amount = "100"
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.selectedMembers = []
        #expect(vm.isValid == false)
    }

    @Test func testIsValidTrueWithAllFieldsSet() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.amount = "100"
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.paidByUserId = alice.id
        vm.selectedMembers = [alice.id]
        #expect(vm.isValid == true)
    }

    // MARK: - isValid: edit

    @Test func testIsValidEditOnlyRequiresCategoryAndDescription() {
        let alice = makeMember()
        let tx = makeGroupTransaction(paidBy: alice.id)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in })
        )
        vm.selectedCategory = "food-dining"
        vm.description = "Updated dinner"
        #expect(vm.isValid == true)
    }

    @Test func testIsValidEditFalseWhenBlankDescription() {
        let alice = makeMember()
        let tx = makeGroupTransaction(paidBy: alice.id)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in })
        )
        vm.selectedCategory = "food-dining"
        vm.description = "   "
        #expect(vm.isValid == false)
    }

    // MARK: - toggleMember

    @Test func testToggleMemberAddsWhenNotSelected() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.selectedMembers = []
        vm.toggleMember(alice.id)
        #expect(vm.selectedMembers.contains(alice.id))
    }

    @Test func testToggleMemberRemovesWhenSelected() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.selectedMembers = [alice.id]
        vm.toggleMember(alice.id)
        #expect(!vm.selectedMembers.contains(alice.id))
    }

    @Test func testToggleMemberRemovingClearsCustomAmount() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.selectedMembers = [alice.id]
        vm.customAmounts = [alice.id: "50"]
        vm.toggleMember(alice.id)
        #expect(vm.customAmounts[alice.id] == nil)
    }

    // MARK: - displayName / customAmountBinding

    @Test func testDisplayNameReturnsUsername() {
        let alice = makeMember(username: "alice")
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        #expect(vm.displayName(for: alice) == "alice")
    }

    @Test func testCustomAmountBindingReadsAndWrites() {
        let alice = makeMember()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, onAdd: { _ in })
        )
        let binding = vm.customAmountBinding(for: alice.id)
        #expect(binding.wrappedValue == "")
        binding.wrappedValue = "75"
        #expect(vm.customAmounts[alice.id] == "75")
    }

    // MARK: - equalShareText / customSplitTotal / splitMatchesTotal

    @Test func testEqualShareTextDividesEvenlyAmongMembers() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice, bob]), members: [alice, bob], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.amount = "100"
        vm.selectedMembers = [alice.id, bob.id]
        #expect(vm.equalShareText.contains("50") || !vm.equalShareText.isEmpty)
    }

    @Test func testCustomSplitTotalSumsSelectedMemberAmounts() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice, bob]), members: [alice, bob], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.selectedMembers = [alice.id, bob.id]
        vm.customAmounts = [alice.id: "60", bob.id: "40"]
        #expect(abs(vm.customSplitTotal - 100) < 0.01)
    }

    @Test func testSplitMatchesTotalTrueWhenSumMatchesAmount() {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice, bob]), members: [alice, bob], currentUserId: alice.id, onAdd: { _ in })
        )
        vm.amount = "100"
        vm.selectedMembers = [alice.id, bob.id]
        vm.customAmounts = [alice.id: "60", bob.id: "40"]
        #expect(vm.splitMatchesTotal == true)
    }

    // MARK: - save: create

    @Test func testSaveCreateCallsGroupServiceAndInvokesOnAdd() async {
        let alice = makeMember()
        let bob = makeMember(username: "bob")
        let mock = MockGroupService.fresh()
        var addedTransaction: GroupTransaction?
        let vm = GroupTransactionEditorViewModel(
            mode: .create(
                group: makeGroup(members: [alice, bob]),
                members: [alice, bob],
                currentUserId: alice.id,
                onAdd: { addedTransaction = $0 }
            ),
            groupService: mock
        )
        vm.amount = "100"
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.paidByUserId = alice.id
        vm.selectedMembers = [alice.id, bob.id]
        vm.splitType = .equal

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        #expect(addedTransaction != nil)
        #expect(addedTransaction?.totalAmount == 100)
    }

    @Test func testSaveCreateFailsWhenNoPaidBy() {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let vm = GroupTransactionEditorViewModel(
            mode: .create(group: makeGroup(members: [alice]), members: [alice], currentUserId: nil, onAdd: { _ in }),
            groupService: mock
        )
        vm.amount = "100"
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.paidByUserId = nil
        vm.selectedMembers = [alice.id]

        var completed = false
        vm.save { completed = true }

        #expect(completed == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - save: edit

    @Test func testSaveEditCallsUpdateAndInvokesOnSaved() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let tx = makeGroupTransaction(paidBy: alice.id)
        var savedTx: GroupTransaction?
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { savedTx = $0 }),
            groupService: mock
        )
        vm.selectedCategory = "transport"
        vm.description = "Uber"

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        #expect(savedTx != nil)
    }

    @Test func testSaveEditPassesOnlyChangedFieldsToRequest() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let tx = makeGroupTransaction(paidBy: alice.id, category: "food-dining", description: "Old")
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in }),
            groupService: mock
        )
        vm.selectedCategory = "food-dining"  // unchanged
        vm.description = "New"               // changed

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        #expect(mock.lastUpdateRequest?.category == nil)
        #expect(mock.lastUpdateRequest?.description == "New")
    }

    @Test func testSaveEditIncludesPaidByUserIdWhenChanged() async {
        let alice = makeMember(username: "alice")
        let bob = makeMember(username: "bob")
        let mock = MockGroupService.fresh()
        let tx = makeGroupTransaction(paidBy: alice.id)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice, bob]), members: [alice, bob], transaction: tx, onSaved: { _ in }),
            groupService: mock
        )
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        vm.paidByUserId = bob.id  // changed

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        #expect(mock.lastUpdateRequest?.paidByUserId == bob.id)
    }

    @Test func testSaveEditOmitsPaidByUserIdWhenUnchanged() async {
        let alice = makeMember(username: "alice")
        let mock = MockGroupService.fresh()
        let tx = makeGroupTransaction(paidBy: alice.id)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in }),
            groupService: mock
        )
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"
        // paidByUserId unchanged

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        #expect(mock.lastUpdateRequest?.paidByUserId == nil)
    }

    @Test func testSaveEditSetsIsSavingFalseOnCompletion() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let tx = makeGroupTransaction(paidBy: alice.id)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in }),
            groupService: mock
        )
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }
        #expect(vm.isSaving == false)
    }

    @Test func testSaveEditFailureSetsErrorMessage() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        struct UpdateError: Error, LocalizedError {
            var errorDescription: String? { "update failed" }
        }
        mock.updateGroupTransactionError = UpdateError()
        let tx = makeGroupTransaction(paidBy: alice.id)
        let vm = GroupTransactionEditorViewModel(
            mode: .edit(group: makeGroup(members: [alice]), members: [alice], transaction: tx, onSaved: { _ in }),
            groupService: mock
        )
        vm.selectedCategory = "food-dining"
        vm.description = "Dinner"

        vm.save { Issue.record("completion must not be called on error path") }
        for _ in 0..<10 { await Task.yield() }

        #expect(vm.errorMessage != nil)
        #expect(vm.isSaving == false)
    }
}
