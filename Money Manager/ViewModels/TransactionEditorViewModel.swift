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
    var selectedCategory = "other"
    var description = ""
    var notes = ""
    var transactionType: TransactionType = .expense
    var selectedDate = Date()
    var selectedTime = Date()
    var hasTime = true

    // MARK: - State

    var isSaving = false
    var errorMessage: String?

    // MARK: - Read-only context

    let mode: EditorMode
    @ObservationIgnored var persistence: PersistenceService

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
        return true
    }

    var typeLabel: String {
        transactionType == .income ? "Income" : "Expense"
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

        isSaving = true

        let resolvedDate = buildDate()

        do {
            switch mode {
            case .create:
                let tx = Transaction(
                    type: transactionType.kind,
                    amount: amountValue,
                    category: selectedCategory,
                    date: resolvedDate,
                    time: hasTime ? selectedTime : nil,
                    transactionDescription: description.isEmpty ? nil : description,
                    notes: notes.isEmpty ? nil : notes
                )
                persistence.modelContext.insert(tx)
                try persistence.save(tx, action: .create)

            case .edit(let tx):
                tx.amount = amountValue
                tx.type = transactionType.kind
                tx.category = selectedCategory
                tx.date = resolvedDate
                tx.time = hasTime ? selectedTime : nil
                tx.transactionDescription = description.isEmpty ? nil : description
                tx.notes = notes.isEmpty ? nil : notes
                tx.updatedAt = Date()
                try persistence.save(tx, action: .update)

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

    private func populate(from tx: Transaction) {
        amountText = tx.amount.editableString
        selectedCategory = tx.category
        description = tx.transactionDescription ?? ""
        notes = tx.notes ?? ""
        transactionType = TransactionType(kind: tx.type)
        selectedDate = tx.date
        selectedTime = tx.time ?? tx.date
        hasTime = tx.time != nil
    }
}
