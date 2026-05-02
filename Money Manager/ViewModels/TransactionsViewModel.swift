import SwiftUI
import SwiftData

@MainActor
@Observable class TransactionsViewModel {
    var selectedDate: Date = Date() { didSet { recalculate() } }
    var searchText: String = "" { didSet { recalculate() } }
    var selectedCategoryFilter: String? { didSet { recalculate() } }
    var transactionTypeFilter: TransactionTypeFilter = .all { didSet { recalculate() } }
    var showAddTransaction = false
    var isConfirmingDelete = false

    var filteredTransactions: [Transaction] = []
    var transactionToDelete: Transaction?

    var selectedCategoryFilterName: String? {
        guard let key = selectedCategoryFilter else { return nil }
        let lookup = CategoryResolver.makeLookup(from: customCategories)
        let (name, _, _) = CategoryResolver.resolveAll(key, lookup: lookup)
        return name
    }

    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }
    let persistence: PersistenceService

    private var allTransactions: [Transaction] = []
    private var customCategories: [CustomCategory] = []

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
    }

    func update(allTransactions: [Transaction], customCategories: [CustomCategory]) {
        self.allTransactions = allTransactions
        self.customCategories = customCategories
        recalculate()
    }

    func recalculate() {
        let calendar = Calendar.current
        guard
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
            let firstDayNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
        else {
            filteredTransactions = []
            return
        }

        var result = allTransactions.filter { transaction in
            !transaction.isSoftDeleted &&
            transaction.date >= startOfMonth &&
            transaction.date < firstDayNextMonth
        }

        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.category.localizedStandardContains(searchText) ||
                (transaction.transactionDescription?.localizedStandardContains(searchText) ?? false) ||
                (transaction.notes?.localizedStandardContains(searchText) ?? false)
            }
        }

        if let categoryFilter = selectedCategoryFilter {
            result = result.filter { $0.category == categoryFilter }
        }

        switch transactionTypeFilter {
        case .all:      break
        case .expenses: result = result.filter { $0.type == .expense }
        case .income:   result = result.filter { $0.type == .income }
        }

        filteredTransactions = result
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactionToDelete = transaction
        isConfirmingDelete = true
    }

    func confirmDeleteTransaction() {
        guard let transaction = transactionToDelete else { return }
        transaction.isSoftDeleted = true
        transaction.updatedAt = Date()
        transactionToDelete = nil
        isConfirmingDelete = false
        do {
            try persistence.saveTransaction(transaction, action: "delete")
        } catch {
            AppLogger.data.error("Error deleting transaction: \(error)")
        }
        recalculate()
    }

    func cancelDeleteTransaction() {
        transactionToDelete = nil
        isConfirmingDelete = false
    }
}
