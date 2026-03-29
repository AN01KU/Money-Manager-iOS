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

    /// Sum of amounts for all upcoming transactions this month.
    var upcomingTotalThisMonth: Double {
        upcomingThisMonth.reduce(0) { $0 + $1.amount }
    }

    var modelContext: ModelContext?
    private let changeQueue: ChangeQueueManagerProtocol
    private let auth: AuthServiceProtocol

    init(changeQueue: ChangeQueueManagerProtocol = changeQueueManager, auth: AuthServiceProtocol = authService) {
        self.changeQueue = changeQueue
        self.auth = auth
    }

    func update(recurring: [RecurringTransaction]) {
        self.recurring = recurring
    }

    func deactivate(at index: Int) {
        guard index < activeRecurring.count else { return }
        let item = activeRecurring[index]
        item.isActive = false
        item.updatedAt = Date()
        try? modelContext?.save()
    }

    func toggle(at index: Int) {
        guard index < allRecurring.count else { return }
        let item = allRecurring[index]
        item.isActive.toggle()
        item.updatedAt = Date()

        guard let modelContext = modelContext else { return }

        do {
            try modelContext.save()

            let payload = try? APIClient.apiEncoder.encode(item.toUpdateRequest())
            changeQueue.enqueue(
                entityType: "recurring",
                entityID: item.id,
                action: "update",
                endpoint: "/recurring-transactions",
                httpMethod: "PUT",
                payload: payload,
                context: modelContext
            )

            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
            AppLogger.data.info("Recurring transaction toggled: \(item.id) isActive=\(item.isActive)")
        } catch {
            AppLogger.data.error("Error toggling recurring transaction: \(error)")
        }
    }

    func delete(at index: Int) {
        guard index < pausedRecurring.count, let modelContext = modelContext else { return }
        let recurring = pausedRecurring[index]
        let recurringId = recurring.id

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.recurringExpenseId == recurringId }
        )
        if let linked = try? modelContext.fetch(descriptor) {
            for linked in linked {
                linked.recurringExpenseId = nil
            }
        }

        modelContext.delete(recurring)

        do {
            try modelContext.save()

            changeQueue.enqueue(
                entityType: "recurring",
                entityID: recurringId,
                action: "delete",
                endpoint: "/recurring-transactions",
                httpMethod: "DELETE",
                payload: nil,
                context: modelContext
            )

            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
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
    var frequency: String = "monthly"
    var startDate: Date = Date()
    var hasEndDate: Bool = false
    var endDate: Date = Date()
    var dayOfMonth: Int = 1
    var notes: String = ""
    var showCategoryPicker = false
    var showError = false
    var errorMessage = ""

    let frequencies = ["daily", "weekly", "monthly", "yearly"]

    var modelContext: ModelContext?
    var customCategories: [CustomCategory] = []
    private let changeQueue: ChangeQueueManagerProtocol
    private let auth: AuthServiceProtocol

    init(changeQueue: ChangeQueueManagerProtocol = changeQueueManager, auth: AuthServiceProtocol = authService) {
        self.changeQueue = changeQueue
        self.auth = auth
    }

    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedCategory.isEmpty
    }

    func prefill(amount: String, category: String) {
        self.amount = amount
        self.selectedCategory = category
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
            dayOfMonth: frequency == "monthly" ? dayOfMonth : nil,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            notes: notes.isEmpty ? nil : notes,
            categoryId: resolvedCategoryId
        )

        modelContext.insert(recurringTransaction)

        do {
            try modelContext.save()
            AppLogger.data.info("Recurring transaction saved: \(recurringTransaction.id)")
            let payload = try? APIClient.apiEncoder.encode(recurringTransaction.toCreateRequest())
            changeQueue.enqueue(
                entityType: "recurring",
                entityID: recurringTransaction.id,
                action: "create",
                endpoint: "/recurring-transactions",
                httpMethod: "POST",
                payload: payload,
                context: modelContext
            )

            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
        } catch {
            AppLogger.data.error("Failed to save recurring transaction: \(error)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
            return false
        }

        return true
    }
}
