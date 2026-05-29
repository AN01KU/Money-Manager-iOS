import SwiftUI

enum GroupEditorMode {
    case create(group: SplitGroup, members: [GroupMember], currentUserId: UUID?, onAdd: (GroupTransaction) -> Void)
    case edit(group: SplitGroup, members: [GroupMember], transaction: GroupTransaction, onSaved: (GroupTransaction) -> Void)
}

@MainActor
@Observable class GroupTransactionEditorViewModel {
    var amount = ""
    var selectedCategory = "other"
    var description = ""
    var notes = ""
    var showCategoryPicker = false
    var errorMessage: String?
    var isSaving = false
    var selectedDate = Date()
    var paidByUserId: UUID?
    var splitType: SplitType = .equal
    var selectedMembers: Set<UUID> = []
    var customAmounts: [UUID: String] = [:]
    var customCategories: [Category] = []

    let mode: GroupEditorMode
    private let groupService: GroupServiceProtocol

    var isEditingExisting: Bool {
        if case .edit = mode { return true }
        return false
    }

    var navigationTitle: String {
        isEditingExisting ? "Edit Group Expense" : "Add Group Expense"
    }

    var navigationTitleIdentifier: String {
        isEditingExisting ? "edit-group-expense" : "add-group-expense"
    }

    var members: [GroupMember] {
        switch mode {
        case .create(_, let m, _, _): m
        case .edit(_, let m, _, _): m
        }
    }

    var isValid: Bool {
        if isEditingExisting {
            return !selectedCategory.isEmpty &&
                   !description.trimmingCharacters(in: .whitespaces).isEmpty
        }
        guard let amountValue = parsedAmountValue, amountValue > 0 else { return false }
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty,
              paidByUserId != nil,
              !selectedMembers.isEmpty else { return false }
        if splitType == .custom { return splitMatchesTotal }
        return true
    }

    private var parsedAmountValue: Double? {
        Money.parse(amount, currencyCode: CurrencyFormatter.currentCode)?.doubleValue
    }

    private var splitCalculator: SplitCalculator {
        SplitCalculator(
            totalAmount: parsedAmountValue ?? 0,
            selectedMembers: selectedMembers,
            customAmounts: customAmounts,
            splitType: splitType
        )
    }

    var equalShareText: String { splitCalculator.equalShareText }
    var customSplitTotal: Double { splitCalculator.customSplitTotal }
    var splitMatchesTotal: Bool { splitCalculator.splitMatchesTotal }

    init(mode: GroupEditorMode, groupService: GroupServiceProtocol = GroupService.shared) {
        self.mode = mode
        self.groupService = groupService
        setup()
    }

    private func setup() {
        switch mode {
        case .create(_, let members, let currentUserId, _):
            paidByUserId = currentUserId
            selectedMembers = Set(members.map(\.id))
        case .edit(_, _, let tx, _):
            amount = tx.totalAmount.editableString
            selectedCategory = tx.category
            description = tx.description ?? ""
            notes = tx.notes ?? ""
            paidByUserId = tx.paidByUserId
            selectedDate = tx.date
            selectedMembers = Set(tx.splits.map(\.userId))
        }
    }

    func toggleMember(_ id: UUID) {
        if selectedMembers.contains(id) {
            selectedMembers.remove(id)
            customAmounts.removeValue(forKey: id)
        } else {
            selectedMembers.insert(id)
        }
    }

    func displayName(for member: GroupMember) -> String {
        member.username
    }

    func customAmountBinding(for userId: UUID) -> Binding<String> {
        Binding(
            get: { [self] in customAmounts[userId] ?? "" },
            set: { [self] in customAmounts[userId] = $0 }
        )
    }

    func save(completion: @escaping () -> Void) {
        switch mode {
        case .create(let group, _, _, let onAdd):
            saveCreate(groupId: group.id, onAdd: onAdd, completion: completion)
        case .edit(let group, _, let tx, let onSaved):
            saveEdit(existing: tx, groupId: group.id, onSaved: onSaved, completion: completion)
        }
    }

    private func saveCreate(
        groupId: UUID,
        onAdd: @escaping (GroupTransaction) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let amountValue = parsedAmountValue, amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        guard let paidBy = paidByUserId else {
            errorMessage = "Please select who paid"
            return
        }

        let splits = splitCalculator.buildSplits()
        let request = APICreateGroupTransactionRequest(
            paidByUserId: paidBy,
            totalAmount: amountValue,
            category: selectedCategory,
            date: selectedDate,
            description: description.trimmingCharacters(in: .whitespaces),
            notes: nil,
            splits: splits,
            updatedAt: Date()
        )

        isSaving = true
        Task {
            do {
                let expense = try await groupService.createGroupTransaction(request, groupId: groupId)
                onAdd(expense)
                isSaving = false
                completion()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isSaving = false
            }
        }
    }

    private func saveEdit(
        existing: GroupTransaction,
        groupId: UUID,
        onSaved: @escaping (GroupTransaction) -> Void,
        completion: @escaping () -> Void
    ) {
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        let request = APIUpdateGroupTransactionRequest(
            category: selectedCategory != existing.category ? selectedCategory : nil,
            date: selectedDate != existing.date ? selectedDate : nil,
            description: trimmedDescription != (existing.description ?? "") ? trimmedDescription : nil,
            notes: trimmedNotes.isEmpty ? nil : (trimmedNotes != (existing.notes ?? "") ? trimmedNotes : nil),
            updatedAt: existing.updatedAt,
            paidByUserId: paidByUserId != existing.paidByUserId ? paidByUserId : nil
        )

        isSaving = true
        Task {
            do {
                let updated = try await groupService.updateGroupTransaction(request, groupId: groupId, transactionId: existing.id)
                onSaved(updated)
                isSaving = false
                completion()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isSaving = false
            }
        }
    }
}
