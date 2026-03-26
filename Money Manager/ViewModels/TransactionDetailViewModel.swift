import SwiftUI
import SwiftData

@MainActor
@Observable class TransactionDetailViewModel {
    var showEditSheet = false
    var showDeleteAlert = false
    
    let expense: Expense
    var modelContext: ModelContext?
    var customCategories: [CustomCategory] = []
    
    var categoryIcon: String {
        CategoryResolver.resolve(expense.category, customCategories: customCategories).icon
    }

    var categoryColor: Color {
        CategoryResolver.resolve(expense.category, customCategories: customCategories).color
    }
    
    var isGroupExpense: Bool {
        expense.groupId != nil && expense.groupName != nil
    }
    
    private let changeQueue: ChangeQueueManagerProtocol

    init(expense: Expense, changeQueue: ChangeQueueManagerProtocol = changeQueueManager) {
        self.expense = expense
        self.changeQueue = changeQueue
    }
    
    func deleteExpense(completion: @escaping () -> Void) {
        expense.isDeleted = true
        expense.updatedAt = Date()
        
        guard let modelContext = modelContext else {
            completion()
            return
        }
        
        do {
            try modelContext.save()
            
            changeQueue.enqueue(
                entityType: "expense",
                entityID: expense.id,
                action: "delete",
                endpoint: "/expenses",
                httpMethod: "DELETE",
                payload: nil,
                context: modelContext
            )
            
            if NetworkMonitor.shared.isConnected {
                Task {
                    await changeQueue.replayAll(context: modelContext)
                }
            }
            
            completion()
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    func formatAmount(_ amount: Double) -> String {
        amount.formatted(.number.precision(.fractionLength(0...2)))
    }
    
    func formatDateAndTime(_ date: Date, time: Date?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if let time = time {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            let combined = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                         minute: timeComponents.minute ?? 0,
                                         second: 0, of: date) ?? date
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: combined)
        } else {
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
    }
    
    func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
