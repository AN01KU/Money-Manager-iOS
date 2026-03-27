import Foundation
import SwiftData

struct RecurringExpenseService {
    static func generatePendingExpenses(context: ModelContext) {
        let descriptor = FetchDescriptor<RecurringExpense>()
        guard let recurringExpenses = try? context.fetch(descriptor) else { return }

        let calendar = Calendar.current
        var generated = 0

        for recurring in recurringExpenses {
            guard recurring.isActive else { continue }
            guard let nextDate = recurring.nextOccurrence else { continue }

            if let lastAdded = recurring.lastAddedDate {
                let lastAddedDay = calendar.startOfDay(for: lastAdded)
                guard nextDate > lastAddedDay else { continue }
            }

            let expense = Transaction(
                amount: recurring.amount,
                category: recurring.category,
                date: nextDate,
                transactionDescription: recurring.name,
                notes: recurring.notes,
                recurringExpenseId: recurring.id
            )
            context.insert(expense)

            recurring.lastAddedDate = nextDate
            recurring.updatedAt = Date()
            generated += 1
        }

        if generated > 0 {
            do {
                try context.save()
                AppLogger.data.info("RecurringExpenseService: generated \(generated) expense(s)")
            } catch {
                AppLogger.data.error("RecurringExpenseService: failed to save generated expenses: \(error)")
            }
        } else {
            AppLogger.data.debug("RecurringExpenseService: no pending recurring expenses to generate")
        }
    }
}
