import SwiftUI
import SwiftData

enum AddExpenseMode {
    case personal(editing: Expense? = nil)
}

@MainActor
@Observable class AddExpenseViewModel {
    var amount = ""
    var selectedCategory = ""
    var description = ""
    var notes = ""
    var showCategoryPicker = false
    var showRecurringSheet = false
    var showError = false
    var errorMessage = ""
    var isSaving = false
    
    var selectedDate = Date()
    var selectedTime = Date()
    var hasTime = true
    
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
            amount = expense.amount.formatted(.number.precision(.fractionLength(2)))
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
            errorMessage = "Failed to parse amount"
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
        
        let expenseID: UUID
        let action: String
        let endpoint: String
        let httpMethod: String
        var payload: Data?
        
        if case .personal(let existing) = mode, let existingExpense = existing {
            existingExpense.amount = amountValue
            existingExpense.category = selectedCategory
            existingExpense.date = expenseDate
            existingExpense.time = hasTime ? selectedTime : nil
            existingExpense.expenseDescription = description.isEmpty ? nil : description
            existingExpense.notes = notes.isEmpty ? nil : notes
            existingExpense.updatedAt = Date()
            expenseID = existingExpense.id
            action = "update"
            endpoint = "/expenses"
            httpMethod = "PUT"
            payload = try? APIClient.apiEncoder.encode(existingExpense.toUpdateRequest())
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
            expenseID = expense.id
            action = "create"
            endpoint = "/expenses"
            httpMethod = "POST"
            payload = try? APIClient.apiEncoder.encode(expense.toCreateRequest())
        }
        
        do {
            try modelContext.save()
            
            changeQueueManager.enqueue(
                entityType: "expense",
                entityID: expenseID,
                action: action,
                endpoint: endpoint,
                httpMethod: httpMethod,
                payload: payload,
                context: modelContext
            )
            
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueueManager.replayAll(context: modelContext)
                }
            }
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
