import SwiftUI
import SwiftData

@MainActor
@Observable class TransactionsViewModel {
    var selectedDate: Date = Date() { didSet { recalculate() } }
    var searchText: String = "" { didSet { recalculate() } }
    var selectedCategoryFilter: UUID? { didSet { recalculate() } }
    var transactionTypeFilter: TransactionTypeFilter = .all { didSet { recalculate() } }
    var showAddTransaction = false
    var isConfirmingDelete = false

    var filteredTransactions: [Transaction] = []
    var transactionToDelete: Transaction?

    var selectedCategoryFilterName: String? {
        guard let id = selectedCategoryFilter else { return nil }
        return categoryLookup[id]?.name
    }

    var modelContext: ModelContext { persistence.modelContext }
    @ObservationIgnored var persistence: PersistenceService

    private var allTransactions: [Transaction] = []
    private var categoryLookup: [UUID: Category] = [:]

    init(persistence: PersistenceService = .testing) {
        self.persistence = persistence
    }

    func update(allTransactions: [Transaction], customCategories: [Category]) {
        self.allTransactions = allTransactions
        self.categoryLookup = CategoryResolver.makeLookup(from: customCategories)
        recalculate()
    }

    func recalculate() {
        let interval = Calendar.current.monthInterval(for: selectedDate)
        let spending = Spending.from(
            transactions: allTransactions,
            in: interval,
            search: searchText.isEmpty ? nil : searchText,
            categoryLookup: categoryLookup
        )

        var result = spending.filtered

        if let categoryFilter = selectedCategoryFilter {
            result = result.filter { $0.categoryId == categoryFilter }
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
        transactionToDelete = nil
        isConfirmingDelete = false
        do {
            try persistence.save(transaction, action: .delete)
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
