import SwiftUI
import SwiftData

@MainActor
@Observable class RecurringExpensesViewModel {
    var expenses: [RecurringExpense] = []
    var showAddSheet = false
    var editingExpense: RecurringExpense?
    
    var activeExpenses: [RecurringExpense] {
        expenses.filter { $0.isActive }
    }
    
    var pausedExpenses: [RecurringExpense] {
        expenses.filter { !$0.isActive }
    }
    
    var allRecurringExpenses: [RecurringExpense] {
        expenses
    }
    
    var modelContext: ModelContext?
    private let changeQueue: ChangeQueueManagerProtocol
    private let auth: AuthServiceProtocol

    init(changeQueue: ChangeQueueManagerProtocol = changeQueueManager, auth: AuthServiceProtocol = authService) {
        self.changeQueue = changeQueue
        self.auth = auth
    }

    func update(expenses: [RecurringExpense]) {
        self.expenses = expenses
    }
    
    func deactivateExpense(at index: Int) {
        guard index < activeExpenses.count else { return }
        let expense = activeExpenses[index]
        expense.isActive = false
        expense.updatedAt = Date()
        try? modelContext?.save()
    }
    
    func toggleExpense(at index: Int) {
        guard index < allRecurringExpenses.count else { return }
        let expense = allRecurringExpenses[index]
        expense.isActive.toggle()
        expense.updatedAt = Date()
        
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            
            let payload = try? APIClient.apiEncoder.encode(expense.toUpdateRequest())
            changeQueue.enqueue(
                entityType: "recurring",
                entityID: expense.id,
                action: "update",
                endpoint: "/recurring-expenses",
                httpMethod: "PUT",
                payload: payload,
                context: modelContext
            )
            
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
            AppLogger.data.info("Recurring expense toggled: \(expense.id) isActive=\(expense.isActive)")
        } catch {
            AppLogger.data.error("Error toggling recurring expense: \(error)")
        }
    }
    
    func deleteExpense(at index: Int) {
        guard index < pausedExpenses.count, let modelContext = modelContext else { return }
        let recurring = pausedExpenses[index]
        let recurringId = recurring.id
        
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.recurringExpenseId == recurringId }
        )
        if let expenses = try? modelContext.fetch(descriptor) {
            for expense in expenses {
                expense.recurringExpenseId = nil
            }
        }
        
        modelContext.delete(recurring)
        
        do {
            try modelContext.save()
            
            changeQueue.enqueue(
                entityType: "recurring",
                entityID: recurringId,
                action: "delete",
                endpoint: "/recurring-expenses",
                httpMethod: "DELETE",
                payload: nil,
                context: modelContext
            )
            
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext, isAuthenticated: auth.isAuthenticated)
                }
            }
            AppLogger.data.info("Recurring expense deleted: \(recurringId)")
        } catch {
            AppLogger.data.error("Error deleting recurring expense: \(error)")
        }
    }
}

@MainActor
@Observable class AddRecurringExpenseViewModel {
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

        let recurringExpense = RecurringExpense(
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
        
        modelContext.insert(recurringExpense)
        
        do {
            try modelContext.save()
            AppLogger.data.info("Recurring expense saved: \(recurringExpense.id)")
            let payload = try? APIClient.apiEncoder.encode(recurringExpense.toCreateRequest())
            changeQueue.enqueue(
                entityType: "recurring",
                entityID: recurringExpense.id,
                action: "create",
                endpoint: "/recurring-expenses",
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
            AppLogger.data.error("Failed to save recurring expense: \(error)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
            return false
        }
        
        return true
    }
}
