import SwiftUI
import SwiftData

struct Overview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
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
                        
                        if let budget = viewModel.currentBudget {
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
                                EmptyStateView()
                                    .padding(.horizontal)
                            }
                        } else {
                            if viewModel.filteredExpenses.isEmpty {
                                EmptyStateView()
                                    .padding(.horizontal)
                            } else {
                                TransactionList(expenses: viewModel.filteredExpenses)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.filteredExpenses.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search expenses", text: $viewModel.searchText)
                                .textInputAutocapitalization(.never)
                                .accessibilityIdentifier("searchExpensesField")
                            
                            if !viewModel.searchText.isEmpty {
                                Button {
                                    viewModel.searchText = ""
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
            .sheet(isPresented: $viewModel.showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $viewModel.showBudgetSheet) {
                BudgetSheet(selectedMonth: viewModel.selectedDate)
            }
            .task(id: viewModel.selectedDate) {
                viewModel.ensureBudgetExists(defaultBudgetLimit: defaultBudgetLimit, modelContext: modelContext)
            }
            .task {
                viewModel.loadTestDataIfNeeded(modelContext: modelContext)
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
