//
//  BudgetsView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 25/12/25.
//

import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    
    @State private var selectedMonth: Date = Date()
    @State private var showBudgetSheet = false
    
    private var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return allExpenses.filter { expense in
            !expense.isDeleted &&
            expense.date >= startOfMonth &&
            expense.date <= endOfMonth
        }
    }
    
    private var currentBudget: MonthlyBudget? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        return budgets.first { $0.year == year && $0.month == month }
    }
    
    private var totalSpent: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
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
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!)!
        
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month Selector
                    MonthSelector(selectedMonth: $selectedMonth)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if let budget = currentBudget {
                        // Budget Overview Card
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
                        
                        // Status Banner
                        BudgetStatusBanner(
                            spent: totalSpent,
                            limit: budget.limit,
                            percentage: budgetPercentage
                        )
                        .padding(.horizontal)
                        
                    } else {
                        // No Budget Set
                        NoBudgetCard(
                            selectedMonth: selectedMonth,
                            onSetBudget: {
                                showBudgetSheet = true
                            }
                        )
                        .padding(.horizontal)
                    }
                    
                    // Spending Summary
                    if !currentMonthExpenses.isEmpty {
                        SpendingSummaryCard(
                            totalSpent: totalSpent,
                            transactionCount: currentMonthExpenses.count
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 100) // Space for tab bar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showBudgetSheet = true
                    }) {
                        Image(systemName: currentBudget == nil ? "plus" : "pencil")
                            .foregroundColor(.teal)
                    }
                }
            }
            .sheet(isPresented: $showBudgetSheet) {
                BudgetSheet(selectedMonth: selectedMonth)
            }
        }
    }
}


#Preview {
    BudgetsView()
        .modelContainer(for: [Expense.self, MonthlyBudget.self])
}
