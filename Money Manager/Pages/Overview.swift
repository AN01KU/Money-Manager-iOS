import SwiftUI
import SwiftData

struct Overview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Expense> { !$0.isDeleted }, sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    
    @AppStorage("defaultBudgetLimit") private var defaultBudgetLimit: Double = 0
    
    @StateObject private var viewModel = OverviewViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DateFilterSelector(selectedDate: $viewModel.selectedDate, filterMode: $viewModel.filterMode)
                            .padding(.horizontal)
                        
                        if viewModel.filterMode == .daily, viewModel.dailyBudgetLimit > 0 {
                            BudgetOverviewCard(
                                budget: MonthlyBudget(
                                    year: Calendar.current.component(.year, from: viewModel.selectedDate),
                                    month: Calendar.current.component(.month, from: viewModel.selectedDate),
                                    limit: viewModel.dailyBudgetLimit
                                ),
                                spent: viewModel.totalSpent,
                                isDaily: true
                            )
                            .padding(.horizontal)
                        } else if let budget = viewModel.currentBudget {
                            BudgetOverviewCard(
                                budget: budget,
                                spent: viewModel.totalSpent
                            )
                            .padding(.horizontal)
                        } else {
                            NoBudgetCard(selectedMonth: viewModel.selectedDate) {
                                viewModel.showBudgetSheet = true
                            }
                            .padding(.horizontal)
                        }
                        
                        ViewTypeSelector(selectedView: $viewModel.selectedView)
                            .padding(.horizontal)
                        
                        if viewModel.selectedView == .categories {
                            if !viewModel.categorySpending.isEmpty {
                                CategoryChart(categorySpending: viewModel.categorySpending)
                                    .padding(.horizontal)
                            } else {
                                EmptyStateView(
                                    icon: "chart.bar.doc.horizontal",
                                    title: "No expenses yet",
                                    message: "Tap + to add your first expense"
                                )
                                    .padding(.horizontal)
                            }
                        } else {
                            if viewModel.filteredExpenses.isEmpty {
                                EmptyStateView(
                                    icon: "chart.bar.doc.horizontal",
                                    title: "No expenses yet",
                                    message: "Tap + to add your first expense"
                                )
                                    .padding(.horizontal)
                            } else {
                                TransactionList(expenses: viewModel.filteredExpenses) { expense in
                                    viewModel.deleteExpense(expense)
                                }
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                FloatingActionButton(icon: "plus") {
                    viewModel.showAddExpense = true
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Overview")
            .searchable(text: $viewModel.searchText, prompt: "Search expenses")
            .sheet(isPresented: $viewModel.showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $viewModel.showBudgetSheet) {
                BudgetSheet(selectedMonth: viewModel.selectedDate)
            }
            .alert("Delete Expense?", isPresented: Binding(
                get: { viewModel.expenseToDelete != nil },
                set: { if !$0 { viewModel.cancelDeleteExpense() } }
            )) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDeleteExpense()
                }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDeleteExpense()
                }
            } message: {
                if let expense = viewModel.expenseToDelete {
                    Text("Are you sure you want to delete \"\(expense.expenseDescription ?? expense.category)\"? This action cannot be undone.")
                }
            }
            .task(id: viewModel.selectedDate) {
                viewModel.ensureBudgetExists(defaultBudgetLimit: defaultBudgetLimit, modelContext: modelContext)
            }
            .onAppear {
                viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
            }
            .onChange(of: allExpenses) { _, _ in
                viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
            }
            .onChange(of: budgets) { _, _ in
                viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.recalculate()
            }
            .onChange(of: viewModel.filterMode) { _, _ in
                viewModel.recalculate()
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                viewModel.recalculate()
            }
        }
    }
}

// MARK: - Preview Helpers

private func previewContainer(
    expenses: [Expense] = [],
    budgets: [MonthlyBudget] = []
) -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Expense.self, MonthlyBudget.self, CustomCategory.self,
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
