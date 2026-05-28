import SwiftUI
import SwiftData

enum EditorMode {
    case create
    case edit(Transaction)
    case view(Transaction)

    var transaction: Transaction? {
        switch self {
        case .create: nil
        case .edit(let t), .view(let t): t
        }
    }

    var isReadOnly: Bool {
        if case .view = self { return true }
        return false
    }

    var isCreate: Bool {
        if case .create = self { return true }
        return false
    }
}

@MainActor
@Observable final class TransactionEditorViewModel {

    // MARK: - Input fields (editable in create/edit modes)

    var amountText = ""
    var selectedCategoryId: UUID = UUID() // set to a valid UUID via customCategories lookup
    var description = ""
    var notes = ""
    var transactionType: TransactionType = .expense
    var selectedDate = Date()
    var selectedTime = Date()
    var hasTime = true

    // MARK: - Recurring fields

    var isRecurring = false
    var recurringFrequency: RecurringFrequency = .monthly
    var recurringDayOfMonth: Int = 1
    var recurringHasEndDate = false
    var recurringEndDate: Date = Date()
    private(set) var editingRecurringExpenseId: UUID?

    // MARK: - UI state

    var showCategoryPicker = false
    var showRecurringAmountAlert = false
    var showDeleteAlert = false
    var customCategories: [Category] = [] {
        didSet { categoryLookup = CategoryResolver.makeLookup(from: customCategories) }
    }
    private var categoryLookup: [UUID: Category] = [:]

    // MARK: - State

    var isSaving = false
    var errorMessage: String?

    // MARK: - Read-only context

    let mode: EditorMode
    @ObservationIgnored var persistence: PersistenceService

    // MARK: - Pending recurring alert

    private var pendingAmountValue: Double?
    private var originalAmount: Double?
    private var originalCategoryId: UUID?
    private var originalType: TransactionType?

    // MARK: - Init

    init(mode: EditorMode = .create, persistence: PersistenceService = .testing) {
        self.mode = mode
        self.persistence = persistence
        if let tx = mode.transaction {
            populate(from: tx)
        }
    }

    // MARK: - Derived / formatted state

    var canSave: Bool {
        guard !mode.isReadOnly else { return false }
        guard let money = parsedMoney, money.amount > 0 else { return false }
        if isRecurring && description.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        return true
    }

    var typeLabel: String {
        transactionType == .income ? "Income" : "Expense"
    }

    var navigationTitle: String {
        switch mode {
        case .create:
            return transactionType == .income ? "Add Income" : "Add Transaction"
        case .edit(let tx):
            return tx.type == .income ? "Edit Income" : "Edit Expense"
        case .view:
            return "Details"
        }
    }

    var navigationTitleIdentifier: String {
        switch mode {
        case .create:
            return transactionType == .income ? "add-income" : "add-transaction"
        case .edit(let tx):
            return tx.type == .income ? "edit-income" : "edit-expense"
        case .view:
            return "transaction-detail"
        }
    }

    // MARK: - View mode (read-only display)

    var categoryName: String { resolvedCategory.name }
    var categoryIcon: String { resolvedCategory.icon }
    var categoryColor: Color { resolvedCategory.color }

    var isGroupTransaction: Bool { mode.transaction?.groupTransactionId != nil }
    var isSettlementTransaction: Bool { mode.transaction?.settlementId != nil }

    private var resolvedCategory: (name: String, icon: String, color: Color) {
        let id = mode.transaction?.categoryId ?? selectedCategoryId
        return CategoryResolver.resolveAll(id, lookup: categoryLookup)
    }

