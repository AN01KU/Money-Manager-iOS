import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Transaction> { !$0.isSoftDeleted }, sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var budgets: [MonthlyBudget]

    @State private var viewModel = BudgetsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MonthSelector(selectedMonth: $viewModel.selectedMonth)
                    .padding(.horizontal)
                    .padding(.top)

                if let budget = viewModel.currentBudget {
                    BudgetCard(
                        budget: budget,
                        spent: viewModel.totalSpent,
                        remaining: viewModel.remainingBudget,
                        percentage: viewModel.budgetPercentage,
                        daysRemaining: viewModel.daysRemaining,
                        dailyAverage: viewModel.dailyAverage,
                        onEdit: {
                            viewModel.showBudgetSheet = true
                        }
                    )
                    .padding(.horizontal)

                    BudgetStatusBanner(
                        spent: viewModel.totalSpent,
                        limit: budget.limit,
                        percentage: viewModel.budgetPercentage
                    )
                    .padding(.horizontal)

                    if let insight = viewModel.spendingInsight {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.insightIcon)
                                .foregroundStyle(viewModel.insightColor)
                            Text(insight)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                } else {
                    NoBudgetCard(
                        selectedMonth: viewModel.selectedMonth,
                        onSetBudget: {
                            viewModel.showBudgetSheet = true
                        }
                    )
                    .padding(.horizontal)
                }

                if !viewModel.currentMonthTransactions.isEmpty {
                    SpendingSummaryCard(
                        totalSpent: viewModel.totalSpent,
                        transactionCount: viewModel.currentMonthTransactions.count
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showBudgetSheet) {
            BudgetSheet(selectedMonth: viewModel.selectedMonth)
        }
        .onChange(of: BudgetsQuerySnapshot(transactions: allTransactions, budgets: budgets), initial: true) {
            viewModel.configure(allTransactions: allTransactions, budgets: budgets, modelContext: modelContext)
        }
    }
}

// MARK: - Helpers

private struct BudgetsQuerySnapshot: Equatable {
    let transactions: [Transaction]
    let budgets: [MonthlyBudget]
}

#Preview {
    BudgetsView()
        .modelContainer(for: [Transaction.self, MonthlyBudget.self])
}
