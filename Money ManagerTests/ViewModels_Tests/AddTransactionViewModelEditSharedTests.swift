import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests covering AddTransactionViewModel.saveSharedEdit and
/// the remaining isValid/navigationTitle paths.
@MainActor
struct AddTransactionViewModelEditSharedTests {

    // MARK: - Helpers

    private func makeMember(id: UUID = UUID(), username: String = "alice") -> APIGroupMember {
        APIGroupMember(id: id, email: "\(username)@example.com", username: username, joinedAt: Date())
    }

    private func makeGroup(id: UUID = UUID(), members: [APIGroupMember] = []) -> APIGroupWithDetails {
        APIGroupWithDetails(id: id, name: "Test Group", createdBy: UUID(), createdAt: Date(), members: members, balances: [])
    }

    private func makeGroupTransaction(
        id: UUID = UUID(),
        paidBy: UUID = UUID(),
        amount: Double = 100,
        category: String = "Food",
        description: String? = "Dinner",
        notes: String? = nil
    ) -> APIGroupTransaction {
        APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: paidBy,
            totalAmount: amount, category: category, date: Date(),
            description: description, notes: notes, isDeleted: false,
            createdAt: Date(), updatedAt: Date(), splits: []
        )
    }

    // MARK: - saveSharedEdit success

    @Test func testSaveSharedEditCallsUpdateAndInvokesOnAdd() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let group = makeGroup(members: [alice])
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        var addedTx: APIGroupTransaction?
        let mode = AddTransactionMode.shared(
            group: group, members: [alice],
            currentUserId: alice.id, editing: existingTx,
            onAdd: { addedTx = $0 }
        )
        let vm = AddTransactionViewModel(mode: mode, groupService: mock)
        vm.selectedCategory = "Transport"
        vm.description = "Uber"

        var completed = false
        vm.save { completed = true }

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(completed == true)
        #expect(addedTx != nil)
    }

    @Test func testSaveSharedEditSetsIsSavingFalseOnCompletion() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let group = makeGroup(members: [alice])
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: mock)
        vm.selectedCategory = "Transport"
        vm.description = "Uber"

        vm.save { }
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.isSaving == false)
    }

    @Test func testSaveSharedEditFailureSetsShowError() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        struct UpdateError: Error, LocalizedError {
            var errorDescription: String? { "update failed" }
        }
        mock.updateGroupTransactionError = UpdateError()
        let group = makeGroup(members: [alice])
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: mock)
        vm.selectedCategory = "Transport"
        vm.description = "Uber"

        var completed = false
        vm.save { completed = true }
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(completed == false)
        #expect(vm.showError == true)
        #expect(vm.isSaving == false)
    }

    @Test func testSaveSharedEditPassesOnlyChangedFieldsToRequest() async {
        let alice = makeMember()
        let mock = MockGroupService.fresh()
        let group = makeGroup(members: [alice])
        // Existing tx has category "Food" — we only change the description
        let existingTx = makeGroupTransaction(paidBy: alice.id, category: "Food", description: "Old Description")
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: mock)
        vm.selectedCategory = "Food"     // unchanged
        vm.description = "New Description" // changed

        vm.save { }
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(mock.lastUpdateRequest?.category == nil) // unchanged category not sent
        #expect(mock.lastUpdateRequest?.description == "New Description")
    }

    // MARK: - isValid edge cases

    @Test func testIsValidFalseForRecurringWithBlankDescription() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.isRecurring = true
        vm.description = "  "
        #expect(vm.isValid == false)
    }

    @Test func testIsValidTrueForRecurringWithDescription() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.amount = "100"
        vm.selectedCategory = "Food"
        vm.isRecurring = true
        vm.description = "Monthly rent"
        #expect(vm.isValid == true)
    }

    @Test func testIsValidForEditingSharedRequiresOnlyCategoryAndDescription() {
        let alice = makeMember()
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode)
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        #expect(vm.isValid == true)
    }

    @Test func testIsValidFalseForEditingSharedWithBlankCategory() {
        let alice = makeMember()
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: makeGroup(members: [alice]), members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode)
        vm.selectedCategory = ""
        vm.description = "Dinner"
        #expect(vm.isValid == false)
    }

    // MARK: - navigationTitle edge case

    @Test func testNavigationTitleForEditingIncomePersonal() {
        let income = Transaction(type: .income, amount: 500, category: "Salary", date: Date())
        let vm = AddTransactionViewModel(mode: .personal(editing: income))
        #expect(vm.navigationTitle == "Edit Income")
    }

    @Test func testNavigationTitleForAddIncome() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.transactionType = .income
        #expect(vm.navigationTitle == "Add Income")
    }
}
