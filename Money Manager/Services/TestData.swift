import Foundation
import SwiftData

#if DEBUG
struct TestData {

    static func generatePersonalTransactions() -> [Transaction] {
        var expenses: [Transaction] = []
        let today = Date()
        let calendar = Calendar.current

        let todayExpenses = [
            ("Coffee", 120.0, "Morning coffee with colleague"),
            ("Lunch", 450.0, "Office lunch at new cafe"),
            ("Auto Ride", 80.0, "Commute to meeting"),
        ]

        for (desc, amount, details) in todayExpenses {
            let expense = Transaction(
                amount: amount,
                categoryId: UUID(),
                date: today,
                transactionDescription: details
            )
            expenses.append(expense)
        }

        for i in 1...6 {
            guard let expenseDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }

            let weekExpenses: [(String, Double, String)] = [
                ("Dinner", 350, "Restaurant with friends"),
                ("Gas", 2000, "Fuel for car"),
                ("Clothing", 1200, "New shirt and pants"),
                ("Movie", 250, "Cinema ticket"),
                ("Books", 450, "Programming books"),
                ("Gym", 500, "Monthly gym membership"),
            ]

            if i - 1 < weekExpenses.count {
                let (desc, amount, details) = weekExpenses[i - 1]
                let expense = Transaction(
                    amount: amount,
                    categoryId: UUID(),
                    date: expenseDate,
                    transactionDescription: details
                )
                expenses.append(expense)
            }
        }

        let monthExpenses: [(Double, String, String)] = [
            (999, "Phone Bill", "Monthly mobile plan"),
            (1500, "Electricity", "Monthly power bill"),
            (5000, "Insurance", "Car insurance"),
            (2500, "Groceries", "Weekly shopping"),
            (799, "Internet", "WiFi bill"),
            (800, "Doctor Visit", "Checkup and medicines"),
            (399, "Software Subscription", "Dev tools subscription"),
        ]

        for (amount, desc, details) in monthExpenses {
            let dayOffset = Int.random(in: 1...25)
            guard let expenseDate = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfMonth(for: today)) else { continue }
            let expense = Transaction(
                amount: amount,
                categoryId: UUID(),
                date: expenseDate,
                transactionDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }

        guard let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: calendar.startOfMonth(for: today)) else { return expenses }

        let lastMonthExpenses: [(Double, String, String)] = [
            (8000, "Travel", "Weekend trip accommodation"),
            (3200, "Shopping", "Winter clothes"),
            (500, "Movie", "Movies with family"),
            (2000, "Gifts", "Birthday gifts for friends"),
            (5000, "Education", "Online course purchase"),
        ]

        for (amount, desc, details) in lastMonthExpenses {
            let dayOffset = Int.random(in: 1...28)
            guard let expenseDate = calendar.date(byAdding: .day, value: dayOffset, to: lastMonthStart) else { continue }
            let expense = Transaction(
                amount: amount,
                categoryId: UUID(),
                date: expenseDate,
                transactionDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }

        return expenses.sorted { $0.date > $1.date }
    }

    static func generateRecurringTransactions() -> [RecurringTransaction] {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today

        return [
            RecurringTransaction(name: "Netflix", amount: 649, categoryId: UUID(), frequency: .monthly, dayOfMonth: 1, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Gym", amount: 1500, categoryId: UUID(), frequency: .monthly, dayOfMonth: 5, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Insurance", amount: 5000, categoryId: UUID(), frequency: .monthly, dayOfMonth: 10, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Internet", amount: 799, categoryId: UUID(), frequency: .monthly, dayOfMonth: 15, startDate: startOfMonth, isActive: true),
            RecurringTransaction(name: "Lunch", amount: 150, categoryId: UUID(), frequency: .weekly, daysOfWeek: [2, 4], startDate: startOfMonth, isActive: true),
        ]
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        return self.date(from: self.dateComponents([.year, .month], from: date)) ?? date
    }
}
#endif
