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
    var currentBudget: MonthlyBudget?
    var dailyBudgetLimit: Double = 0
    var totalSpent: Double = 0
    var totalIncome: Double = 0
    var categorySpending: [CategorySpending] = []
    var transactionToDelete: Transaction?

    var netBalance: Double { totalIncome - totalSpent }

    private var allTransactions: [Transaction] = []
    private var budgets: [MonthlyBudget] = []
    private var customCategories: [CustomCategory] = []
    private var categoryLookup: [String: CustomCategory] = [:]
    var modelContext: ModelContext? {
        get { persistence.modelContext }
        set { persistence.modelContext = newValue }
    }
    let persistence: PersistenceService

    init(persistence: PersistenceService = PersistenceService()) {
        self.persistence = persistence
    }

    func update(allTransactions: [Transaction], budgets: [MonthlyBudget], customCategories: [CustomCategory]) {
        self.allTransactions = allTransactions
        self.budgets = budgets
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

        var result = dateFiltered

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

        // Compute totals before applying type filter (so budget card is always accurate)
        totalSpent = result.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        totalIncome = result.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }

        switch transactionTypeFilter {
        case .all:      break
        case .expenses: result = result.filter { $0.type == .expense }
        case .income:   result = result.filter { $0.type == .income }
        }

        filteredTransactions = result

        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        currentBudget = budgets.first { $0.year == year && $0.month == month }

        if filterMode == .daily, let budget = currentBudget {
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            dailyBudgetLimit = budget.limit / Double(daysInMonth)
        } else {
            dailyBudgetLimit = 0
        }

        // For the category chart: use income when that filter is active, otherwise expenses
        let categoryBase: [Transaction]
        let categoryTotal: Double
        if transactionTypeFilter == .income {
            categoryBase = result  // already income-only at this point
            categoryTotal = totalIncome
        } else {
            categoryBase = result.filter { $0.type == .expense }
            categoryTotal = totalSpent
        }

        let grouped = Dictionary(grouping: categoryBase, by: { $0.category })

        if categoryTotal > 0 {
            categorySpending = grouped.map { categoryKey, transactions in
                let amount = transactions.reduce(0) { $0 + $1.amount }
                let percentage = Int((amount / categoryTotal) * 100)
                let (name, icon, color) = CategoryResolver.resolveAll(categoryKey, lookup: categoryLookup)
                return CategorySpending(
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

        // Recent transactions: up to 8 from the filtered period, unaffected by type/search filters
        recentTransactions = Array(dateFiltered.prefix(8))
    }

    func ensureBudgetExists(defaultBudgetLimit: Double, modelContext: ModelContext) {
        guard currentBudget == nil, defaultBudgetLimit > 0 else { return }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let budget = MonthlyBudget(year: year, month: month, limit: defaultBudgetLimit)
        modelContext.insert(budget)
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
