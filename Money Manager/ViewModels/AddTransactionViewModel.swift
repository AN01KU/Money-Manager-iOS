import SwiftUI
import SwiftData

enum AddTransactionMode {
    case personal(editing: Transaction? = nil)
    case shared(group: APIGroupWithDetails, members: [APIGroupMember], editing: APIGroupTransaction? = nil, onAdd: (APIGroupTransaction) -> Void)
}

enum TransactionType: String, CaseIterable {
    case expense = "Expense"
    case income  = "Income"

    var kind: TransactionKind {
        switch self {
        case .expense: .expense
        case .income: .income
        }
    }

    init(kind: TransactionKind) {
        switch kind {
        case .expense: self = .expense
        case .income: self = .income
        }
    }
}

enum SplitType: String, CaseIterable {
    case equal  = "Equal"
    case custom = "Custom"
}

@MainActor
@Observable class AddTransactionViewModel {
    var amount = ""
    var selectedCategory = ""
    var description = ""
    var notes = ""
    var transactionType: TransactionType = .expense
    var showCategoryPicker = false
    var showRecurringSheet = false
    var showError = false
    var errorMessage = ""
    var isSaving = false

    var selectedDate = Date()
    var selectedTime = Date()
    var hasTime = true

    // Shared expense fields
    var paidByUserId: UUID?
    var splitType: SplitType = .equal
    var selectedMembers: Set<UUID> = []
    var customAmounts: [UUID: String] = [:]

