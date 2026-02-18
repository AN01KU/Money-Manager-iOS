import SwiftUI
import SwiftData
import Combine

@MainActor
class TransactionDetailViewModel: ObservableObject {
    @Published var showEditSheet = false
    @Published var showDeleteAlert = false
    @Published var selectedGroup: SplitGroup?
    
    let expense: Expense
    private var modelContext: ModelContext?
    
    var category: PredefinedCategory? {
        PredefinedCategory.allCases.first { $0.rawValue == expense.category }
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
        expense.isDeleted = true
        expense.updatedAt = Date()
        
        do {
            try modelContext?.save()
            completion()
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    func getGroupForNavigation() -> SplitGroup? {
        guard let groupId = expense.groupId, let groupName = expense.groupName else { return nil }
        return SplitGroup(
            id: groupId,
            name: groupName,
            createdBy: UUID(),
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
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
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: date)
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
