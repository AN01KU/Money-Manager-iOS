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

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }
    let persistence: PersistenceService

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
    }

    func update(recurring: [RecurringTransaction]) {
        self.recurring = recurring
    }

    func toggle(_ item: RecurringTransaction) {
        item.isActive.toggle()
        item.updatedAt = Date()
        do {
            try persistence.saveRecurring(item, action: "update")
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

        if let modelContext {
            let descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.recurringExpenseId == recurringId }
            )
            if let linked = try? modelContext.fetch(descriptor) {
                for tx in linked { tx.recurringExpenseId = nil }
            }
        }

        do {
            try persistence.saveAndSync(
                entityType: "recurring",
                entityID: recurringId,
                action: "delete",
                endpoint: "/recurring-transactions",
                httpMethod: "DELETE",
                payload: nil
            )
            AppLogger.data.info("Recurring transaction deleted: \(recurringId)")
        } catch {
            AppLogger.data.error("Error deleting recurring transaction: \(error)")
        }
    }
}

@MainActor
@Observable class AddRecurringTransactionViewModel {
    var name: String = ""
    var amount: String = ""
    var selectedCategory: String = ""
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

    var customCategories: [CustomCategory] = []
    let persistence: PersistenceService

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
    }

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }

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

        guard let modelContext = modelContext else { return true }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let resolvedCategoryId = customCategories.first(where: { $0.name == selectedCategory })?.id

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
            try persistence.saveRecurring(recurringTransaction, action: "create")
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