    let mode: AddTransactionMode
    let persistence: PersistenceService
    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }
    var customCategories: [CustomCategory] = []
    private let groupService: GroupServiceProtocol
    private let auth: AuthServiceProtocol

    // MARK: - Computed

    var isShared: Bool {
        if case .shared = mode { return true }
        return false
    }

    var navigationTitle: String {
        switch mode {
        case .personal(let editing):
            if let editing {
                return editing.type == .income ? "Edit Income" : "Edit Expense"
            }
            return transactionType == .income ? "Add Income" : "Add Expense"
        case .shared(_, _, let editing, _):
            return editing != nil ? "Edit Group Expense" : "Add Group Expense"
        }
    }

    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0,
              !selectedCategory.isEmpty else { return false }

        if case .shared = mode {
            guard !description.trimmingCharacters(in: .whitespaces).isEmpty,
                  paidByUserId != nil,
                  !selectedMembers.isEmpty else { return false }
            if splitType == .custom { return splitMatchesTotal }
        }
        return true
    }

    var equalShareText: String {
        guard let total = Double(amount), total > 0, !selectedMembers.isEmpty else {
            return "\(CurrencyFormatter.currentSymbol)0"
        }
        return CurrencyFormatter.format(total / Double(selectedMembers.count), showDecimals: true)
    }

    var customSplitTotal: Double {
        selectedMembers.compactMap { Double(customAmounts[$0] ?? "") }.reduce(0, +)
    }

    var splitMatchesTotal: Bool {
        guard let total = Double(amount) else { return false }
        return abs(customSplitTotal - total) < 0.01
    }

    // MARK: - Init

    init(
        mode: AddTransactionMode = .personal(),
        groupService: GroupServiceProtocol = GroupService.shared,
        persistence: PersistenceService = PersistenceService(),
        auth: AuthServiceProtocol = authService
    ) {
        self.mode = mode
        self.groupService = groupService
        self.persistence = persistence
        self.auth = auth
        setup()
    }

    func setup() {
        switch mode {
        case .personal(let editing):
            guard let expense = editing else { return }
            amount = expense.amount.formatted(.number.precision(.fractionLength(2)))
            selectedCategory = expense.category
            selectedDate = expense.date
            selectedTime = expense.time ?? Date()
            hasTime = expense.time != nil
            description = expense.transactionDescription ?? ""
            notes = expense.notes ?? ""
            transactionType = TransactionType(kind: expense.type)

        case .shared(_, let members, let editing, _):
            if let tx = editing {
                amount = (Double(tx.total_amount) ?? 0).formatted(.number.precision(.fractionLength(2)))
                selectedCategory = tx.category
                description = tx.description ?? ""
                paidByUserId = tx.paid_by_user_id
                selectedMembers = Set(tx.splits.map(\.user_id))
            } else {
                paidByUserId = auth.currentUser?.id
                selectedMembers = Set(members.map(\.id))
            }
        }
    }

    // MARK: - Helpers

    func customAmountBinding(for userId: UUID) -> Binding<String> {
        Binding(
            get: { [self] in customAmounts[userId] ?? "" },
            set: { [self] in customAmounts[userId] = $0 }
        )
    }

    func displayName(for member: APIGroupMember) -> String {
        member.username
    }

    func toggleMember(_ id: UUID) {
        if selectedMembers.contains(id) {
            selectedMembers.remove(id)
            customAmounts.removeValue(forKey: id)
        } else {
            selectedMembers.insert(id)
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Save

    func save(completion: @escaping () -> Void) {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        isSaving = true

        switch mode {
        case .personal:
            savePersonal(amountValue: amountValue, completion: completion)
        case .shared(let group, _, _, let onAdd):
            saveShared(amountValue: amountValue, group: group, onAdd: onAdd, completion: completion)
        }
    }

    // MARK: - Private: personal save (unchanged logic)

    private func savePersonal(amountValue: Double, completion: @escaping () -> Void) {
        guard modelContext != nil else {
            isSaving = false
            return
        }

        let calendar = Calendar.current
        var expenseDate = calendar.startOfDay(for: selectedDate)
        if hasTime {
            let tc = calendar.dateComponents([.hour, .minute], from: selectedTime)
            expenseDate = calendar.date(bySettingHour: tc.hour ?? 0,
                                        minute: tc.minute ?? 0,
                                        second: 0,
                                        of: selectedDate) ?? selectedDate
        }

        let resolvedCategoryId = customCategories.first(where: { $0.name == selectedCategory })?.id

        let transaction: Transaction
        let action: String

        if case .personal(let existing) = mode, let existingExpense = existing {
            existingExpense.amount = amountValue
            existingExpense.category = selectedCategory
            existingExpense.categoryId = resolvedCategoryId
            existingExpense.date = expenseDate
            existingExpense.time = hasTime ? selectedTime : nil
            existingExpense.transactionDescription = description.isEmpty ? nil : description
            existingExpense.notes = notes.isEmpty ? nil : notes
            existingExpense.updatedAt = Date()
            transaction = existingExpense
            action = "update"
        } else {
            let expense = Transaction(
                type: transactionType.kind,
                amount: amountValue,
                category: selectedCategory,
                date: expenseDate,
                time: hasTime ? selectedTime : nil,
                transactionDescription: description.isEmpty ? nil : description,
                notes: notes.isEmpty ? nil : notes,
                categoryId: resolvedCategoryId
            )
            persistence.modelContext?.insert(expense)
            transaction = expense
            action = "create"
        }

        do {
            try persistence.saveTransaction(transaction, action: action)
            AppLogger.data.info("Expense saved: \(transaction.id) action=\(action)")
        } catch {
            AppLogger.data.error("Failed to save expense: \(error)")
            errorMessage = "Failed to save expense"
            showError = true
            isSaving = false
            return
        }

        isSaving = false
        completion()
    }

    // MARK: - Private: shared save

    private func saveShared(
        amountValue: Double,
        group: APIGroupWithDetails,
        onAdd: @escaping (APIGroupTransaction) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let paidBy = paidByUserId else {
            errorMessage = "Please select who paid"
            showError = true
            isSaving = false
            return
        }

        let splits: [APIGroupTransactionSplitInput]
        if splitType == .equal {
            let share = amountValue / Double(max(selectedMembers.count, 1))
            splits = selectedMembers.map {
                APIGroupTransactionSplitInput(user_id: $0, amount: share.formatted(.number.precision(.fractionLength(2)).grouping(.never)))
            }
        } else {
            splits = selectedMembers.compactMap { id in
                guard let raw = customAmounts[id], let _ = Double(raw) else { return nil }
                return APIGroupTransactionSplitInput(user_id: id, amount: raw)
            }
        }

        let request = APICreateGroupTransactionRequest(
            paid_by_user_id: paidBy,
            total_amount: amountValue.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: selectedCategory,
            date: selectedDate,
            description: description.trimmingCharacters(in: .whitespaces),
            notes: nil,
            splits: splits
        )

        Task {
            do {
                let expense = try await groupService.createGroupTransaction(request, groupId: group.id)
                onAdd(expense)
                isSaving = false
                completion()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
                isSaving = false
            }
        }
    }
}
