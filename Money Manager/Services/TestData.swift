import Foundation
import SwiftData

#if DEBUG
let useTestData: Bool = CommandLine.arguments.contains("useTestData")

struct TestData {
    
    static func generatePersonalExpenses() -> [Expense] {
        var expenses: [Expense] = []
        let today = Date()
        let calendar = Calendar.current
        
        let todayExpenses = [
            ("Coffee", 120.0, "Food & Dining", "Morning coffee with colleague"),
            ("Lunch", 450.0, "Food & Dining", "Office lunch at new cafe"),
            ("Auto Ride", 80.0, "Transport", "Commute to meeting"),
        ]
        
        for (desc, amount, category, details) in todayExpenses {
            let expense = Expense(
                amount: amount,
                category: category,
                date: today,
                expenseDescription: details
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
                let expense = Expense(
                    amount: amount,
                    category: category,
                    date: expenseDate,
                    expenseDescription: details
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
            let expense = Expense(
                amount: amount,
                category: category,
                date: expenseDate,
                expenseDescription: desc,
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
            let expense = Expense(
                amount: amount,
                category: category,
                date: expenseDate,
                expenseDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }
        
        let recurringExpenses: [(Double, String, String, String)] = [
            (649, "Netflix", "Entertainment", "monthly"),
            (500, "Gym", "Health & Medical", "monthly"),
            (5000, "Insurance", "Debt & Payments", "monthly"),
            (799, "Internet", "Utilities", "monthly"),
            (500, "Lunch", "Food & Dining", "weekly"),
        ]
        
        for (amount, name, category, frequency) in recurringExpenses {
            let expense = Expense(
                amount: amount,
                category: category,
                date: today,
                expenseDescription: name,
                isRecurring: true,
                frequency: frequency
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
    
    static func getGroupExpensesForOverview() -> [Expense] {
        return []
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.year, .month], from: date)) ?? date
    }
}
#endif
