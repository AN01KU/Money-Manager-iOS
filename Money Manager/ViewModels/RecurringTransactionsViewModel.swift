import SwiftUI
import SwiftData

@MainActor
@Observable class RecurringTransactionsViewModel {
    var recurring: [RecurringTransaction] = []
    var showAddSheet = false
    var editingRecurring: RecurringTransaction?

    var activeRecurring: [RecurringTransaction] {
        recurring.filter { $0.isActive }
    }

    var pausedRecurring: [RecurringTransaction] {
        recurring.filter { !$0.isActive }
    }

    var allRecurring: [RecurringTransaction] {
        recurring
    }

    /// Active recurring transactions with a next occurrence falling within the current calendar month.
    var upcomingThisMonth: [RecurringTransaction] {
        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) else { return [] }
        return activeRecurring
            .filter { item in
                guard let next = item.nextOccurrence else { return false }
                return next >= start && next <= end
            }
            .sorted { ($0.nextOccurrence ?? .distantFuture) < ($1.nextOccurrence ?? .distantFuture) }
    }

    /// Net amount for upcoming transactions this month (income - expense).
    var upcomingTotalThisMonth: Double {
        upcomingThisMonth.reduce(0) { total, item in
            item.type == .income ? total + item.amount : total - item.amount
        }
    }

    var modelContext: ModelContext { persistence.modelContext }
    @ObservationIgnored var persistence: PersistenceService

    init(persistence: PersistenceService = .testing) {
        self.persistence = persistence
    }

    func update(recurring: [RecurringTransaction]) {
        self.recurring = recurring
    }

    func toggle(_ item: RecurringTransaction) {
        item.isActive.toggle()
        item.updatedAt = Date()
        do {
            try persistence.save(item, action: .update)
            AppLogger.data.info("Recurring transaction toggled: \(item.id) isActive=\(item.isActive)")
        } catch {
            AppLogger.data.error("Error toggling recurring transaction: \(error)")
        }
    }

    func deleteItem(_ item: RecurringTransaction) {
        let recurringId = item.id

        // Remove from the in-memory array first so computed properties (upcomingThisMonth, etc.)
        // never access the item's attributes after SwiftData detaches its backing store.
        recurring.removeAll { $0.id == recurringId }

        item.isSoftDeleted = true
        item.updatedAt = Date()

        let mctx = modelContext
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.recurringExpenseId == recurringId }
        )
        if let linked = try? mctx.fetch(descriptor) {
            for tx in linked { tx.recurringExpenseId = nil }
        }

        do {
            try persistence.saveAndSync(
                entityType: .recurring,
                entityID: recurringId,
                action: .delete,
                endpoint: "/recurring-transactions",
                httpMethod: .delete,
                payload: nil
            )
            AppLogger.data.info("Recurring transaction deleted: \(recurringId)")
        } catch {
            AppLogger.data.error("Error deleting recurring transaction: \(error)")
        }
    }
}

@MainActor
@Observable class EditRecurringTransactionViewModel {
    var name: String = ""
    var amount: String = ""
    var selectedCategory: String = ""
    var selectedCategoryName: String {
        let lookup = CategoryResolver.makeLookup(from: customCategories)
        return CategoryResolver.resolveAll(selectedCategory, lookup: lookup).name
    }
    var transactionType: TransactionKind = .expense
    var frequency: RecurringFrequency = .monthly
    var startDate: Date = Date()
    var hasEndDate: Bool = false
    var endDate: Date = Date()
    var dayOfMonth: Int = 1
    var daysOfWeek: [Int] = []
    var notes: String = ""
    var showCategoryPicker = false
    var showError = false
    var errorMessage = ""
    var frequencyError: String? = nil

    var customCategories: [Category] = []

    private var originalFrequency: RecurringFrequency = .monthly

