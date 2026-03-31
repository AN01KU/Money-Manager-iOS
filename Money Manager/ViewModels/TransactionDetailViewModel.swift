import SwiftUI
import SwiftData

@MainActor
@Observable class TransactionDetailViewModel {
    var showEditSheet = false
    var showDeleteAlert = false

    let transaction: Transaction
    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }
    var customCategories: [CustomCategory] = []

    var categoryIcon: String {
        CategoryResolver.resolve(transaction.category, customCategories: customCategories).icon
    }

    var categoryColor: Color {
        CategoryResolver.resolve(transaction.category, customCategories: customCategories).color
    }

    var isGroupTransaction: Bool {
        transaction.groupTransactionId != nil
    }

    var isSettlementTransaction: Bool {
        transaction.settlementId != nil
    }

    let persistence: PersistenceService

    init(transaction: Transaction, persistence: PersistenceService = PersistenceService()) {
        self.transaction = transaction
        self.persistence = persistence
    }

    func deleteTransaction(completion: @escaping () -> Void) {
        transaction.isDeleted = true
        transaction.updatedAt = Date()

        guard persistence.modelContext != nil else {
            completion()
            return
        }

        do {
            try persistence.saveTransaction(transaction, action: "delete")
            AppLogger.data.info("Transaction deleted: \(self.transaction.id)")
            completion()
        } catch {
            AppLogger.data.error("Error deleting transaction: \(error)")
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
