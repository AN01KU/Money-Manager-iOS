import SwiftUI
import SwiftData

@MainActor
@Observable class BudgetsViewModel {
    var selectedMonth: Date = Date()
    var showBudgetSheet = false

    var allTransactions: [Transaction] = []
    var budgets: [MonthlyBudget] = []
    var modelContext: ModelContext?

    var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        guard
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
        else { return [] }

        return allTransactions.filter { transaction in
            !transaction.isDeleted &&
            transaction.type == "expense" &&
            transaction.date >= startOfMonth &&
            transaction.date <= endOfMonth
        }
    }

    var currentBudget: MonthlyBudget? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        return budgets.first { $0.year == year && $0.month == month }
    }

    var totalSpent: Double {
        currentMonthTransactions.reduce(0) { $0 + $1.amount }
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

    var dailyAverage: Double {
        guard daysRemaining > 0 else { return 0 }
        return remainingBudget / Double(daysRemaining + 1)
    }

    func configure(allTransactions: [Transaction], budgets: [MonthlyBudget], modelContext: ModelContext?) {
        self.allTransactions = allTransactions
        self.budgets = budgets
        self.modelContext = modelContext
    }
}
