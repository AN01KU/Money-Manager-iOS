import SwiftUI
import SwiftData

struct Overview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Transaction> { !$0.isSoftDeleted }, sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var budgets: [MonthlyBudget]
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    @AppStorage("defaultBudgetLimit") private var defaultBudgetLimit: Double = 0

    @State private var viewModel = OverviewViewModel()
    @State private var navigationPath: [AppRoute] = []
    var pendingRoute: Binding<AppRoute?>?
    var onCategoryTapped: ((String) -> Void)?

    private var queryData: QuerySnapshot {
        QuerySnapshot(transactions: allTransactions, budgets: budgets, categories: customCategories)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            OverviewBody(viewModel: viewModel, defaultBudgetLimit: defaultBudgetLimit, onCategoryTapped: onCategoryTapped)
                .navigationDestination(for: AppRoute.self) { route in
                    if case .transaction(let id) = route,
                       let transaction = allTransactions.first(where: { $0.id == id }) {
                        TransactionDetailView(transaction: transaction)
                    }
                }
        }
        .onChange(of: pendingRoute?.wrappedValue) { _, route in
            guard let route, case .transaction = route else { return }
            navigationPath = [route]
            pendingRoute?.wrappedValue = nil
        }
        .task {
            viewModel.modelContext = modelContext
            viewModel.update(allTransactions: allTransactions, budgets: budgets, customCategories: customCategories)
        }
        .onChange(of: queryData) { viewModel.update(allTransactions: allTransactions, budgets: budgets, customCategories: customCategories) }
    }
}

// MARK: - Body

private struct OverviewBody: View {
    @Bindable var viewModel: OverviewViewModel
    let defaultBudgetLimit: Double
    let onCategoryTapped: ((String) -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService

    var body: some View {
        ScrollView {
            OverviewScrollContent(viewModel: viewModel, onCategoryTapped: onCategoryTapped)
        }
        .navigationTitle("Overview")
        .toolbar { overviewToolbar }
        .sheet(isPresented: $viewModel.showBudgetSheet) {
            BudgetSheet(selectedMonth: viewModel.selectedDate)
        }
        .task(id: viewModel.selectedDate) {
            viewModel.ensureBudgetExists(defaultBudgetLimit: defaultBudgetLimit, modelContext: modelContext)
        }
    }

    @ToolbarContentBuilder
    private var overviewToolbar: some ToolbarContent {
        if authService.isAuthenticated {
            ToolbarItem(placement: .topBarTrailing) {
                SyncStatusView()
            }
        }
    }
}

// MARK: - Scroll Content

private struct OverviewScrollContent: View {
    @Bindable var viewModel: OverviewViewModel
    let onCategoryTapped: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OverviewHeaderCard(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.top, 8)

            if !viewModel.categorySpending.isEmpty {
                CategoryChart(categorySpending: viewModel.categorySpending) { categoryName in
                    onCategoryTapped?(categoryName)
                }
                .padding(.horizontal)
            } else {
                EmptyStateView(
                    icon: "chart.pie",
                    title: "No expenses yet",
                    message: "Tap + to add your first transaction"
                )
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 100)
    }
}

// MARK: - Header Card

private struct OverviewHeaderCard: View {
    @Bindable var viewModel: OverviewViewModel
    @State private var showDatePicker = false
    @State private var navTapped = 0

    private var budgetPercentage: Int {
        guard let budget = viewModel.currentBudget, budget.limit > 0 else { return 0 }
        return min(100, Int((viewModel.totalSpent / budget.limit) * 100))
    }

    private var budgetColor: Color {
        if budgetPercentage >= 100 { return AppColors.budgetDanger }
        if budgetPercentage >= 80 { return AppColors.budgetCaution }
        return AppColors.budgetSafe
    }

