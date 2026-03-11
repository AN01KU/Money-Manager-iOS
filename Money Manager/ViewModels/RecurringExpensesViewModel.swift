import SwiftUI
import SwiftData
import Combine

@MainActor
class RecurringExpensesViewModel: ObservableObject {
    @Published var expenses: [RecurringExpense] = []
    @Published var showAddSheet = false
    @Published var editingExpense: RecurringExpense?
    
    var activeExpenses: [RecurringExpense] {
        expenses.filter { $0.isActive }
    }
    
    var pausedExpenses: [RecurringExpense] {
        expenses.filter { !$0.isActive }
    }
    
    var allRecurringExpenses: [RecurringExpense] {
        expenses
    }
    
    private var modelContext: ModelContext?
    
    func configure(expenses: [RecurringExpense], modelContext: ModelContext?) {
        self.expenses = expenses
        self.modelContext = modelContext
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
        try? modelContext?.save()
    }
}

@MainActor
class AddRecurringExpenseViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var amount: String = ""
    @Published var selectedCategory: String = ""
    @Published var frequency: String = "monthly"
    @Published var startDate: Date = Date()
    @Published var hasEndDate: Bool = false
    @Published var endDate: Date = Date()
    @Published var dayOfMonth: Int = 1
    @Published var notes: String = ""
    @Published var showCategoryPicker = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    let frequencies = ["daily", "weekly", "monthly", "yearly"]
    
    private var modelContext: ModelContext?
    
    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedCategory.isEmpty
    }
    
    func configure(modelContext: ModelContext?) {
        self.modelContext = modelContext
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
        
        let recurringExpense = RecurringExpense(
            name: trimmedName,
            amount: amountValue,
            category: selectedCategory,
            frequency: frequency,
            dayOfMonth: frequency == "monthly" ? dayOfMonth : nil,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(recurringExpense)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
            return false
        }
        
        return true
    }
}
