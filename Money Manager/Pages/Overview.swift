import SwiftUI
import SwiftData

struct Overview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    
    @AppStorage("defaultBudgetLimit") private var defaultBudgetLimit: Double = 0
    
    @State private var selectedView: ViewType = .daily
    @State private var selectedDate: Date = Date()
    @State private var filterMode: FilterMode = .monthly
    @State private var showAddExpense = false
    @State private var showBudgetSheet = false
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var showSearchBar = false
    @State private var testDataLoaded = false
    
    private var filteredExpenses: [Expense] {
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
        
        guard !searchText.isEmpty else { return dateFiltered }
        return dateFiltered.filter { expense in
            expense.category.localizedCaseInsensitiveContains(searchText) ||
            (expense.expenseDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (expense.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (expense.groupName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var currentBudget: MonthlyBudget? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        return budgets.first { $0.year == year && $0.month == month }
    }
    
    private var totalSpent: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var categorySpending: [CategorySpending] {
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        let total = totalSpent
        
        guard total > 0 else { return [] }
        
        return grouped.map { category, expenses in
            let amount = expenses.reduce(0) { $0 + $1.amount }
            let percentage = Int((amount / total) * 100)
            return CategorySpending(
                category: Category.fromString(category),
                amount: amount,
                percentage: percentage
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                        }
                        .frame(height: 0)
                        
                        DateFilterSelector(selectedDate: $selectedDate, filterMode: $filterMode)
                            .padding(.horizontal)
                        
                        if let budget = currentBudget {
                            BudgetOverviewCard(
                                budget: budget,
                                spent: totalSpent
                            )
                            .padding(.horizontal)
                        } else {
                            NoBudgetCard(selectedMonth: selectedDate) {
                                showBudgetSheet = true
                            }
                            .padding(.horizontal)
                        }
                        
                        ViewTypeSelector(selectedView: $selectedView)
                            .padding(.horizontal)
                        
                        if selectedView == .categories {
                            if !categorySpending.isEmpty {
                                CategoryChart(categorySpending: categorySpending)
                                    .padding(.horizontal)
                            } else {
                                EmptyStateView()
                                    .padding(.horizontal)
                            }
                        } else {
                            if filteredExpenses.isEmpty {
                                EmptyStateView()
                                    .padding(.horizontal)
                            } else {
                                TransactionList(expenses: filteredExpenses)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSearchBar = value < -30
                    }
                }
                
                FloatingActionButton(icon: "plus") {
                    showAddExpense = true
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showSearchBar {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search expenses", text: $searchText)
                                .textInputAutocapitalization(.never)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showBudgetSheet) {
                BudgetSheet(selectedMonth: selectedDate)
            }
            .task(id: selectedDate) {
                ensureBudgetExists()
            }
            .task {
                loadTestDataIfNeeded()
            }
        }
    }
    
    private func loadTestDataIfNeeded() {
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
    
    private func ensureBudgetExists() {
        guard currentBudget == nil, defaultBudgetLimit > 0 else { return }
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let budget = MonthlyBudget(year: year, month: month, limit: defaultBudgetLimit)
        modelContext.insert(budget)
        try? modelContext.save()
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview Helpers

private func previewContainer(
    expenses: [Expense] = [],
    budgets: [MonthlyBudget] = []
) -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Expense.self, MonthlyBudget.self, RecurringExpense.self, CustomCategory.self,
        configurations: config
    )
    let context = container.mainContext
    for expense in expenses { context.insert(expense) }
    for budget in budgets { context.insert(budget) }
    try? context.save()
    return container
}

#Preview("With Expenses & Budget") {
    let calendar = Calendar.current
    let today = Date()
    let year = calendar.component(.year, from: today)
    let month = calendar.component(.month, from: today)

    let expenses = [
        Expense(amount: 450, category: "Food & Dining", date: today, expenseDescription: "Lunch at cafe"),
        Expense(amount: 120, category: "Food & Dining", date: today, expenseDescription: "Morning coffee"),
        Expense(amount: 2000, category: "Transport", date: calendar.date(byAdding: .day, value: -1, to: today)!, expenseDescription: "Fuel"),
        Expense(amount: 1200, category: "Shopping", date: calendar.date(byAdding: .day, value: -2, to: today)!, expenseDescription: "New shirt"),
        Expense(amount: 999, category: "Utilities", date: calendar.date(byAdding: .day, value: -5, to: today)!, expenseDescription: "Phone bill"),
        Expense(amount: 649, category: "Entertainment", date: calendar.date(byAdding: .day, value: -3, to: today)!, expenseDescription: "Netflix"),
    ]
    let budget = MonthlyBudget(year: year, month: month, limit: 50000)

    Overview()
        .modelContainer(previewContainer(expenses: expenses, budgets: [budget]))
}

#Preview("Empty State") {
    Overview()
        .modelContainer(previewContainer())
}

#Preview("Over Budget") {
    let calendar = Calendar.current
    let today = Date()
    let year = calendar.component(.year, from: today)
    let month = calendar.component(.month, from: today)

    let expenses = [
        Expense(amount: 15000, category: "Travel", date: today, expenseDescription: "Flight tickets"),
        Expense(amount: 8000, category: "Shopping", date: calendar.date(byAdding: .day, value: -1, to: today)!, expenseDescription: "Electronics"),
        Expense(amount: 5000, category: "Food & Dining", date: calendar.date(byAdding: .day, value: -2, to: today)!, expenseDescription: "Party dinner"),
        Expense(amount: 3000, category: "Entertainment", date: calendar.date(byAdding: .day, value: -3, to: today)!, expenseDescription: "Concert tickets"),
    ]
    let budget = MonthlyBudget(year: year, month: month, limit: 10000)

    Overview()
        .modelContainer(previewContainer(expenses: expenses, budgets: [budget]))
}

#Preview("No Budget Set") {
    let today = Date()
    let expenses = [
        Expense(amount: 350, category: "Food & Dining", date: today, expenseDescription: "Dinner"),
        Expense(amount: 80, category: "Transport", date: today, expenseDescription: "Auto ride"),
    ]

    Overview()
        .modelContainer(previewContainer(expenses: expenses))
}
