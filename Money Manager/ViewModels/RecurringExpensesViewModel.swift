import SwiftUI
import SwiftData
import Combine

@MainActor
class RecurringExpensesViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var showAddSheet = false
    
    var activeExpenses: [Expense] {
        expenses.filter { $0.isRecurring && $0.isActive }
    }
    
    private var modelContext: ModelContext?
    
    func configure(expenses: [Expense], modelContext: ModelContext?) {
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
        
        let expense = Expense(
            amount: amountValue,
            category: selectedCategory,
            date: startDate,
            expenseDescription: trimmedName,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: true,
            frequency: frequency,
            dayOfMonth: frequency == "monthly" ? dayOfMonth : nil,
            recurringEndDate: hasEndDate ? endDate : nil
        )
        
        modelContext.insert(expense)
        
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
