import SwiftUI
import SwiftData

enum TransactionTypeFilter: String, CaseIterable {
    case all      = "All"
    case expenses = "Expenses"
    case income   = "Income"
}

@MainActor
@Observable class OverviewViewModel {
    var selectedView: ViewType = .daily
    var selectedDate: Date = Date() { didSet { if oldValue != selectedDate { recalculate() } } }
    var filterMode: FilterMode = .monthly { didSet { if oldValue != filterMode { recalculate() } } }
    var showAddTransaction = false
    var showBudgetSheet = false
    var searchText = "" { didSet { if oldValue != searchText { recalculate() } } }
    var selectedCategoryFilter: String? { didSet { if oldValue != selectedCategoryFilter { recalculate() } } }
    var transactionTypeFilter: TransactionTypeFilter = .all { didSet { if oldValue != transactionTypeFilter { recalculate() } } }

    var filteredTransactions: [Transaction] = []
    var recentTransactions: [Transaction] = []
    var currentBudget: UserBudget?
    var dailyBudgetLimit: Double = 0
    var totalSpent: Double = 0
    var totalIncome: Double = 0
    var categorySpending: [CategorySpending] = []
    var transactionToDelete: Transaction?

    var netBalance: Double { totalIncome - totalSpent }

    private var allTransactions: [Transaction] = []
    private var userBudget: UserBudget?
    private var customCategories: [Category] = []
    private var categoryLookup: [String: Category] = [:]
    var modelContext: ModelContext { persistence.modelContext }
    @ObservationIgnored var persistence: PersistenceService

    init(persistence: PersistenceService = .testing) {
        self.persistence = persistence
    }

    func update(allTransactions: [Transaction], userBudget: UserBudget?, customCategories: [Category]) {
        self.allTransactions = allTransactions
        self.userBudget = userBudget
        self.customCategories = customCategories
        self.categoryLookup = CategoryResolver.makeLookup(from: customCategories)
        recalculate()
    }

    func recalculate() {
        let calendar = Calendar.current
        let interval = filterMode == .daily
            ? calendar.dayInterval(for: selectedDate)
            : calendar.monthInterval(for: selectedDate)

        // date + isSoftDeleted filtering delegated to Spending.from
        let spending = Spending.from(transactions: allTransactions, in: interval)

        // Apply category drill-down. Totals and recent list use this scope —
        // before search/type filters, which are transient UI state.
        let categoryFiltered: [Transaction]
        if let categoryFilter = selectedCategoryFilter {
            categoryFiltered = spending.filtered.filter { $0.category == categoryFilter }
        } else {
            categoryFiltered = spending.filtered
        }

        // Totals reflect the date + category scope, not the search term or type filter.
        totalSpent  = categoryFiltered.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        totalIncome = categoryFiltered.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }

        // Recent list follows the category drill-down but ignores search and type filter.
        recentTransactions = Array(categoryFiltered.prefix(8))

        var result = categoryFiltered

        if !searchText.isEmpty {
            result = result.filter { $0.matches(searchText: searchText) }
        }

        switch transactionTypeFilter {
        case .all:      break
        case .expenses: result = result.filter { $0.type == .expense }
        case .income:   result = result.filter { $0.type == .income }
        }

        filteredTransactions = result

        currentBudget = userBudget?.limit != nil ? userBudget : nil

        if filterMode == .daily, let budget = currentBudget, let limit = budget.limit {
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            dailyBudgetLimit = limit / Double(daysInMonth)
        } else {
            dailyBudgetLimit = 0
        }

        // Category chart: derive from categoryFiltered (before type/search filters) so the
        // chart base is always the full date + category scope, not a search-narrowed subset.
        let categoryBase: [Transaction]
        let categoryTotal: Double
        if transactionTypeFilter == .income {
            categoryBase = categoryFiltered.filter { $0.type == .income }
            categoryTotal = totalIncome
        } else {
            categoryBase = categoryFiltered.filter { $0.type == .expense }
            categoryTotal = totalSpent
        }

        let grouped = Dictionary(grouping: categoryBase, by: { $0.category })

        if categoryTotal > 0 {
            categorySpending = grouped.map { categoryKey, transactions in
                let amount = transactions.reduce(0) { $0 + $1.amount }
                let percentage = Int((amount / categoryTotal) * 100)
                let (name, icon, color) = CategoryResolver.resolveAll(categoryKey, lookup: categoryLookup)
                return CategorySpending(
                    categoryKey: categoryKey,
                    categoryName: name,
                    icon: icon,
                    color: color,
                    amount: amount,
                    percentage: percentage
                )
            }.sorted { $0.amount > $1.amount }
        } else {
            categorySpending = []
        }
    }

    func filterByCategory(_ categoryName: String) {
        selectedCategoryFilter = categoryName
        selectedView = .daily
    }

    func clearCategoryFilter() {
        selectedCategoryFilter = nil
        selectedView = .categories
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactionToDelete = transaction
    }

    func confirmDeleteTransaction() {
        guard let transaction = transactionToDelete else { return }

        transactionToDelete = nil

        do {
            try persistence.save(transaction, action: .delete)
        } catch {
            AppLogger.data.error("Error deleting transaction: \(error)")
        }

        recalculate()
    }

    func cancelDeleteTransaction() {
        transactionToDelete = nil
    }

    func resolveCategory(_ categoryName: String) -> (icon: String, color: Color) {
        CategoryResolver.resolve(categoryName, lookup: categoryLookup)
    }
}
