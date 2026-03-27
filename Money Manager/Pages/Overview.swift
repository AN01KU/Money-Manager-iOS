import SwiftUI
import SwiftData

struct Overview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Transaction> { !$0.isDeleted }, sort: \Transaction.date, order: .reverse) private var allExpenses: [Transaction]
    @Query private var budgets: [MonthlyBudget]
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @AppStorage("defaultBudgetLimit") private var defaultBudgetLimit: Double = 0

    @State private var viewModel = OverviewViewModel()
    @State private var navigationPath: [AppRoute] = []
    var pendingRoute: Binding<AppRoute?>?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            OverviewBody(viewModel: viewModel, defaultBudgetLimit: defaultBudgetLimit)
                .navigationDestination(for: AppRoute.self) { route in
                    if case .expense(let id) = route,
                       let expense = allExpenses.first(where: { $0.id == id }) {
                        TransactionDetailView(expense: expense)
                    }
                }
        }
        .onChange(of: pendingRoute?.wrappedValue) { _, route in
            guard let route, case .expense = route else { return }
            navigationPath = [route]
            pendingRoute?.wrappedValue = nil
        }
        .task {
            viewModel.modelContext = modelContext
            viewModel.update(allExpenses: allExpenses, budgets: budgets, customCategories: customCategories)
        }
        .onChange(of: allExpenses) { _, newValue in
            viewModel.update(allExpenses: newValue, budgets: budgets, customCategories: customCategories)
        }
        .onChange(of: budgets) { _, newValue in
            viewModel.update(allExpenses: allExpenses, budgets: newValue, customCategories: customCategories)
        }
        .onChange(of: customCategories) { _, newValue in
            viewModel.update(allExpenses: allExpenses, budgets: budgets, customCategories: newValue)
        }
    }
}

// MARK: - Body (reduces type-checker complexity in Overview)

private struct OverviewBody: View {
    @Bindable var viewModel: OverviewViewModel
    let defaultBudgetLimit: Double
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                OverviewScrollContent(viewModel: viewModel)
            }
            FloatingActionButton(icon: "plus") {
                viewModel.showAddExpense = true
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Overview")
        .toolbar { overviewToolbar }
        .searchable(text: $viewModel.searchText, prompt: "Search expenses")
        .sheet(isPresented: $viewModel.showAddExpense) { AddTransactionView() }
        .sheet(isPresented: $viewModel.showBudgetSheet) {
            BudgetSheet(selectedMonth: viewModel.selectedDate)
        }
        .alert("Delete Expense?", isPresented: Binding(
            get: { viewModel.expenseToDelete != nil },
            set: { if !$0 { viewModel.cancelDeleteExpense() } }
        )) {
            Button("Cancel", role: .cancel) { viewModel.cancelDeleteExpense() }
            Button("Delete", role: .destructive) { viewModel.confirmDeleteExpense() }
        } message: {
            if let expense = viewModel.expenseToDelete {
                Text("Are you sure you want to delete \"\(expense.transactionDescription ?? expense.category)\"? This action cannot be undone.")
            }
        }
        .task(id: viewModel.selectedDate) {
            viewModel.ensureBudgetExists(defaultBudgetLimit: defaultBudgetLimit, modelContext: modelContext)
        }
    }

    @ToolbarContentBuilder
    private var overviewToolbar: some ToolbarContent {
        if authService.isAuthenticated {
            ToolbarItem(placement: .navigationBarTrailing) {
                SyncStatusView()
            }
        }
    }
}

// MARK: - Scroll Content

private struct OverviewScrollContent: View {
    @Bindable var viewModel: OverviewViewModel

    var body: some View {
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

            // Net balance strip — shown when there's any income
            if viewModel.totalIncome > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Income")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(viewModel.totalIncome))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.positive)
                    }
                    Spacer()
                    VStack(alignment: .center, spacing: 2) {
                        Text("Net")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(abs(viewModel.netBalance)))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(viewModel.netBalance >= 0 ? AppColors.positive : AppColors.expense)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Expenses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(viewModel.totalSpent))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.expense)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }

            ViewTypeSelector(selectedView: $viewModel.selectedView)
                .padding(.horizontal)

            // Type filter chips
            HStack(spacing: 8) {
                ForEach(TransactionTypeFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation { viewModel.transactionTypeFilter = filter }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(viewModel.transactionTypeFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(viewModel.transactionTypeFilter == filter ? AppColors.accent : Color(.systemGray5))
                            .foregroundStyle(viewModel.transactionTypeFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            if let categoryFilter = viewModel.selectedCategoryFilter {
                HStack(spacing: 8) {
                    Label(categoryFilter, systemImage: "line.3.horizontal.decrease.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Button {
                        withAnimation {
                            viewModel.clearCategoryFilter()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppColors.accentLight)
                .clipShape(Capsule())
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if viewModel.selectedView == .categories {
                if !viewModel.categorySpending.isEmpty {
                    CategoryChart(categorySpending: viewModel.categorySpending) { categoryName in
                        withAnimation {
                            viewModel.filterByCategory(categoryName)
                        }
                    }
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
                        title: viewModel.transactionTypeFilter == .income ? "No income yet" : "No transactions yet",
                        message: "Tap + to add your first \(viewModel.transactionTypeFilter == .income ? "income" : "expense")"
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
}

// MARK: - Preview Helpers

@MainActor
private func previewContainer(
    expenses: [Transaction] = [],
    budgets: [MonthlyBudget] = []
) -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Transaction.self, MonthlyBudget.self, CustomCategory.self,
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
        Transaction(amount: 450, category: "Food & Dining", date: today, transactionDescription: "Lunch at cafe"),
        Transaction(amount: 120, category: "Food & Dining", date: today, transactionDescription: "Morning coffee"),
        Transaction(amount: 2000, category: "Transport", date: calendar.date(byAdding: .day, value: -1, to: today)!, transactionDescription: "Fuel"),
        Transaction(amount: 1200, category: "Shopping", date: calendar.date(byAdding: .day, value: -2, to: today)!, transactionDescription: "New shirt"),
        Transaction(amount: 999, category: "Utilities", date: calendar.date(byAdding: .day, value: -5, to: today)!, transactionDescription: "Phone bill"),
        Transaction(amount: 649, category: "Entertainment", date: calendar.date(byAdding: .day, value: -3, to: today)!, transactionDescription: "Netflix"),
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
        Transaction(amount: 15000, category: "Travel", date: today, transactionDescription: "Flight tickets"),
        Transaction(amount: 8000, category: "Shopping", date: calendar.date(byAdding: .day, value: -1, to: today)!, transactionDescription: "Electronics"),
        Transaction(amount: 5000, category: "Food & Dining", date: calendar.date(byAdding: .day, value: -2, to: today)!, transactionDescription: "Party dinner"),
        Transaction(amount: 3000, category: "Entertainment", date: calendar.date(byAdding: .day, value: -3, to: today)!, transactionDescription: "Concert tickets"),
    ]
    let budget = MonthlyBudget(year: year, month: month, limit: 10000)

    Overview()
        .modelContainer(previewContainer(expenses: expenses, budgets: [budget]))
}

#Preview("No Budget Set") {
    let today = Date()
    let expenses = [
        Transaction(amount: 350, category: "Food & Dining", date: today, transactionDescription: "Dinner"),
        Transaction(amount: 80, category: "Transport", date: today, transactionDescription: "Auto ride"),
    ]

    Overview()
        .modelContainer(previewContainer(expenses: expenses))
}
