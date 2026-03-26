import SwiftUI
import SwiftData

@MainActor
@Observable class OverviewViewModel {
    var selectedView: ViewType = .daily
    var selectedDate: Date = Date() { didSet { recalculate() } }
    var filterMode: FilterMode = .monthly { didSet { recalculate() } }
    var showAddExpense = false
    var showBudgetSheet = false
    var searchText = "" { didSet { recalculate() } }
    var selectedCategoryFilter: String? { didSet { recalculate() } }
    
    var filteredExpenses: [Expense] = []
    var currentBudget: MonthlyBudget?
    var dailyBudgetLimit: Double = 0
    var totalSpent: Double = 0
    var categorySpending: [CategorySpending] = []
    var expenseToDelete: Expense?
    
    private var allExpenses: [Expense] = []
    private var budgets: [MonthlyBudget] = []
    private var customCategories: [CustomCategory] = []
    var modelContext: ModelContext?
    private let changeQueue: ChangeQueueManagerProtocol

    init(changeQueue: ChangeQueueManagerProtocol = changeQueueManager) {
        self.changeQueue = changeQueue
    }

    func update(allExpenses: [Expense], budgets: [MonthlyBudget], customCategories: [CustomCategory]) {
        self.allExpenses = allExpenses
        self.budgets = budgets
        self.customCategories = customCategories
        recalculate()
    }
    
    func recalculate() {
        let calendar = Calendar.current
        
        let dateFiltered: [Expense]
        if filterMode == .daily {
            let startOfDay = calendar.startOfDay(for: selectedDate)
            guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
                filteredExpenses = []
                return
            }

            dateFiltered = allExpenses.filter { expense in
                !expense.isDeleted &&
                expense.date >= startOfDay &&
                expense.date <= endOfDay
            }
        } else {
            guard
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
                let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
            else {
                filteredExpenses = []
                return
            }
            
            dateFiltered = allExpenses.filter { expense in
                !expense.isDeleted &&
                expense.date >= startOfMonth &&
                expense.date <= endOfMonth
            }
        }
        
        var result = dateFiltered
        
        if !searchText.isEmpty {
            result = result.filter { expense in
                expense.category.localizedStandardContains(searchText) ||
                (expense.expenseDescription?.localizedStandardContains(searchText) ?? false) ||
                (expense.notes?.localizedStandardContains(searchText) ?? false) ||
                (expense.groupName?.localizedStandardContains(searchText) ?? false)
            }
        }
        
        if let categoryFilter = selectedCategoryFilter {
            result = result.filter { $0.category == categoryFilter }
        }
        
        filteredExpenses = result
        
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        currentBudget = budgets.first { $0.year == year && $0.month == month }
        
        if filterMode == .daily, let budget = currentBudget {
            let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
            dailyBudgetLimit = budget.limit / Double(daysInMonth)
        } else {
            dailyBudgetLimit = 0
        }
        
        totalSpent = filteredExpenses.reduce(0) { $0 + $1.amount }
        
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        let total = totalSpent
        
        if total > 0 {
            categorySpending = grouped.map { categoryName, expenses in
                let amount = expenses.reduce(0) { $0 + $1.amount }
                let percentage = Int((amount / total) * 100)
                let (icon, color) = resolveCategory(categoryName)
                return CategorySpending(
                    categoryName: categoryName,
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
    
    func deleteExpense(_ expense: Expense) {
        expenseToDelete = expense
    }
    
    func confirmDeleteExpense() {
        guard let expense = expenseToDelete else { return }
        
        expense.isDeleted = true
        expense.updatedAt = Date()
        expenseToDelete = nil
        
        if let modelContext = modelContext {
            do {
                try modelContext.save()
                
                changeQueue.enqueue(
                    entityType: "expense",
                    entityID: expense.id,
                    action: "delete",
                    endpoint: "/expenses",
                    httpMethod: "DELETE",
                    payload: nil,
                    context: modelContext
                )
                
                if NetworkMonitor.shared.isConnected {
                    Task {
                        await changeQueue.replayAll(context: modelContext)
                    }
                }
            } catch {
                print("Error deleting expense: \(error)")
            }
        }
        
        recalculate()
    }
    
    func cancelDeleteExpense() {
        expenseToDelete = nil
    }
    
    func resolveCategory(_ categoryName: String) -> (icon: String, color: Color) {
        CategoryResolver.resolve(categoryName, customCategories: customCategories)
    }
}
