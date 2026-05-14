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
    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }
    let persistence: PersistenceService

    init(persistence: PersistenceService = PersistenceService()) {
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

        let dateFiltered: [Transaction]
        if filterMode == .daily {
            let startOfDay = calendar.startOfDay(for: selectedDate)
            guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
                filteredTransactions = []
                return
            }

            dateFiltered = allTransactions.filter { transaction in
                !transaction.isSoftDeleted &&
                transaction.date >= startOfDay &&
                transaction.date <= endOfDay
            }
        } else {
            guard
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
                let firstDayNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
            else {
                filteredTransactions = []
                return
            }

            dateFiltered = allTransactions.filter { transaction in
                !transaction.isSoftDeleted &&
                transaction.date >= startOfMonth &&
                transaction.date < firstDayNextMonth
            }
        }

        // Apply category filter. Totals and recent list are computed at this scope —
        // after category drill-down but before search/type filters, which are transient UI state.
        let categoryFiltered: [Transaction]
        if let categoryFilter = selectedCategoryFilter {
            categoryFiltered = dateFiltered.filter { $0.category == categoryFilter }
        } else {
            categoryFiltered = dateFiltered
        }

        // Totals reflect the month + category scope, not the search term.
        totalSpent  = categoryFiltered.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        totalIncome = categoryFiltered.filter { $0.type == .income  }.reduce(0) { $0 + $1.amount }

        // Recent list follows the category drill-down but ignores search and type filter.
        recentTransactions = Array(categoryFiltered.prefix(8))

        var result = categoryFiltered

        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.category.localizedStandardContains(searchText) ||
                (transaction.transactionDescription?.localizedStandardContains(searchText) ?? false) ||
                (transaction.notes?.localizedStandardContains(searchText) ?? false)
            }
        }

        switch transactionTypeFilter {
        case .all:      break
        case .expenses: result = result.filter { $0.type == .expense }
        case .income:   result = result.filter { $0.type == .income }
        }

        filteredTransactions = result

        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        currentBudget = userBudget?.limit != nil ? userBudget : nil

        if filterMode == .daily, let budget = currentBudget, let limit = budget.limit {
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            dailyBudgetLimit = limit / Double(daysInMonth)
        } else {
            dailyBudgetLimit = 0
        }

        // Category chart: derive from categoryFiltered (before type/search filters) so the
        // chart base is always the full month/category scope, not a search-narrowed subset.
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

    func ensureBudgetExists(defaultBudgetLimit: Double, modelContext: ModelContext) {
        guard currentBudget == nil, defaultBudgetLimit > 0 else { return }
        let existing = (try? modelContext.fetch(FetchDescriptor<UserBudget>()))?.first
        if let existing {
            existing.limit = defaultBudgetLimit
        } else {
            modelContext.insert(UserBudget(limit: defaultBudgetLimit))
        }
        try? modelContext.save()
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

        transaction.isSoftDeleted = true
        transaction.updatedAt = Date()
        transactionToDelete = nil

        do {
            try persistence.saveTransaction(transaction, action: "delete")
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
