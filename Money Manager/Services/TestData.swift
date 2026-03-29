import Foundation
import SwiftData

#if DEBUG
struct TestData {

    static func generatePersonalTransactions() -> [Transaction] {
        var expenses: [Transaction] = []
        let today = Date()
        let calendar = Calendar.current

        let todayExpenses = [
            ("Coffee", 120.0, "Food & Dining", "Morning coffee with colleague"),
            ("Lunch", 450.0, "Food & Dining", "Office lunch at new cafe"),
            ("Auto Ride", 80.0, "Transport", "Commute to meeting"),
        ]

        for (desc, amount, category, details) in todayExpenses {
            let expense = Transaction(
                amount: amount,
                category: category,
                date: today,
                transactionDescription: details
            )
            expenses.append(expense)
        }

        for i in 1...6 {
            guard let expenseDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }

            let weekExpenses: [(String, Double, String, String)] = [
                ("Dinner", 350, "Food & Dining", "Restaurant with friends"),
                ("Gas", 2000, "Transport", "Fuel for car"),
                ("Clothing", 1200, "Shopping", "New shirt and pants"),
                ("Movie", 250, "Entertainment", "Cinema ticket"),
                ("Books", 450, "Books & Media", "Programming books"),
                ("Gym", 500, "Health & Medical", "Monthly gym membership"),
            ]

            if i - 1 < weekExpenses.count {
                let (desc, amount, category, details) = weekExpenses[i - 1]
                let expense = Transaction(
                    amount: amount,
                    category: category,
                    date: expenseDate,
                    transactionDescription: details
                )
                expenses.append(expense)
            }
        }

        let monthExpenses: [(Double, String, String, String)] = [
            (999, "Phone Bill", "Utilities", "Monthly mobile plan"),
            (1500, "Electricity", "Housing", "Monthly power bill"),
            (5000, "Insurance", "Debt & Payments", "Car insurance"),
            (2500, "Groceries", "Food & Dining", "Weekly shopping"),
            (799, "Internet", "Utilities", "WiFi bill"),
            (800, "Doctor Visit", "Health & Medical", "Checkup and medicines"),
            (399, "Software Subscription", "Work & Professional", "Dev tools subscription"),
        ]

        for (amount, desc, category, details) in monthExpenses {
            let dayOffset = Int.random(in: 1...25)
            guard let expenseDate = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfMonth(for: today)) else { continue }
            let expense = Transaction(
                amount: amount,
                category: category,
                date: expenseDate,
                transactionDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }

        guard let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: calendar.startOfMonth(for: today)) else { return expenses }

        let lastMonthExpenses: [(Double, String, String, String)] = [
            (8000, "Travel", "Travel", "Weekend trip accommodation"),
            (3200, "Shopping", "Shopping", "Winter clothes"),
            (500, "Movie", "Entertainment", "Movies with family"),
            (2000, "Gifts", "Gifts", "Birthday gifts for friends"),
            (5000, "Education", "Education", "Online course purchase"),
        ]

        for (amount, desc, category, details) in lastMonthExpenses {
            let dayOffset = Int.random(in: 1...28)
            guard let expenseDate = calendar.date(byAdding: .day, value: dayOffset, to: lastMonthStart) else { continue }
            let expense = Transaction(
                amount: amount,
                category: category,
                date: expenseDate,
                transactionDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }

        return expenses.sorted { $0.date > $1.date }
    }

    static func generateBudgets() -> [MonthlyBudget] {
        var budgets: [MonthlyBudget] = []
        let today = Date()
        let calendar = Calendar.current

        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)

        budgets.append(MonthlyBudget(year: currentYear, month: currentMonth, limit: 50000))

        if currentMonth > 1 {
            budgets.append(MonthlyBudget(year: currentYear, month: currentMonth - 1, limit: 45000))
        } else {
            budgets.append(MonthlyBudget(year: currentYear - 1, month: 12, limit: 45000))
        }

        if currentMonth > 2 {
            budgets.append(MonthlyBudget(year: currentYear, month: currentMonth - 2, limit: 50000))
        } else if currentMonth == 2 {
            budgets.append(MonthlyBudget(year: currentYear - 1, month: 12, limit: 50000))
        } else {
            budgets.append(MonthlyBudget(year: currentYear - 1, month: 11, limit: 50000))
        }

        return budgets
    }

    static func getGroupExpensesForOverview() -> [Transaction] {
        return []
    }

    static func generateRecurringTransactions() -> [RecurringTransaction] {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        return [
            RecurringTransaction(name: "Netflix", amount: 649, category: "Entertainment", frequency: "monthly", dayOfMonth: 1, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Gym", amount: 1500, category: "Health & Medical", frequency: "monthly", dayOfMonth: 5, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Insurance", amount: 5000, category: "Debt & Payments", frequency: "monthly", dayOfMonth: 10, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Internet", amount: 799, category: "Utilities", frequency: "monthly", dayOfMonth: 15, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Lunch", amount: 150, category: "Food & Dining", frequency: "weekly", daysOfWeek: [2, 4], startDate: startOfMonth, isActive: true),
        ]
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.year, .month], from: date)) ?? date
    }
}
#endif
