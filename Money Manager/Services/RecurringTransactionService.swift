import Foundation
import SwiftData

struct RecurringTransactionService {
    static func generatePendingTransactions(context: ModelContext) {
        let descriptor = FetchDescriptor<RecurringTransaction>()
        guard let allRecurring = try? context.fetch(descriptor) else { return }

        let calendar = Calendar.current
        var generated = 0

        for recurring in allRecurring {
            guard !recurring.isSoftDeleted else { continue }
            guard recurring.isActive else { continue }
            guard let nextDate = recurring.nextOccurrence else { continue }

            if let lastAdded = recurring.lastAddedDate {
                let lastAddedDay = calendar.startOfDay(for: lastAdded)
                guard nextDate > lastAddedDay else { continue }
            }

            let transaction = Transaction(
                type: recurring.type,
                amount: recurring.amount,
                category: recurring.category,
                date: nextDate,
                transactionDescription: recurring.name,
                notes: recurring.notes,
                recurringExpenseId: recurring.id
            )
            context.insert(transaction)

            recurring.lastAddedDate = nextDate
            recurring.updatedAt = Date()
            generated += 1
        }

        if generated > 0 {
            do {
                try context.save()
                AppLogger.data.info("RecurringTransactionService: generated \(generated) transaction(s)")
            } catch {
                AppLogger.data.error("RecurringTransactionService: failed to save generated transactions: \(error)")
            }
        } else {
            AppLogger.data.debug("RecurringTransactionService: no pending recurring transactions to generate")
        }
    }
}
