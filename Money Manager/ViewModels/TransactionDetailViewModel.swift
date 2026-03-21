import SwiftUI
import SwiftData

@MainActor
@Observable class TransactionDetailViewModel {
    var showEditSheet = false
    var showDeleteAlert = false
    
    let expense: Expense
    private var modelContext: ModelContext?
    var customCategories: [CustomCategory] = []
    
    var categoryIcon: String {
        if let custom = customCategories.first(where: { $0.name == expense.category && !$0.isHidden }) {
            return custom.icon
        }
        return PredefinedCategory.allCases.first { $0.rawValue == expense.category }?.icon ?? "ellipsis.circle.fill"
    }
    
    var categoryColor: Color {
        if let custom = customCategories.first(where: { $0.name == expense.category && !$0.isHidden }) {
            return Color(hex: custom.color)
        }
        return PredefinedCategory.allCases.first { $0.rawValue == expense.category }?.color ?? .gray
    }
    
    var isGroupExpense: Bool {
        expense.groupId != nil && expense.groupName != nil
    }
    
    init(expense: Expense) {
        self.expense = expense
    }
    
    func configure(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }
    
    func deleteExpense(completion: @escaping () -> Void) {
        guard let modelContext = modelContext else {
            completion()
            return
        }
        
        expense.isDeleted = true
        expense.updatedAt = Date()
        
        do {
            try modelContext.save()
            
            ChangeQueueManager.shared.enqueue(
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
                    await ChangeQueueManager.shared.replayAll(context: modelContext)
                }
            }
            
            completion()
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
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
