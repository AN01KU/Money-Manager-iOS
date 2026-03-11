import SwiftUI
import SwiftData
import Combine

enum AddExpenseMode {
    case personal(editing: Expense? = nil)
}

@MainActor
class AddExpenseViewModel: ObservableObject {
    @Published var amount = ""
    @Published var selectedCategory = ""
    @Published var description = ""
    @Published var notes = ""
    @Published var showCategoryPicker = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSaving = false
    
    @Published var selectedDate = Date()
    @Published var selectedTime = Date()
    @Published var hasTime = true
    @Published var showDatePicker = false
    @Published var showTimePicker = false
    
    let mode: AddExpenseMode
    private var modelContext: ModelContext?
    
    var navigationTitle: String {
        if case .personal(let editing) = mode {
            return editing != nil ? "Edit Expense" : "Add Expense"
        }
        return "Add Expense"
    }
    
    var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0,
              !selectedCategory.isEmpty else { return false }
        return true
    }
    
    init(mode: AddExpenseMode) {
        self.mode = mode
    }
    
    func configure(modelContext: ModelContext?) {
        self.modelContext = modelContext
        setup()
    }
    
    func setup() {
        if case .personal(let editing) = mode, let expense = editing {
            amount = String(format: "%.2f", expense.amount)
            selectedCategory = expense.category
            selectedDate = expense.date
            selectedTime = expense.time ?? Date()
            hasTime = expense.time != nil
            description = expense.expenseDescription ?? ""
            notes = expense.notes ?? ""
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func save(completion: @escaping () -> Void) {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Amount must be greater than 0"
            showError = true
            return
        }
        
        guard let modelContext = modelContext else { return }
        
        isSaving = true
        let calendar = Calendar.current
        var expenseDate = calendar.startOfDay(for: selectedDate)
        
        if hasTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            expenseDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                        minute: timeComponents.minute ?? 0,
                                        second: 0,
                                        of: selectedDate) ?? selectedDate
        }
        
        if case .personal(let existing) = mode, let existingExpense = existing {
            existingExpense.amount = amountValue
            existingExpense.category = selectedCategory
            existingExpense.date = expenseDate
            existingExpense.time = hasTime ? selectedTime : nil
            existingExpense.expenseDescription = description.isEmpty ? nil : description
            existingExpense.notes = notes.isEmpty ? nil : notes
            existingExpense.updatedAt = Date()
        } else {
            let expense = Expense(
                amount: amountValue,
                category: selectedCategory,
                date: expenseDate,
                time: hasTime ? selectedTime : nil,
                expenseDescription: description.isEmpty ? nil : description,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(expense)
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save expense"
            showError = true
            isSaving = false
            return
        }
        
        isSaving = false
        completion()
    }
}
