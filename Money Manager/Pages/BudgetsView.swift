import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    
    @StateObject private var viewModel = BudgetsViewModel()
    
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
                    
                } else {
                    NoBudgetCard(
                        selectedMonth: viewModel.selectedMonth,
                        onSetBudget: {
                            viewModel.showBudgetSheet = true
                        }
                    )
                    .padding(.horizontal)
                }
                
                if !viewModel.currentMonthExpenses.isEmpty {
                    SpendingSummaryCard(
                        totalSpent: viewModel.totalSpent,
                        transactionCount: viewModel.currentMonthExpenses.count
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


#Preview {
    BudgetsView()
        .modelContainer(for: [Expense.self, MonthlyBudget.self])
}
