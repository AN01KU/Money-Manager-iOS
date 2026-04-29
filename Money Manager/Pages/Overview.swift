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
        .onChange(of: queryData, initial: true) {
            viewModel.modelContext = modelContext
            viewModel.update(allTransactions: allTransactions, budgets: budgets, customCategories: customCategories)
        }
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
        .background(AppColors.background)
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
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBg)
                        .frame(width: 36, height: 36)
                    SyncStatusView()
                }
            }
        }
    }
}

// MARK: - Scroll Content

private struct OverviewScrollContent: View {
    @Bindable var viewModel: OverviewViewModel
    let onCategoryTapped: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacing20) {
            OverviewHeaderCard(viewModel: viewModel)
                .padding(.horizontal, AppConstants.UI.padding)
                .padding(.top, AppConstants.UI.spacingSM)

            if !viewModel.categorySpending.isEmpty {
                CategoryChart(categorySpending: viewModel.categorySpending) { categoryName in
                    onCategoryTapped?(categoryName)
                }
                .padding(.horizontal, AppConstants.UI.padding)
            } else {
                EmptyStateView(
                    icon: "chart.pie",
                    title: "No expenses yet",
                    message: "Tap + to add your first transaction"
                )
                .accessibilityIdentifier("overview.empty-state")
                .padding(.horizontal, AppConstants.UI.padding)
            }

            if !viewModel.recentTransactions.isEmpty {
                OverviewRecentTransactions(
                    transactions: viewModel.recentTransactions,
                    onGroupTapped: nil
                )
                .padding(.horizontal, AppConstants.UI.padding)
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
                    .accessibilityIdentifier("overview.date-filter-button")

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

                // Daily / Monthly mode selector
                HStack(spacing: 4) {
                    FilterModeChip(label: "Daily",   isSelected: viewModel.filterMode == .daily)   { withAnimation(.easeInOut(duration: 0.2)) { viewModel.filterMode = .daily } }
                    FilterModeChip(label: "Monthly", isSelected: viewModel.filterMode == .monthly) { withAnimation(.easeInOut(duration: 0.2)) { viewModel.filterMode = .monthly } }
                }
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
                .accessibilityIdentifier("overview.budget-card")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                Divider()
                    .padding(.horizontal, 16)

                Button {
                    viewModel.showBudgetSheet = true
                } label: {
                    HStack(spacing: 6) {
                        AppIcon(name: AppIcons.UI.add, size: 16, color: AppColors.accent)
                        Text("Set a budget")
                            .font(AppTypography.subhead)
                    }
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("overview.no-budget-card")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select \(viewModel.filterMode == .daily ? "Date" : "Month")",
                    selection: $viewModel.selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .navigationTitle("Select \(viewModel.filterMode == .daily ? "Date" : "Month")")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDatePicker = false }
                    }
                }
            }
            .presentationDetents([.height(300)])
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
                        AppIcon(name: AppIcons.UI.budget, size: 14, color: color)
                        Text("Budget")
                            .font(AppTypography.cardLabel)
                            .foregroundStyle(AppColors.label2)
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
                            .fill(AppColors.surface2)
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

// MARK: - Recent Transactions

private struct OverviewRecentTransactions: View {
    let transactions: [Transaction]
    let onGroupTapped: ((UUID) -> Void)?
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]

    private var categoryLookup: [String: CustomCategory] {
        CategoryResolver.makeLookup(from: customCategories)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text("RECENT")
                .font(AppTypography.footnote)
                .fontWeight(.semibold)
                .tracking(AppTypography.trackingFootnote)
                .foregroundStyle(AppColors.label2)
                .padding(.leading, AppConstants.UI.spacingXS)

            VStack(spacing: 0) {
                ForEach(Array(transactions.enumerated()), id: \.element.persistentModelID) { index, transaction in
                    TransactionRow(transaction: transaction, categoryLookup: categoryLookup, onGroupTapped: onGroupTapped)

                    if index < transactions.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        }
    }
}

// MARK: - Filter Mode Chip

private struct FilterModeChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(isSelected ? AppTypography.chipSelected : AppTypography.chip)
                .foregroundStyle(isSelected ? .white : AppColors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? AppColors.accent : AppColors.accentLight)
                .clipShape(Capsule())
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
