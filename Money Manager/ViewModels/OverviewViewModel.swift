import SwiftUI
import SwiftData
import Combine

@MainActor
class OverviewViewModel: ObservableObject {
    @Published var selectedView: ViewType = .daily
    @Published var selectedDate: Date = Date()
    @Published var filterMode: FilterMode = .monthly
    @Published var showAddExpense = false
    @Published var showBudgetSheet = false
    @Published var searchText = ""
    @Published var scrollOffset: CGFloat = 0
    @Published var showSearchBar = false
    @Published var testDataLoaded = false
    
    @Published var filteredExpenses: [Expense] = []
    @Published var currentBudget: MonthlyBudget?
    @Published var totalSpent: Double = 0
    @Published var categorySpending: [CategorySpending] = []
    
    private var allExpenses: [Expense] = []
    private var budgets: [MonthlyBudget] = []
    private var modelContext: ModelContext?
    
    func configure(allExpenses: [Expense], budgets: [MonthlyBudget], modelContext: ModelContext?) {
        self.allExpenses = allExpenses
        self.budgets = budgets
        self.modelContext = modelContext
        recalculate()
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        recalculate()
    }
    
    func updateFilterMode(_ mode: FilterMode) {
        filterMode = mode
        recalculate()
    }
    
    func updateSelectedDate(_ date: Date) {
        selectedDate = date
        recalculate()
    }
    
    func updateSelectedView(_ view: ViewType) {
        selectedView = view
    }
    
    func updateScrollOffset(_ offset: CGFloat) {
        scrollOffset = offset
        withAnimation(.easeInOut(duration: 0.2)) {
            showSearchBar = offset < -30
        }
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
        
        totalSpent = filteredExpenses.reduce(0) { $0 + $1.amount }
        
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        let total = totalSpent
        
        if total > 0 {
            categorySpending = grouped.map { category, expenses in
                let amount = expenses.reduce(0) { $0 + $1.amount }
                let percentage = Int((amount / total) * 100)
                return CategorySpending(
                    category: Category.fromString(category),
                    amount: amount,
                    percentage: percentage
                )
            }.sorted { $0.amount > $1.amount }
        } else {
            categorySpending = []
        }
    }
    
    func loadTestDataIfNeeded(modelContext: ModelContext) {
        guard !testDataLoaded, useTestData else { return }
        testDataLoaded = true
        
        try? modelContext.delete(model: Expense.self)
        try? modelContext.delete(model: MonthlyBudget.self)
        try? modelContext.delete(model: RecurringExpense.self)
        
        for expense in TestData.generatePersonalExpenses() {
            modelContext.insert(expense)
        }
        for expense in TestData.getGroupExpensesForOverview() {
            modelContext.insert(expense)
        }
        for budget in TestData.generateBudgets() {
            modelContext.insert(budget)
        }
        for recurring in TestData.generateRecurringExpenses() {
            modelContext.insert(recurring)
        }
        
        try? modelContext.save()
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
}
