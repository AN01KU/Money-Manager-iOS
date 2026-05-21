import SwiftUI
import SwiftData

@MainActor
@Observable class TransactionDetailViewModel {
    var showDeleteAlert = false


    let transaction: Transaction
    var modelContext: ModelContext { persistence.modelContext }
    var customCategories: [Category] = [] {
        didSet { categoryLookup = CategoryResolver.makeLookup(from: customCategories) }
    }
    private var categoryLookup: [String: Category] = [:]

    var categoryName: String { resolvedCategory.name }
    var categoryIcon: String { resolvedCategory.icon }
    var categoryColor: Color { resolvedCategory.color }

    private var resolvedCategory: (name: String, icon: String, color: Color) {
        CategoryResolver.resolveAll(transaction.category, lookup: categoryLookup)
    }

    var isGroupTransaction: Bool {
        transaction.groupTransactionId != nil
    }

    var isSettlementTransaction: Bool {
        transaction.settlementId != nil
    }

    @ObservationIgnored var persistence: PersistenceService

    init(transaction: Transaction, persistence: PersistenceService = .testing) {
        self.transaction = transaction
        self.persistence = persistence
    }

    func deleteTransaction(completion: @escaping () -> Void) {
        transaction.isSoftDeleted = true
        transaction.updatedAt = Date()

        do {
            try persistence.save(transaction, action: .delete)
            AppLogger.data.info("Transaction deleted: \(self.transaction.id)")
            completion()
        } catch {
            AppLogger.data.error("Error deleting transaction: \(error)")
        }
    }

    func formatAmount(_ amount: Double) -> String {
        // Route through Money so the displayed value uses the same Decimal-based formatting as
        // the editor's parse/format pipeline. We render without the currency symbol here because
        // the surrounding view supplies it separately.
        let money = Money(amount: Decimal(amount), currencyCode: CurrencyFormatter.currentCode)
        return money.editableString
    }

    func formatDateAndTime(_ date: Date, time: Date?) -> String {
        if let time = time {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            let combined = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                         minute: timeComponents.minute ?? 0,
                                         second: 0, of: date) ?? date
            return combined.formatted(date: .abbreviated, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    func formatFullDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