    func formatDateAndTime(_ date: Date, time: Date?) -> String {
        if let time {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            let combined = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                         minute: timeComponents.minute ?? 0,
                                         second: 0, of: date) ?? date
            return combined.formatted(date: .abbreviated, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    func formatFullDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    var dateLabel: String {
        if hasTime {
            return selectedDate.formatted(date: .abbreviated, time: .omitted)
                + " "
                + selectedTime.formatted(date: .omitted, time: .shortened)
        }
        return selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    /// Amount with sign — positive for income, negative for expenses.
    var signedAmountString: String {
        guard let money = parsedMoney else { return "" }
        let sign = transactionType == .expense ? "-" : "+"
        return sign + money.formatted()
    }

    // MARK: - Save

    func save(completion: @escaping () -> Void) {
        guard canSave, let amountValue = parsedMoney?.doubleValue else {
            errorMessage = "Please enter a valid amount"
            return
        }

        if editingRecurringExpenseId != nil {
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
        savePersonal(amountValue: amountValue, completion: completion)
    }

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
            let descriptor = FetchDescriptor<RecurringTransaction>(
                predicate: #Predicate { $0.id == recurringId && !$0.isSoftDeleted }
            )
            if let recurring = try? persistence.modelContext.fetch(descriptor).first {
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

    func delete(completion: @escaping () -> Void) {
        guard let tx = mode.transaction else { return }
        do {
            try persistence.save(tx, action: .delete)
            completion()
        } catch {
            errorMessage = "Failed to delete transaction"
        }
    }

    // MARK: - Private

    private var parsedMoney: Money? {
        Money.parse(amountText, currencyCode: CurrencyFormatter.currentCode)
    }

    private func buildDate() -> Date {
        let calendar = Calendar.current
        if hasTime {
            let tc = calendar.dateComponents([.hour, .minute], from: selectedTime)
            return calendar.date(
                bySettingHour: tc.hour ?? 0,
                minute: tc.minute ?? 0,
                second: 0,
                of: selectedDate
            ) ?? selectedDate
        }
        return calendar.startOfDay(for: selectedDate)
    }

    private func otherCategoryId() -> UUID {
        customCategories.first { $0.key == PredefinedCategory.other.serverKey }?.id ?? UUID()
    }

    private func savePersonal(amountValue: Double, completion: @escaping () -> Void) {
        let resolvedDate = buildDate()

        var recurringExpenseId: UUID? = editingRecurringExpenseId
        if isRecurring && editingRecurringExpenseId == nil {
            let trimmedName = description.trimmingCharacters(in: .whitespaces)
            let recurring = RecurringTransaction(
                name: trimmedName,
                amount: amountValue,
                categoryId: selectedCategoryId,
                frequency: recurringFrequency,
                dayOfMonth: recurringFrequency == .monthly ? recurringDayOfMonth : nil,
                startDate: selectedDate,
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

        do {
            switch mode {
            case .create:
                let resolvedDescription = isRecurring
                    ? description.trimmingCharacters(in: .whitespaces)
                    : (description.isEmpty ? nil : description)
                let tx = Transaction(
                    type: transactionType.kind,
                    amount: amountValue,
                    categoryId: selectedCategoryId,
                    date: resolvedDate,
                    time: hasTime ? selectedTime : nil,
                    transactionDescription: resolvedDescription,
                    notes: notes.isEmpty ? nil : notes,
                    recurringExpenseId: recurringExpenseId
                )
                persistence.modelContext.insert(tx)
                try persistence.save(tx, action: .create)
                AppLogger.data.info("Transaction saved: \(tx.id) action=create")

            case .edit(let tx):
                tx.amount = amountValue
                tx.type = transactionType.kind
                tx.categoryId = selectedCategoryId
                tx.date = resolvedDate
                tx.time = hasTime ? selectedTime : nil
                if isRecurring {
                    tx.transactionDescription = description.trimmingCharacters(in: .whitespaces)
                    tx.recurringExpenseId = recurringExpenseId
                } else {
                    tx.transactionDescription = description.isEmpty ? nil : description
                }
                tx.notes = notes.isEmpty ? nil : notes
                tx.updatedAt = Date()
                try persistence.save(tx, action: .update)
                AppLogger.data.info("Transaction saved: \(tx.id) action=update")

            case .view:
                isSaving = false
                return
            }

            isSaving = false
            completion()
        } catch {
            errorMessage = "Failed to save transaction"
            isSaving = false
        }
    }

    private func populate(from tx: Transaction) {
        amountText = tx.amount.editableString
        selectedCategoryId = tx.categoryId
        description = tx.transactionDescription ?? ""
        notes = tx.notes ?? ""
        transactionType = TransactionType(kind: tx.type)
        selectedDate = tx.date
        selectedTime = tx.time ?? tx.date
        hasTime = tx.time != nil
        editingRecurringExpenseId = tx.recurringExpenseId
        isRecurring = tx.recurringExpenseId != nil
        originalAmount = tx.amount
        originalCategoryId = tx.categoryId
        originalType = TransactionType(kind: tx.type)
    }
}
