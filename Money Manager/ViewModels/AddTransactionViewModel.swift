import SwiftUI
import SwiftData

enum AddTransactionMode {
    case personal(editing: Transaction? = nil)
    case shared(group: APIGroupWithDetails, members: [APIGroupMember], currentUserId: UUID? = nil, editing: APIGroupTransaction? = nil, onAdd: (APIGroupTransaction) -> Void)
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
    var showRecurringAmountAlert = false
    var showError = false

    // Inline recurring fields
    var isRecurring = false
    var recurringFrequency: RecurringFrequency = .monthly
    var recurringDayOfMonth: Int = 1
    var recurringHasEndDate = false
    var recurringEndDate: Date = Date()
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

    private var originalAmount: Double?
    private var pendingSaveCompletion: (() -> Void)?
    private(set) var editingRecurringExpenseId: UUID?

    let mode: AddTransactionMode
    let persistence: PersistenceService
    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }
    var customCategories: [CustomCategory] = []
    private let groupService: GroupServiceProtocol

    // MARK: - Computed

    var isShared: Bool {
        if case .shared = mode { return true }
        return false
    }

    var isEditingShared: Bool {
        if case .shared(_, _, _, let editing, _) = mode { return editing != nil }
        return false
    }

    var navigationTitle: String {
        switch mode {
        case .personal(let editing):
            if let editing {
                return editing.type == .income ? "Edit Income" : "Edit Expense"
            }
            return transactionType == .income ? "Add Income" : "Add Transaction"
        case .shared(_, _, _, let editing, _):
            return editing != nil ? "Edit Group Expense" : "Add Group Expense"
        }
    }

    /// Stable identifier for the current screen mode — use in tests and accessibility.
    /// Unaffected by display copy changes.
    var navigationTitleIdentifier: String {
        switch mode {
        case .personal(let editing):
            if let editing {
                return editing.type == .income ? "edit-income" : "edit-expense"
            }
            return transactionType == .income ? "add-income" : "add-transaction"
        case .shared(_, _, _, let editing, _):
            return editing != nil ? "edit-group-expense" : "add-group-expense"
        }
    }

    var isValid: Bool {
        if isEditingShared {
            return !selectedCategory.isEmpty &&
                   !description.trimmingCharacters(in: .whitespaces).isEmpty
        }

        guard let amountValue = Double(amount), amountValue > 0,
              !selectedCategory.isEmpty else { return false }

        if isRecurring && description.trimmingCharacters(in: .whitespaces).isEmpty { return false }

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
        persistence: PersistenceService = PersistenceService()
    ) {
        self.mode = mode
        self.groupService = groupService
        self.persistence = persistence
        setup()
    }

    func setup() {
        switch mode {
        case .personal(let editing):
            guard let expense = editing else { return }
            originalAmount = expense.amount
            editingRecurringExpenseId = expense.recurringExpenseId
            amount = expense.amount.editableString
            selectedCategory = expense.category
            selectedDate = expense.date
            selectedTime = expense.time ?? Date()
            hasTime = expense.time != nil
            description = expense.transactionDescription ?? ""
            notes = expense.notes ?? ""
            transactionType = TransactionType(kind: expense.type)

        case .shared(_, let members, let currentUserId, let editing, _):
            if let tx = editing {
                let txAmount = Double(tx.totalAmount) ?? 0
                amount = txAmount.editableString
                selectedCategory = tx.category
                description = tx.description ?? ""
                paidByUserId = tx.paidByUserId
                selectedMembers = Set(tx.splits.map(\.userId))
            } else {
                paidByUserId = currentUserId
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
        date.formatted(date: .abbreviated, time: .omitted)
    }

    func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Save

    func save(completion: @escaping () -> Void) {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        // If editing a recurring-linked transaction and amount changed, ask the user
        if case .personal = mode,
           editingRecurringExpenseId != nil,
           let original = originalAmount,
           amountValue != original {
            pendingSaveCompletion = completion
            showRecurringAmountAlert = true
            return
        }

        isSaving = true

        switch mode {
        case .personal:
            savePersonal(amountValue: amountValue, completion: completion)
        case .shared(let group, _, _, _, let onAdd):
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
        let baseDate = selectedDate
        var expenseDate = calendar.startOfDay(for: baseDate)
        if hasTime {
            let tc = calendar.dateComponents([.hour, .minute], from: selectedTime)
            expenseDate = calendar.date(bySettingHour: tc.hour ?? 0,
                                        minute: tc.minute ?? 0,
                                        second: 0,
                                        of: baseDate) ?? baseDate
        }

        let resolvedCategoryId = customCategories.first(where: { $0.name == selectedCategory })?.id

        let transaction: Transaction
        let action: String

        // If recurring is toggled on, create the template first so we can link it atomically.
        var recurringExpenseId: UUID? = nil
        if isRecurring {
            let trimmedName = description.trimmingCharacters(in: .whitespaces)
            let resolvedCategoryIdForRecurring = customCategories.first(where: { $0.name == selectedCategory })?.id
            let recurring = RecurringTransaction(
                name: trimmedName,
                amount: amountValue,
                category: selectedCategory,
                frequency: recurringFrequency,
                dayOfMonth: recurringFrequency == .monthly ? recurringDayOfMonth : nil,
                startDate: baseDate,
                endDate: recurringHasEndDate ? recurringEndDate : nil,
                categoryId: resolvedCategoryIdForRecurring,
                type: transactionType.kind
            )
            persistence.modelContext?.insert(recurring)
            do {
                try persistence.saveRecurring(recurring, action: "create")
                AppLogger.data.info("Recurring transaction saved: \(recurring.id)")
                recurringExpenseId = recurring.id
            } catch {
                AppLogger.data.error("Failed to save recurring: \(error)")
                errorMessage = "Failed to save recurring template"
                showError = true
                isSaving = false
                return
            }
        }

        if case .personal(let existing) = mode, let existingExpense = existing {
            existingExpense.amount = amountValue
            existingExpense.category = selectedCategory
            existingExpense.categoryId = resolvedCategoryId
            existingExpense.date = expenseDate
            existingExpense.time = hasTime ? selectedTime : nil
            if isRecurring {
                existingExpense.transactionDescription = description.trimmingCharacters(in: .whitespaces)
                existingExpense.recurringExpenseId = recurringExpenseId
            } else {
                existingExpense.transactionDescription = description.isEmpty ? nil : description
            }
            existingExpense.notes = notes.isEmpty ? nil : notes
            existingExpense.updatedAt = Date()
            transaction = existingExpense
            action = "update"
        } else {
            let resolvedDescription = isRecurring
                ? description.trimmingCharacters(in: .whitespaces)
                : (description.isEmpty ? nil : description)
            let expense = Transaction(
                type: transactionType.kind,
                amount: amountValue,
                category: selectedCategory,
                date: expenseDate,
                time: hasTime ? selectedTime : nil,
                transactionDescription: resolvedDescription,
                notes: notes.isEmpty ? nil : notes,
                recurringExpenseId: recurringExpenseId,
                
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

    // MARK: - Recurring amount alert responses

    /// Called when user chooses to update only this transaction (not the recurring template).
    func saveThisTransactionOnly() {
        showRecurringAmountAlert = false
        guard let completion = pendingSaveCompletion else { return }
        pendingSaveCompletion = nil
        isSaving = true
        savePersonal(amountValue: Double(amount) ?? 0, completion: completion)
    }

    /// Called when user chooses to update this transaction AND the recurring template.
    func saveAlsoUpdatingRecurring(completion: @escaping () -> Void) {
        showRecurringAmountAlert = false
        pendingSaveCompletion = nil
        if let recurringId = editingRecurringExpenseId,
           let newAmount = Double(amount),
           let ctx = persistence.modelContext {
            let descriptor = FetchDescriptor<RecurringTransaction>(
                predicate: #Predicate { $0.id == recurringId && !$0.isSoftDeleted }
            )
            if let recurring = try? ctx.fetch(descriptor).first {
                recurring.amount = newAmount
                recurring.updatedAt = Date()
                try? persistence.saveRecurring(recurring, action: "update")
            }
        }
        isSaving = true
        savePersonal(amountValue: Double(amount) ?? 0, completion: completion)
    }

    // MARK: - Private: shared save

    private func saveShared(
        amountValue: Double,
        group: APIGroupWithDetails,
        onAdd: @escaping (APIGroupTransaction) -> Void,
        completion: @escaping () -> Void
    ) {
        if case .shared(_, _, _, let editing, _) = mode, let existing = editing {
            saveSharedEdit(existing: existing, group: group, onAdd: onAdd, completion: completion)
        } else {
            saveSharedCreate(amountValue: amountValue, group: group, onAdd: onAdd, completion: completion)
        }
    }

    private func saveSharedCreate(
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
                APIGroupTransactionSplitInput(userId: $0, amount: share)
            }
        } else {
            splits = selectedMembers.compactMap { id in
                guard let raw = customAmounts[id], let value = Double(raw) else { return nil }
                return APIGroupTransactionSplitInput(userId: id, amount: value)
            }
        }

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

    private func saveSharedEdit(
        existing: APIGroupTransaction,
        group: APIGroupWithDetails,
        onAdd: @escaping (APIGroupTransaction) -> Void,
        completion: @escaping () -> Void
    ) {
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        let request = APIUpdateGroupTransactionRequest(
            category: selectedCategory != existing.category ? selectedCategory : nil,
            date: selectedDate != existing.date ? selectedDate : nil,
            description: trimmedDescription != (existing.description ?? "") ? trimmedDescription : nil,
            notes: trimmedNotes.isEmpty ? nil : (trimmedNotes != (existing.notes ?? "") ? trimmedNotes : nil)
        )

        Task {
            do {
                let updated = try await groupService.updateGroupTransaction(request, groupId: group.id, transactionId: existing.id)
                onAdd(updated)
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
