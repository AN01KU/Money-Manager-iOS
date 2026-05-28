import SwiftUI
import SwiftData

enum AddTransactionMode {
    case personal(editing: Transaction? = nil)
    case shared(group: SplitGroup, members: [GroupMember], currentUserId: UUID? = nil, editing: GroupTransaction? = nil, onAdd: (GroupTransaction) -> Void)
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

struct SplitCalculator {
    let totalAmount: Double
    let selectedMembers: Set<UUID>
    let customAmounts: [UUID: String]
    let splitType: SplitType

    var equalShareText: String {
        guard totalAmount > 0, !selectedMembers.isEmpty else {
            return "\(CurrencyFormatter.currentSymbol)0"
        }
        return CurrencyFormatter.format(totalAmount / Double(selectedMembers.count), showDecimals: true)
    }

    var customSplitTotal: Double {
        selectedMembers
            .compactMap { Money.parse(customAmounts[$0] ?? "", currencyCode: CurrencyFormatter.currentCode)?.doubleValue }
            .reduce(0, +)
    }

    var splitMatchesTotal: Bool {
        totalAmount > 0 && abs(customSplitTotal - totalAmount) < 0.01
    }

    func buildSplits() -> [APIGroupTransactionSplitInput] {
        if splitType == .equal {
            let share = totalAmount / Double(max(selectedMembers.count, 1))
            return selectedMembers.map { APIGroupTransactionSplitInput(userId: $0, amount: share) }
        } else {
            return selectedMembers.compactMap { id in
                guard let raw = customAmounts[id],
                      let money = Money.parse(raw, currencyCode: CurrencyFormatter.currentCode) else { return nil }
                return APIGroupTransactionSplitInput(userId: id, amount: money.doubleValue)
            }
        }
    }
}

@MainActor
@Observable class AddTransactionViewModel {
    var amount = ""
    // Personal path: UUID-based; shared path: string key sent to API
    var selectedCategoryId: UUID = UUID()
    var selectedCategory = "other" // used by shared (group) path only
    var description = ""
    var notes = ""
    var transactionType: TransactionType = .expense
    var showCategoryPicker = false
    var errorMessage: String?
    var showRecurringAmountAlert = false

    // Inline recurring fields
    var isRecurring = false
    var recurringFrequency: RecurringFrequency = .monthly
    var recurringDayOfMonth: Int = 1
    var recurringHasEndDate = false
    var recurringEndDate: Date = Date()
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
    private var originalCategoryId: UUID?
    private var originalType: TransactionType?
    private var pendingAmountValue: Double?
    private(set) var editingRecurringExpenseId: UUID?

    let mode: AddTransactionMode
    @ObservationIgnored var persistence: PersistenceService
    var modelContext: ModelContext { persistence.modelContext }
    var customCategories: [Category] = []
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

        guard let amountValue = parsedAmountValue, amountValue > 0 else { return false }

        if isRecurring && description.trimmingCharacters(in: .whitespaces).isEmpty { return false }

        if case .shared = mode {
            guard !description.trimmingCharacters(in: .whitespaces).isEmpty,
                  paidByUserId != nil,
                  !selectedMembers.isEmpty else { return false }
            if splitType == .custom { return splitMatchesTotal }
        }
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

    // MARK: - Init

    init(
        mode: AddTransactionMode = .personal(),
        groupService: GroupServiceProtocol = GroupService.shared,
        persistence: PersistenceService = .testing
    ) {
        self.mode = mode
        self.groupService = groupService
        self.persistence = persistence
        setup()
    }

    func setup() {
        switch mode {
        case .personal(let editing): setupPersonal(editing: editing)
        case .shared(_, let members, let currentUserId, let editing, _): setupShared(members: members, currentUserId: currentUserId, editing: editing)
        }
    }

    private func setupPersonal(editing: Transaction?) {
        guard let expense = editing else { return }
        originalAmount = expense.amount
        originalCategoryId = expense.categoryId
        originalType = TransactionType(kind: expense.type)
        editingRecurringExpenseId = expense.recurringExpenseId
        isRecurring = expense.recurringExpenseId != nil
        amount = expense.amount.editableString
        selectedCategoryId = expense.categoryId
        selectedDate = expense.date
        selectedTime = expense.time ?? Date()
        hasTime = expense.time != nil
        description = expense.transactionDescription ?? ""
        notes = expense.notes ?? ""
        transactionType = TransactionType(kind: expense.type)
    }

