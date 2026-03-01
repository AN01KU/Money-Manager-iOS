import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    
    @StateObject private var viewModel = BudgetsViewModel()
    @State private var lastBudgetUpdate: Date = Date.distantPast
    
    private var latestBudgetUpdate: Date {
        budgets.map(\.updatedAt).max() ?? Date.distantPast
    }
    
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
            lastBudgetUpdate = latestBudgetUpdate
            viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
        }
        .onChange(of: allExpenses.count) { _, _ in
            viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
        }
        .onChange(of: budgets.count) { _, _ in
            lastBudgetUpdate = latestBudgetUpdate
            viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
        }
        .onChange(of: latestBudgetUpdate) { _, newUpdate in
            if newUpdate > lastBudgetUpdate {
                lastBudgetUpdate = newUpdate
                viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.selectedMonth) { _, _ in
            viewModel.configure(allExpenses: allExpenses, budgets: budgets, modelContext: modelContext)
        }
    }
}


#Preview {
    BudgetsView()
        .modelContainer(for: [Expense.self, MonthlyBudget.self])
}
