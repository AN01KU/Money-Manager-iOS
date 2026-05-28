import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests covering AddTransactionViewModel.saveSharedEdit and
/// the remaining isValid/navigationTitle paths.
@MainActor
struct AddTransactionViewModelEditSharedTests {

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
        category: String = "Food",
        description: String? = "Dinner",
        notes: String? = nil,
        updatedAt: Date = Date()
    ) -> GroupTransaction {
        let dto = APIGroupTransaction(
            id: id, groupId: UUID(), paidByUserId: paidBy,
            totalAmount: amount, category: category, date: Date(),
            description: description, notes: notes, isDeleted: false,
            createdAt: Date(), updatedAt: updatedAt, splits: []
        )
        return try! GroupTransaction(from: dto)
    }

    /// Returns a GroupService backed by a MockAPIClient configured for edit (PATCH) saves.
    private func makeEditService(groupId: UUID = UUID(), patchError: Error? = nil) -> (GroupService, MockAPIClient) {
        let client = MockAPIClient()
        client.patchHandler = { endpoint, _ in
            if case .groupTransaction = endpoint {
                if let err = patchError { throw err }
                return APIGroupTransaction(
                    id: UUID(), groupId: groupId, paidByUserId: UUID(),
                    totalAmount: 100, category: "Food", date: Date(),
                    description: "Updated", notes: nil, isDeleted: false,
                    createdAt: Date(), updatedAt: Date(), splits: []
                )
            }
            throw MockAPIClient.MockError.notConfigured
        }
        return (GroupService(apiClient: client), client)
    }

    /// Decodes the last PATCH body from a MockAPIClient into an APIUpdateGroupTransactionRequest.
    private func lastUpdateRequest(from client: MockAPIClient) -> APIUpdateGroupTransactionRequest? {
        guard let data = client.patchCalls.last?.body else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            let ms = try container.decode(Int64.self)
            return Date(timeIntervalSince1970: Double(ms) / 1000.0)
        }
        return try? decoder.decode(APIUpdateGroupTransactionRequest.self, from: data)
    }

    // MARK: - saveSharedEdit success

    @Test func testSaveSharedEditCallsUpdateAndInvokesOnAdd() async {
        let alice = makeMember()
        let group = makeGroup(members: [alice])
        let (service, _) = makeEditService(groupId: group.id)
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        var addedTx: GroupTransaction?
        let mode = AddTransactionMode.shared(
            group: group, members: [alice],
            currentUserId: alice.id, editing: existingTx,
            onAdd: { addedTx = $0 }
        )
        let vm = AddTransactionViewModel(mode: mode, groupService: service)
        vm.selectedCategory = "Transport"
        vm.description = "Uber"

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        #expect(addedTx != nil)
    }

    @Test func testSaveSharedEditSetsIsSavingFalseOnCompletion() async {
        let alice = makeMember()
        let group = makeGroup(members: [alice])
        let (service, _) = makeEditService(groupId: group.id)
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: service)
        vm.selectedCategory = "Transport"
        vm.description = "Uber"

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }
        #expect(vm.isSaving == false)
    }

    @Test func testSaveSharedEditFailureSetsShowError() async {
        let alice = makeMember()
        struct UpdateError: Error, LocalizedError {
            var errorDescription: String? { "update failed" }
        }
        let group = makeGroup(members: [alice])
        let (service, _) = makeEditService(groupId: group.id, patchError: UpdateError())
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: service)
        vm.selectedCategory = "Transport"
        vm.description = "Uber"

        vm.save { Issue.record("completion must not be called on error path") }
        // Yield to let the spawned Task run to completion on @MainActor.
        for _ in 0..<10 { await Task.yield() }

        #expect(vm.errorMessage != nil)
        #expect(vm.isSaving == false)
    }

    @Test func testSaveSharedEditPassesOnlyChangedFieldsToRequest() async {
        let alice = makeMember()
        let group = makeGroup(members: [alice])
        let (service, client) = makeEditService(groupId: group.id)
        // Existing tx has category "Food" — we only change the description
        let existingTx = makeGroupTransaction(paidBy: alice.id, category: "Food", description: "Old Description")
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: service)
        vm.selectedCategory = "Food"       // unchanged
        vm.description = "New Description" // changed

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        let req = lastUpdateRequest(from: client)
        #expect(req?.category == nil) // unchanged category not sent
        #expect(req?.description == "New Description")
    }

    @Test func testSaveSharedEditIncludesUpdatedAtInPayload() async {
        let alice = makeMember()
        let group = makeGroup(members: [alice])
        let (service, client) = makeEditService(groupId: group.id)
        let knownDate = Date(timeIntervalSince1970: 1_700_000_000)
        let existingTx = makeGroupTransaction(paidBy: alice.id, updatedAt: knownDate)
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: service)
        vm.selectedCategory = "Transport"
        vm.description = "Taxi"

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        let req = lastUpdateRequest(from: client)
        // updatedAt is encoded as ms epoch and decoded back — within 1ms tolerance
        let reqUpdatedAt = req?.updatedAt
        #expect(reqUpdatedAt != nil)
        #expect(abs((reqUpdatedAt?.timeIntervalSince1970 ?? 0) - knownDate.timeIntervalSince1970) < 1)
    }

    @Test func testSaveSharedEditIncludesPaidByUserIdWhenChanged() async {
        let alice = makeMember(username: "alice")
        let bob = makeMember(username: "bob")
        let group = makeGroup(members: [alice, bob])
        let (service, client) = makeEditService(groupId: group.id)
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: group, members: [alice, bob], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: service)
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        vm.paidByUserId = bob.id   // changed from alice → bob

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        let req = lastUpdateRequest(from: client)
        #expect(req?.paidByUserId == bob.id)
    }

    @Test func testSaveSharedEditOmitsPaidByUserIdWhenUnchanged() async {
        let alice = makeMember(username: "alice")
        let group = makeGroup(members: [alice])
        let (service, client) = makeEditService(groupId: group.id)
        let existingTx = makeGroupTransaction(paidBy: alice.id)
        let mode = AddTransactionMode.shared(group: group, members: [alice], currentUserId: alice.id, editing: existingTx, onAdd: { _ in })
        let vm = AddTransactionViewModel(mode: mode, groupService: service)
        vm.selectedCategory = "Food"
        vm.description = "Dinner"
        // paidByUserId remains alice.id (unchanged)

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            vm.save { cont.resume() }
        }

        let req = lastUpdateRequest(from: client)
        #expect(req?.paidByUserId == nil)
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
        let income = Transaction(type: .income, amount: 500, categoryId: UUID(), date: Date())
        let vm = AddTransactionViewModel(mode: .personal(editing: income))
        #expect(vm.navigationTitle == "Edit Income")
    }

    @Test func testNavigationTitleForAddIncome() {
        let vm = AddTransactionViewModel(mode: .personal())
        vm.transactionType = .income
        #expect(vm.navigationTitle == "Add Income")
    }
}