    private func setupShared(members: [GroupMember], currentUserId: UUID?, editing: GroupTransaction?) {
        if let tx = editing {
            let txAmount = tx.totalAmount
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

    // MARK: - Helpers

    func customAmountBinding(for userId: UUID) -> Binding<String> {
        Binding(
            get: { [self] in customAmounts[userId] ?? "" },
            set: { [self] in customAmounts[userId] = $0 }
        )
    }

    func displayName(for member: GroupMember) -> String {
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
        guard let amountValue = parsedAmountValue, amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        if case .personal = mode, editingRecurringExpenseId != nil {
            let amountChanged = originalAmount.map { amountValue != $0 } ?? false
            let categoryChanged = originalCategoryId.map { selectedCategoryId != $0 } ?? false
            let typeChanged = originalType.map { transactionType != $0 } ?? false
            if amountChanged || categoryChanged || typeChanged {
                pendingAmountValue = amountValue
                showRecurringAmountAlert = true
                return
            }
        }

        isSaving = true

        switch mode {
        case .personal:
            savePersonal(amountValue: amountValue, completion: completion)
        case .shared(let group, _, _, _, let onAdd):
            saveShared(amountValue: amountValue, groupId: group.id, onAdd: onAdd, completion: completion)
        }
    }

    // MARK: - Private: personal save

    private func savePersonal(amountValue: Double, completion: @escaping () -> Void) {
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

        let transaction: Transaction
        let action: ChangeAction

        var recurringExpenseId: UUID? = editingRecurringExpenseId
        if isRecurring && editingRecurringExpenseId == nil {
            let trimmedName = description.trimmingCharacters(in: .whitespaces)
            let recurring = RecurringTransaction(
                name: trimmedName,
                amount: amountValue,
                categoryId: selectedCategoryId,
                frequency: recurringFrequency,
                dayOfMonth: recurringFrequency == .monthly ? recurringDayOfMonth : nil,
                startDate: baseDate,
                endDate: recurringHasEndDate ? recurringEndDate : nil,
                type: transactionType.kind
            )
            persistence.modelContext.insert(recurring)
            do {
                try persistence.save(recurring, action: .create)
                AppLogger.data.info("Recurring transaction saved: \(recurring.id)")
                recurringExpenseId = recurring.id
            } catch {
                AppLogger.data.error("Failed to save recurring: \(error)")
                errorMessage = "Failed to save recurring template"
                isSaving = false
                return
            }
        }

        if case .personal(let existing) = mode, let existingExpense = existing {
            existingExpense.amount = amountValue
            existingExpense.type = transactionType.kind
            existingExpense.categoryId = selectedCategoryId
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
            action = .update
        } else {
            let resolvedDescription = isRecurring
                ? description.trimmingCharacters(in: .whitespaces)
                : (description.isEmpty ? nil : description)
            let expense = Transaction(
                type: transactionType.kind,
                amount: amountValue,
                categoryId: selectedCategoryId,
                date: expenseDate,
                time: hasTime ? selectedTime : nil,
                transactionDescription: resolvedDescription,
                notes: notes.isEmpty ? nil : notes,
                recurringExpenseId: recurringExpenseId
            )
            persistence.modelContext.insert(expense)
            transaction = expense
            action = .create
        }

        do {
            try persistence.save(transaction, action: action)
            AppLogger.data.info("Expense saved: \(transaction.id) action=\(action.rawValue)")
        } catch {
            AppLogger.data.error("Failed to save expense: \(error)")
            errorMessage = "Failed to save expense"
            isSaving = false
            return
        }

        isSaving = false
        completion()
    }

    // MARK: - Recurring amount alert responses

    func saveThisTransactionOnly(completion: @escaping () -> Void) {
        let amountValue = pendingAmountValue ?? 0
        pendingAmountValue = nil
        isSaving = true
        savePersonal(amountValue: amountValue, completion: completion)
    }

    func saveAlsoUpdatingRecurring(completion: @escaping () -> Void) {
        let amountValue = pendingAmountValue ?? 0
        pendingAmountValue = nil
        if let recurringId = editingRecurringExpenseId {
            let ctx = persistence.modelContext
            let descriptor = FetchDescriptor<RecurringTransaction>(
                predicate: #Predicate { $0.id == recurringId && !$0.isSoftDeleted }
            )
            if let recurring = try? ctx.fetch(descriptor).first {
                recurring.amount = amountValue
                recurring.categoryId = selectedCategoryId
                recurring.type = transactionType.kind
                recurring.updatedAt = Date()
                try? persistence.save(recurring, action: .update)
            }
        }
        isSaving = true
        savePersonal(amountValue: amountValue, completion: completion)
    }

    // MARK: - Private: shared save

    private func saveShared(
        amountValue: Double,
        groupId: UUID,
        onAdd: @escaping (GroupTransaction) -> Void,
        completion: @escaping () -> Void
    ) {
        if case .shared(_, _, _, let editing, _) = mode, let existing = editing {
            saveSharedEdit(existing: existing, groupId: groupId, onAdd: onAdd, completion: completion)
        } else {
            saveSharedCreate(amountValue: amountValue, groupId: groupId, onAdd: onAdd, completion: completion)
        }
    }

    private func saveSharedCreate(
        amountValue: Double,
        groupId: UUID,
        onAdd: @escaping (GroupTransaction) -> Void,
        completion: @escaping () -> Void
    ) {
        guard let paidBy = paidByUserId else {
            errorMessage = "Please select who paid"
            isSaving = false
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

    private func saveSharedEdit(
        existing: GroupTransaction,
        groupId: UUID,
        onAdd: @escaping (GroupTransaction) -> Void,
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

        Task {
            do {
                let updated = try await groupService.updateGroupTransaction(request, groupId: groupId, transactionId: existing.id)
                onAdd(updated)
                isSaving = false
                completion()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                isSaving = false
            }
        }
    }
}
