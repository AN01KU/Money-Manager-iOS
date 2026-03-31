import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Transaction> { !$0.isDeleted }, sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var budgets: [MonthlyBudget]
    
    @State private var selectedMonth: Date = Date()
    @State private var showBudgetSheet = false
    @State private var refreshTrigger = false
    
    private var currentBudget: MonthlyBudget? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        return budgets.first { $0.year == year && $0.month == month }
    }
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        guard
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
            let firstDayNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
        else { return [] }

        return allTransactions.filter { transaction in
            !transaction.isDeleted &&
            transaction.type == .expense &&
            transaction.date >= startOfMonth &&
            transaction.date < firstDayNextMonth
        }
    }

    private var totalSpent: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var remainingBudget: Double {
        guard let budget = currentBudget else { return 0 }
        return max(0, budget.limit - totalSpent)
    }
    
    private var budgetPercentage: Int {
        guard let budget = currentBudget, budget.limit > 0 else { return 0 }
        return Int((totalSpent / budget.limit) * 100.0)
    }
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        guard
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
        else { return 0 }

        if calendar.isDate(today, equalTo: selectedMonth, toGranularity: .month) {
            let daysLeft = calendar.dateComponents([.day], from: today, to: endOfMonth).day ?? 0
            return max(0, daysLeft)
        }
        return 0
    }
    
    private var dailyAverage: Double {
        guard daysRemaining > 0 else { return 0 }
        return remainingBudget / Double(daysRemaining + 1)
    }

    private var daysElapsed: Int {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else { return 1 }
        if calendar.isDate(today, equalTo: selectedMonth, toGranularity: .month) {
            return max(1, (calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 0) + 1)
        }
        return calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
    }

    private var projectedMonthEnd: Double {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        let dailyRate = totalSpent / Double(daysElapsed)
        return totalSpent + (dailyRate * Double(daysInMonth - daysElapsed))
    }

    private var spendingInsight: String? {
        guard let budget = currentBudget, budget.limit > 0 else { return nil }
        guard Calendar.current.isDate(Date(), equalTo: selectedMonth, toGranularity: .month) else { return nil }
        guard daysElapsed > 1 else { return nil }
        let overspend = projectedMonthEnd - budget.limit
        if totalSpent >= budget.limit {
            return "You've exceeded your budget"
        } else if overspend > 0 {
            return "At this rate you'll overspend by \(CurrencyFormatter.format(overspend))"
        } else {
            return "On track — projected \(CurrencyFormatter.format(projectedMonthEnd)) of \(CurrencyFormatter.format(budget.limit))"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MonthSelector(selectedMonth: $selectedMonth)
                    .padding(.horizontal)
                    .padding(.top)
                
                if let budget = currentBudget {
                    BudgetCard(
                        budget: budget,
                        spent: totalSpent,
                        remaining: remainingBudget,
                        percentage: budgetPercentage,
                        daysRemaining: daysRemaining,
                        dailyAverage: dailyAverage,
                        onEdit: {
                            showBudgetSheet = true
                        }
                    )
                    .padding(.horizontal)
                    
                    BudgetStatusBanner(
                        spent: totalSpent,
                        limit: budget.limit,
                        percentage: budgetPercentage
                    )
                    .padding(.horizontal)

                    if let insight = spendingInsight {
                        HStack(spacing: 8) {
                            Image(systemName: totalSpent >= budget.limit ? "exclamationmark.triangle.fill" : projectedMonthEnd > budget.limit ? "arrow.up.circle.fill" : "checkmark.circle.fill")
                                .foregroundStyle(totalSpent >= budget.limit ? AppColors.expense : projectedMonthEnd > budget.limit ? AppColors.budgetCaution : AppColors.positive)
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
                        selectedMonth: selectedMonth,
                        onSetBudget: {
                            showBudgetSheet = true
                        }
                    )
                    .padding(.horizontal)
                }
                
                if !currentMonthTransactions.isEmpty {
                    SpendingSummaryCard(
                        totalSpent: totalSpent,
                        transactionCount: currentMonthTransactions.count
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBudgetSheet) {
            BudgetSheet(selectedMonth: selectedMonth)
        }
        .onAppear {
            refreshTrigger.toggle()
        }
    }
}


#Preview {
    BudgetsView()
        .modelContainer(for: [Transaction.self, MonthlyBudget.self])
}
