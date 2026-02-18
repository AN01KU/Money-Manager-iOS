import SwiftUI
import SwiftData
import Combine

@MainActor
class RecurringExpensesViewModel: ObservableObject {
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var showAddSheet = false
    
    var activeExpenses: [RecurringExpense] {
        recurringExpenses.filter { $0.isActive }
    }
    
    private var modelContext: ModelContext?
    
    func configure(recurringExpenses: [RecurringExpense], modelContext: ModelContext?) {
        self.recurringExpenses = recurringExpenses
        self.modelContext = modelContext
    }
    
    func deactivateExpense(at index: Int) {
        guard index < activeExpenses.count else { return }
        activeExpenses[index].isActive = false
        activeExpenses[index].updatedAt = Date()
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
        
        guard let modelContext = modelContext else { return false }
        
        let recurring = RecurringExpense(
            name: name.trimmingCharacters(in: .whitespaces),
            amount: amountValue,
            category: selectedCategory,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            dayOfMonth: frequency == "monthly" ? dayOfMonth : nil
        )
        recurring.notes = notes.isEmpty ? nil : notes
        
        modelContext.insert(recurring)
        
        do {
            try modelContext.save()
            return true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
}
