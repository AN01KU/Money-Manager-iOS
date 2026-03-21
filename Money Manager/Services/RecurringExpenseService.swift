import Foundation
import SwiftData

struct RecurringExpenseService {
    static func generatePendingExpenses(context: ModelContext) {
        let descriptor = FetchDescriptor<RecurringExpense>()
        guard let recurringExpenses = try? context.fetch(descriptor) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for recurring in recurringExpenses {
            guard recurring.isActive else { continue }
            
            guard let nextDate = recurring.nextOccurrence else { continue }
            
            if let lastAdded = recurring.lastAddedDate {
                let lastAddedDay = calendar.startOfDay(for: lastAdded)
                guard nextDate > lastAddedDay else { continue }
            }
            
            let expense = Expense(
                amount: recurring.amount,
                category: recurring.category,
                date: nextDate,
                expenseDescription: recurring.name,
                notes: recurring.notes,
                recurringExpenseId: recurring.id
            )
            context.insert(expense)
            
            recurring.lastAddedDate = nextDate
            recurring.updatedAt = Date()
        }
        
        try? context.save()
    }
}
