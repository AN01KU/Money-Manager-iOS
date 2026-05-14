import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Transaction> { !$0.isSoftDeleted }, sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var userBudgets: [UserBudget]

    @State private var viewModel = BudgetsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MonthSelector(selectedMonth: $viewModel.selectedMonth)
                    .padding(.horizontal)
                    .padding(.top)

                if let budget = viewModel.userBudget, budget.limit != nil {
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

                    if let limit = budget.limit {
                        BudgetStatusBanner(
                            spent: viewModel.totalSpent,
                            limit: limit,
                            percentage: viewModel.budgetPercentage
                        )
                        .padding(.horizontal)
                    }

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
        .onChange(of: BudgetsQuerySnapshot(transactions: allTransactions, userBudget: userBudgets.first), initial: true) {
            viewModel.configure(allTransactions: allTransactions, userBudget: userBudgets.first, modelContext: modelContext)
        }
    }
}

// MARK: - Helpers

private struct BudgetsQuerySnapshot: Equatable {
    let transactions: [Transaction]
    let userBudget: UserBudget?
}

#Preview {
    BudgetsView()
        .modelContainer(for: [Transaction.self, MonthlyBudget.self, UserBudget.self])
}
