import SwiftUI
import SwiftData
import Combine

@MainActor
class BudgetsViewModel: ObservableObject {
    @Published var selectedMonth: Date = Date()
    @Published var showBudgetSheet = false
    
    var allExpenses: [Expense] = []
    var budgets: [MonthlyBudget] = []
    var modelContext: ModelContext?
    
    var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return allExpenses.filter { expense in
            !expense.isDeleted &&
            expense.date >= startOfMonth &&
            expense.date <= endOfMonth
        }
    }
    
    var currentBudget: MonthlyBudget? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        return budgets.first { $0.year == year && $0.month == month }
    }
    
    var totalSpent: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBudget: Double {
        guard let budget = currentBudget else { return 0 }
        return max(0, budget.limit - totalSpent)
    }
    
    var budgetPercentage: Int {
        guard let budget = currentBudget, budget.limit > 0 else { return 0 }
        return Int((totalSpent / budget.limit) * 100.0)
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!)!
        
        if calendar.isDate(today, equalTo: selectedMonth, toGranularity: .month) {
            let daysLeft = calendar.dateComponents([.day], from: today, to: endOfMonth).day ?? 0
            return max(0, daysLeft)
        }
        return 0
    }
    
    var dailyAverage: Double {
        guard daysRemaining > 0 else { return 0 }
        return remainingBudget / Double(daysRemaining + 1)
    }
    
    func configure(allExpenses: [Expense], budgets: [MonthlyBudget], modelContext: ModelContext?) {
        self.allExpenses = allExpenses
        self.budgets = budgets
        self.modelContext = modelContext
    }
}
