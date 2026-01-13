//
//  Overview.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 25/12/25.
//

import SwiftUI
import SwiftData

struct Overview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var budgets: [MonthlyBudget]
    
    @State private var selectedView: ViewType = .daily
    @State private var selectedMonth: Date = Date()
    @State private var showAddExpense = false
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
    
    private var categorySpending: [CategorySpending] {
        let grouped = Dictionary(grouping: currentMonthExpenses, by: { $0.category })
        let total = totalSpent
        
        guard total > 0 else { return [] }
        
        return grouped.map { category, expenses in
            let amount = expenses.reduce(0) { $0 + $1.amount }
            let percentage = Int((amount / total) * 100)
            return CategorySpending(
                category: Category.fromString(category),
                amount: amount,
                percentage: percentage
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        MonthSelector(selectedMonth: $selectedMonth)
                            .padding(.horizontal)
                        
                        if let budget = currentBudget {
                            BudgetOverviewCard(
                                budget: budget,
                                spent: totalSpent
                            )
                            .padding(.horizontal)
                        } else {
                            NoBudgetCard(selectedMonth: selectedMonth) {
                                showBudgetSheet = true
                            }
                            .padding(.horizontal)
                        }
                        
                        ViewTypeSelector(selectedView: $selectedView)
                            .padding(.horizontal)
                        
                        if !categorySpending.isEmpty {
                            CategoryChart(categorySpending: categorySpending)
                                .padding(.horizontal)
                        }
                        
                        if currentMonthExpenses.isEmpty {
                            EmptyStateView()
                                .padding(.horizontal)
                        } else {
                            TransactionList(expenses: currentMonthExpenses)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                
                FloatingActionButton(icon: "plus") {
                    showAddExpense = true
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddExpense = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.teal)
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showBudgetSheet) {
                BudgetSheet(selectedMonth: selectedMonth)
            }
        }
    }
}

#Preview {
    Overview()
        .modelContainer(for: [Expense.self, MonthlyBudget.self])
}
