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

    /// Days elapsed so far in the selected month (1-based, capped to today if current month).
    private var daysElapsed: Int {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else { return 1 }
        if calendar.isDate(today, equalTo: selectedMonth, toGranularity: .month) {
            return max(1, (calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 0) + 1)
        }
        // Past month — use full month length
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)
        return range?.count ?? 30
    }

    /// Projected total spend at end of month based on current daily rate.
    var projectedMonthEnd: Double {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        let dailyRate = totalSpent / Double(daysElapsed)
        let daysLeft = daysInMonth - daysElapsed
        return totalSpent + (dailyRate * Double(daysLeft))
    }

    /// Human-readable spending insight for the current budget period.
    var spendingInsight: String? {
        guard let budget = currentBudget, budget.limit > 0 else { return nil }
        // Only show for current month
        guard Calendar.current.isDate(Date(), equalTo: selectedMonth, toGranularity: .month) else { return nil }
        guard daysElapsed > 1 else { return nil }

        let projected = projectedMonthEnd
        let overspend = projected - budget.limit

        if totalSpent >= budget.limit {
            return "You've exceeded your budget"
        } else if overspend > 0 {
            return "At this rate you'll overspend by \(CurrencyFormatter.format(overspend))"
        } else {
            return "On track — projected \(CurrencyFormatter.format(projected)) of \(CurrencyFormatter.format(budget.limit))"
        }
    }

    func configure(allTransactions: [Transaction], budgets: [MonthlyBudget], modelContext: ModelContext?) {
        self.allTransactions = allTransactions
        self.budgets = budgets
        self.modelContext = modelContext
    }
}
