import SwiftUI
import SwiftData
import Combine

@MainActor
class OverviewViewModel: ObservableObject {
    @Published var selectedView: ViewType = .daily
    @Published var selectedDate: Date = Date() { didSet { recalculate() } }
    @Published var filterMode: FilterMode = .monthly { didSet { recalculate() } }
    @Published var showAddExpense = false
    @Published var showBudgetSheet = false
    @Published var searchText = "" { didSet { recalculate() } }
    
    @Published var filteredExpenses: [Expense] = []
    @Published var currentBudget: MonthlyBudget?
    @Published var dailyBudgetLimit: Double = 0
    @Published var totalSpent: Double = 0
    @Published var categorySpending: [CategorySpending] = []
    @Published var expenseToDelete: Expense?
    
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
        
        if searchText.isEmpty {
            filteredExpenses = dateFiltered
        } else {
            filteredExpenses = dateFiltered.filter { expense in
                expense.category.localizedCaseInsensitiveContains(searchText) ||
                (expense.expenseDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (expense.groupName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
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
    
    private func resolveCategory(_ categoryName: String) -> (icon: String, color: Color) {
        if let custom = customCategories.first(where: { $0.name == categoryName && !$0.isHidden }) {
            return (custom.icon, Color(hex: custom.color))
        }
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == categoryName }) {
            return (predefined.icon, predefined.color)
        }
        return ("ellipsis.circle.fill", Color(hex: "#95A5A6"))
    }
}
