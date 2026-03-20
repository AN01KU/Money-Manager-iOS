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
    private var modelContext: ModelContext?
    
    func configure(allExpenses: [Expense], budgets: [MonthlyBudget], customCategories: [CustomCategory], modelContext: ModelContext?) {
        self.allExpenses = allExpenses
        self.budgets = budgets
        self.customCategories = customCategories
        self.modelContext = modelContext
        
        recalculate()
    }
    
    func recalculate() {
        let calendar = Calendar.current
        
        let dateFiltered: [Expense]
        if filterMode == .daily {
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
            
            dateFiltered = allExpenses.filter { expense in
                !expense.isDeleted &&
                expense.date >= startOfDay &&
                expense.date <= endOfDay
            }
        } else {
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            
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
            let range = calendar.range(of: .day, in: .month, for: selectedDate)!
            let daysInMonth = range.count
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
        
        do {
            try modelContext?.save()
            recalculate()
        } catch {
            print("Error deleting expense: \(error)")
        }
        expenseToDelete = nil
    }
    
    func cancelDeleteExpense() {
        expenseToDelete = nil
    }
    
    func resolveCategory(_ categoryName: String) -> (icon: String, color: Color) {
        if let custom = customCategories.first(where: { $0.name == categoryName && !$0.isHidden }) {
            return (custom.icon, Color(hex: custom.color))
        }
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == categoryName }) {
            return (predefined.icon, predefined.color)
        }
        return ("ellipsis.circle.fill", Color(hex: "#95A5A6"))
    }
}