    var body: some View {
        VStack(spacing: 0) {
            // Period selector row
            HStack {
                HStack(spacing: 4) {
                    Button {
                        let step = viewModel.filterMode == .daily ? Calendar.Component.day : .month
                        if let prev = Calendar.current.date(byAdding: step, value: -1, to: viewModel.selectedDate) {
                            viewModel.selectedDate = prev
                            navTapped += 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(AppTypography.cardMeta)
                            .foregroundStyle(AppColors.accent)
                            .padding(6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showDatePicker = true
                    } label: {
                        Text(viewModel.selectedDate, format: viewModel.filterMode == .daily
                            ? .dateTime.day().month(.abbreviated).year()
                            : .dateTime.month(.wide).year())
                            .font(AppTypography.cardValue)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        let step = viewModel.filterMode == .daily ? Calendar.Component.day : .month
                        if let next = Calendar.current.date(byAdding: step, value: 1, to: viewModel.selectedDate) {
                            viewModel.selectedDate = next
                            navTapped += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(AppTypography.cardMeta)
                            .foregroundStyle(AppColors.accent)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
                .sensoryFeedback(.impact(weight: .light), trigger: navTapped)

                Spacer()

                // Daily / Monthly toggle pill
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.filterMode = viewModel.filterMode == .daily ? .monthly : .daily
                    }
                } label: {
                    Text(viewModel.filterMode == .daily ? "Daily" : "Monthly")
                        .font(AppTypography.chip)
                        .foregroundStyle(AppColors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColors.accentLight)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Income / Net / Expenses row
            HStack(spacing: 0) {
                SummaryStatView(
                    label: "Income",
                    amount: viewModel.totalIncome,
                    color: AppColors.positive,
                    alignment: .leading
                )

                Divider()
                    .frame(height: 40)

                SummaryStatView(
                    label: "Net",
                    amount: viewModel.netBalance,
                    color: viewModel.netBalance >= 0 ? AppColors.positive : AppColors.expense,
                    alignment: .center,
                    showSign: true
                )

                Divider()
                    .frame(height: 40)

                SummaryStatView(
                    label: "Expenses",
                    amount: viewModel.totalSpent,
                    color: AppColors.expense,
                    alignment: .trailing
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Budget bar — only when a budget exists
            if let budget = viewModel.currentBudget {
                Divider()
                    .padding(.horizontal, 16)

                BudgetInlineRow(
                    spent: viewModel.totalSpent,
                    limit: budget.limit,
                    percentage: budgetPercentage,
                    color: budgetColor,
                    onTap: { viewModel.showBudgetSheet = true }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                Divider()
                    .padding(.horizontal, 16)

                Button {
                    viewModel.showBudgetSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(AppTypography.infoLabel)
                        Text("Set a budget")
                            .font(AppTypography.infoLabel)
                    }
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.separator).opacity(0.4), lineWidth: 1)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select \(viewModel.filterMode == .daily ? "Date" : "Month")",
                    selection: $viewModel.selectedDate,
                    displayedComponents: viewModel.filterMode == .daily ? [.date] : [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Select \(viewModel.filterMode == .daily ? "Date" : "Month")")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDatePicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

}

private struct SummaryStatView: View {
    let label: String
    let amount: Double
    let color: Color
    let alignment: HorizontalAlignment
    var showSign: Bool = false

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(label)
                .font(AppTypography.cardLabel)
                .foregroundStyle(.secondary)
            Text(formattedAmount)
                .font(AppTypography.cardValue)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }

    private var formattedAmount: String {
        let formatted = CurrencyFormatter.format(abs(amount))
        if showSign {
            return amount >= 0 ? "+\(formatted)" : "-\(formatted)"
        }
        return formatted
    }
}

private struct BudgetInlineRow: View {
    let spent: Double
    let limit: Double
    let percentage: Int
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(AppTypography.cardMeta)
                            .foregroundStyle(color)
                        Text("Budget")
                            .font(AppTypography.cardLabel)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(CurrencyFormatter.format(spent)) / \(CurrencyFormatter.format(limit))")
                        .font(AppTypography.cardLabel)
                        .foregroundStyle(.secondary)
                    Text("· \(percentage)%")
                        .font(AppTypography.cardValue)
                        .foregroundStyle(color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 5)
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * min(1.0, Double(percentage) / 100.0), height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Query Snapshot

private struct QuerySnapshot: Equatable {
    let transactions: [Transaction]
    let budgets: [MonthlyBudget]
    let categories: [CustomCategory]
}

// MARK: - Preview Helpers

@MainActor
private func previewContainer(
    transactions: [Transaction] = [],
    budgets: [MonthlyBudget] = []
) -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Transaction.self, MonthlyBudget.self, CustomCategory.self,
        configurations: config
    )
    let context = container.mainContext
    for transaction in transactions { context.insert(transaction) }
    for budget in budgets { context.insert(budget) }
    try? context.save()
    return container
}

#Preview("With Transactions & Budget") {
    let calendar = Calendar.current
    let today = Date()
    let year = calendar.component(.year, from: today)
    let month = calendar.component(.month, from: today)

    let transactions = [
        Transaction(amount: 450, category: "Food & Dining", date: today, transactionDescription: "Lunch at cafe"),
        Transaction(amount: 120, category: "Food & Dining", date: today, transactionDescription: "Morning coffee"),
        Transaction(type: .income, amount: 85000, category: "Salary", date: today, transactionDescription: "Monthly salary"),
        Transaction(amount: 2000, category: "Transport", date: calendar.date(byAdding: .day, value: -1, to: today)!, transactionDescription: "Fuel"),
        Transaction(amount: 1200, category: "Shopping", date: calendar.date(byAdding: .day, value: -2, to: today)!, transactionDescription: "New shirt"),
        Transaction(amount: 999, category: "Utilities", date: calendar.date(byAdding: .day, value: -5, to: today)!, transactionDescription: "Phone bill"),
        Transaction(amount: 649, category: "Entertainment", date: calendar.date(byAdding: .day, value: -3, to: today)!, transactionDescription: "Netflix"),
    ]
    let budget = MonthlyBudget(year: year, month: month, limit: 50000)

    Overview()
        .modelContainer(previewContainer(transactions: transactions, budgets: [budget]))
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

    let transactions = [
        Transaction(amount: 15000, category: "Travel", date: today, transactionDescription: "Flight tickets"),
        Transaction(amount: 8000, category: "Shopping", date: calendar.date(byAdding: .day, value: -1, to: today)!, transactionDescription: "Electronics"),
        Transaction(amount: 5000, category: "Food & Dining", date: calendar.date(byAdding: .day, value: -2, to: today)!, transactionDescription: "Party dinner"),
        Transaction(amount: 3000, category: "Entertainment", date: calendar.date(byAdding: .day, value: -3, to: today)!, transactionDescription: "Concert tickets"),
    ]
    let budget = MonthlyBudget(year: year, month: month, limit: 10000)

    Overview()
        .modelContainer(previewContainer(transactions: transactions, budgets: [budget]))
}

#Preview("No Budget Set") {
    let today = Date()
    let transactions = [
        Transaction(amount: 350, category: "Food & Dining", date: today, transactionDescription: "Dinner"),
        Transaction(amount: 80, category: "Transport", date: today, transactionDescription: "Auto ride"),
    ]

    Overview()
        .modelContainer(previewContainer(transactions: transactions))
}