    let frequencies = RecurringFrequency.allCases

    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard !selectedCategory.isEmpty else { return false }
        return frequencyValidationError == nil
    }

    var frequencyValidationError: String? {
        guard frequency != originalFrequency else { return nil }
        switch frequency {
        case .weekly where daysOfWeek.isEmpty:
            return "Please select at least one day of the week."
        case .monthly where dayOfMonth < 1:
            return "Please select a day of the month."
        default:
            return nil
        }
    }

    func load(from recurring: RecurringTransaction, categories: [Category] = []) {
        name = recurring.name
        amount = recurring.amount.editableString
        selectedCategory = recurring.category
        transactionType = recurring.type
        frequency = recurring.frequency
        originalFrequency = recurring.frequency
        startDate = recurring.startDate
        hasEndDate = recurring.endDate != nil
        endDate = recurring.endDate ?? Date()
        dayOfMonth = recurring.dayOfMonth ?? 1
        daysOfWeek = recurring.daysOfWeek ?? []
        notes = recurring.notes ?? ""
        customCategories = categories
        frequencyError = nil
    }

    func validateFrequency() {
        frequencyError = frequencyValidationError
    }

    func apply(to recurring: RecurringTransaction, categories: [Category] = []) -> Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            showError = true
            return false
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a name"
            showError = true
            return false
        }
        guard !selectedCategory.isEmpty else {
            errorMessage = "Please select a category"
            showError = true
            return false
        }
        if let freqErr = frequencyValidationError {
            errorMessage = freqErr
            showError = true
            return false
        }

        recurring.name = trimmed
        recurring.amount = amountValue
        recurring.category = selectedCategory
        recurring.categoryId = categories.first(where: { $0.key == selectedCategory })?.id
        recurring.type = transactionType
        recurring.frequency = frequency
        recurring.startDate = startDate
        recurring.dayOfMonth = frequency == .monthly ? dayOfMonth : nil
        recurring.daysOfWeek = frequency == .weekly ? (daysOfWeek.isEmpty ? nil : daysOfWeek) : nil
        recurring.endDate = hasEndDate ? endDate : nil
        recurring.notes = notes.isEmpty ? nil : notes
        recurring.updatedAt = Date()
        return true
    }
}

@MainActor
@Observable class AddRecurringTransactionViewModel {
    var name: String = ""
    var amount: String = ""
    var selectedCategory: String = ""
    var selectedCategoryName: String {
        let lookup = CategoryResolver.makeLookup(from: customCategories)
        return CategoryResolver.resolveAll(selectedCategory, lookup: lookup).name
    }
    var transactionType: TransactionKind = .expense
    var frequency: RecurringFrequency = .monthly
    var startDate: Date = Date()
    var hasEndDate: Bool = false
    var endDate: Date = Date()
    var dayOfMonth: Int = 1
    var notes: String = ""
    var showCategoryPicker = false
    var showError = false
    var errorMessage = ""

    let frequencies = RecurringFrequency.allCases

    var customCategories: [Category] = []
    @ObservationIgnored var persistence: PersistenceService

    init(persistence: PersistenceService = .testing) {
        self.persistence = persistence
    }

    var modelContext: ModelContext { persistence.modelContext }

    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedCategory.isEmpty
    }

    func prefill(amount: String, category: String, type: TransactionKind = .expense) {
        self.amount = amount
        self.selectedCategory = category
        self.transactionType = type
    }

    func save() -> Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            showError = true
            return false
        }

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a name"
            showError = true
            return false
        }

        guard !selectedCategory.isEmpty else {
            errorMessage = "Please select a category"
            showError = true
            return false
        }

        let modelContext = modelContext

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let resolvedCategoryId = customCategories.first(where: { $0.key == selectedCategory })?.id

        let recurringTransaction = RecurringTransaction(
            name: trimmedName,
            amount: amountValue,
            category: selectedCategory,
            frequency: frequency,
            dayOfMonth: frequency == .monthly ? dayOfMonth : nil,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            notes: notes.isEmpty ? nil : notes,
            categoryId: resolvedCategoryId,
            type: transactionType
        )

        modelContext.insert(recurringTransaction)

        do {
            try persistence.save(recurringTransaction, action: .create)
            AppLogger.data.info("Recurring transaction saved: \(recurringTransaction.id)")
        } catch {
            AppLogger.data.error("Failed to save recurring transaction: \(error)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
            return false
        }

        return true
    }
}
