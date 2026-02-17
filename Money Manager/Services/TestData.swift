import Foundation
import SwiftData

/// Comprehensive test data for UI coverage and development
struct TestData {
    
    // MARK: - Users
    static let currentUser = APIUser(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        email: "ankush@example.com",
        createdAt: "2025-06-15T10:00:00Z"
    )
    
    static let testUsers: [APIUser] = [
        currentUser,
        APIUser(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, email: "ravi@example.com", createdAt: "2025-07-01T10:00:00Z"),
        APIUser(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, email: "priya@example.com", createdAt: "2025-07-10T10:00:00Z"),
        APIUser(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, email: "neha@example.com", createdAt: "2025-08-01T10:00:00Z"),
        APIUser(id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!, email: "amit@example.com", createdAt: "2025-08-15T10:00:00Z"),
    ]
    
    // MARK: - Groups
    static let testGroups: [SplitGroup] = [
        SplitGroup(id: UUID(uuidString: "aaaa1111-1111-1111-1111-111111111111")!, name: "Goa Trip", createdBy: currentUser.id, createdAt: "2025-12-01T10:00:00Z"),
        SplitGroup(id: UUID(uuidString: "aaaa2222-2222-2222-2222-222222222222")!, name: "Flat Expenses", createdBy: testUsers[1].id, createdAt: "2025-11-15T10:00:00Z"),
        SplitGroup(id: UUID(uuidString: "aaaa3333-3333-3333-3333-333333333333")!, name: "Office Lunch", createdBy: currentUser.id, createdAt: "2026-01-05T10:00:00Z"),
        SplitGroup(id: UUID(uuidString: "aaaa4444-4444-4444-4444-444444444444")!, name: "Weekend Hangout", createdBy: testUsers[2].id, createdAt: "2026-02-01T10:00:00Z"),
    ]
    
    static let testGroupMembers: [UUID: [APIUser]] = [
        testGroups[0].id: [testUsers[0], testUsers[1], testUsers[2]],
        testGroups[1].id: [testUsers[0], testUsers[1], testUsers[3]],
        testGroups[2].id: [testUsers[0], testUsers[1], testUsers[2], testUsers[3], testUsers[4]],
        testGroups[3].id: [testUsers[0], testUsers[2], testUsers[3]],
    ]
    
    // MARK: - Shared Expenses (Group Expenses)
    static let testSharedExpenses: [UUID: [SharedExpense]] = [
        testGroups[0].id: [
            SharedExpense(id: UUID(), groupId: testGroups[0].id, description: "Hotel booking", category: "Travel", totalAmount: "9000.00", paidBy: currentUser.id, createdAt: "2025-12-10T14:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "3000.00"),
                ExpenseSplit(userId: testUsers[1].id, amount: "3000.00"),
                ExpenseSplit(userId: testUsers[2].id, amount: "3000.00"),
            ]),
            SharedExpense(id: UUID(), groupId: testGroups[0].id, description: "Dinner at beach shack", category: "Food & Dining", totalAmount: "2400.00", paidBy: testUsers[1].id, createdAt: "2025-12-11T20:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "800.00"),
                ExpenseSplit(userId: testUsers[1].id, amount: "800.00"),
                ExpenseSplit(userId: testUsers[2].id, amount: "800.00"),
            ]),
            SharedExpense(id: UUID(), groupId: testGroups[0].id, description: "Cab to airport", category: "Transport", totalAmount: "1500.00", paidBy: testUsers[2].id, createdAt: "2025-12-12T08:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "500.00"),
                ExpenseSplit(userId: testUsers[1].id, amount: "500.00"),
                ExpenseSplit(userId: testUsers[2].id, amount: "500.00"),
            ]),
        ],
        testGroups[1].id: [
            SharedExpense(id: UUID(), groupId: testGroups[1].id, description: "Electricity bill", category: "Utilities", totalAmount: "3200.00", paidBy: currentUser.id, createdAt: "2026-01-05T10:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "1066.67"),
                ExpenseSplit(userId: testUsers[1].id, amount: "1066.67"),
                ExpenseSplit(userId: testUsers[3].id, amount: "1066.66"),
            ]),
            SharedExpense(id: UUID(), groupId: testGroups[1].id, description: "WiFi monthly", category: "Utilities", totalAmount: "999.00", paidBy: testUsers[1].id, createdAt: "2026-01-01T10:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "333.00"),
                ExpenseSplit(userId: testUsers[1].id, amount: "333.00"),
                ExpenseSplit(userId: testUsers[3].id, amount: "333.00"),
            ]),
            SharedExpense(id: UUID(), groupId: testGroups[1].id, description: "Water bill", category: "Utilities", totalAmount: "1500.00", paidBy: testUsers[3].id, createdAt: "2026-02-01T10:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "500.00"),
                ExpenseSplit(userId: testUsers[1].id, amount: "500.00"),
                ExpenseSplit(userId: testUsers[3].id, amount: "500.00"),
            ]),
        ],
        testGroups[2].id: [
            SharedExpense(id: UUID(), groupId: testGroups[2].id, description: "Pizza order", category: "Food & Dining", totalAmount: "1800.00", paidBy: testUsers[4].id, createdAt: "2026-02-10T13:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "360.00"),
                ExpenseSplit(userId: testUsers[1].id, amount: "360.00"),
                ExpenseSplit(userId: testUsers[2].id, amount: "360.00"),
                ExpenseSplit(userId: testUsers[3].id, amount: "360.00"),
                ExpenseSplit(userId: testUsers[4].id, amount: "360.00"),
            ]),
            SharedExpense(id: UUID(), groupId: testGroups[2].id, description: "Coffee & snacks", category: "Food & Dining", totalAmount: "800.00", paidBy: currentUser.id, createdAt: "2026-02-12T10:30:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "160.00"),
                ExpenseSplit(userId: testUsers[1].id, amount: "160.00"),
                ExpenseSplit(userId: testUsers[2].id, amount: "160.00"),
                ExpenseSplit(userId: testUsers[3].id, amount: "160.00"),
                ExpenseSplit(userId: testUsers[4].id, amount: "160.00"),
            ]),
        ],
        testGroups[3].id: [
            SharedExpense(id: UUID(), groupId: testGroups[3].id, description: "Movie tickets", category: "Entertainment", totalAmount: "900.00", paidBy: currentUser.id, createdAt: "2026-02-14T18:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "300.00"),
                ExpenseSplit(userId: testUsers[2].id, amount: "300.00"),
                ExpenseSplit(userId: testUsers[3].id, amount: "300.00"),
            ]),
            SharedExpense(id: UUID(), groupId: testGroups[3].id, description: "Dinner after movie", category: "Food & Dining", totalAmount: "1200.00", paidBy: testUsers[3].id, createdAt: "2026-02-14T21:00:00Z", splits: [
                ExpenseSplit(userId: testUsers[0].id, amount: "400.00"),
                ExpenseSplit(userId: testUsers[2].id, amount: "400.00"),
                ExpenseSplit(userId: testUsers[3].id, amount: "400.00"),
            ]),
        ],
    ]
    
    static let testBalances: [UUID: [UserBalance]] = [
        testGroups[0].id: [
            UserBalance(userId: testUsers[0].id, amount: "-5700.00"),
            UserBalance(userId: testUsers[1].id, amount: "1100.00"),
            UserBalance(userId: testUsers[2].id, amount: "500.00"),
        ],
        testGroups[1].id: [
            UserBalance(userId: testUsers[0].id, amount: "-2366.67"),
            UserBalance(userId: testUsers[1].id, amount: "732.67"),
            UserBalance(userId: testUsers[3].id, amount: "1566.66"),
        ],
        testGroups[2].id: [
            UserBalance(userId: testUsers[0].id, amount: "200.00"),
            UserBalance(userId: testUsers[1].id, amount: "200.00"),
            UserBalance(userId: testUsers[2].id, amount: "200.00"),
            UserBalance(userId: testUsers[3].id, amount: "200.00"),
            UserBalance(userId: testUsers[4].id, amount: "-1040.00"),
        ],
        testGroups[3].id: [
            UserBalance(userId: testUsers[0].id, amount: "-400.00"),
            UserBalance(userId: testUsers[2].id, amount: "-100.00"),
            UserBalance(userId: testUsers[3].id, amount: "500.00"),
        ],
    ]
    
    // MARK: - Personal Expenses
    /// Generate comprehensive personal expenses for different time periods and categories
    static func generatePersonalExpenses() -> [Expense] {
        var expenses: [Expense] = []
        let today = Date()
        let calendar = Calendar.current
        
        // Today's expenses
        let todayExpenses = [
            ("Coffee", 120, "Food & Dining", "Morning coffee with colleague"),
            ("Lunch", 450, "Food & Dining", "Office lunch at new cafe"),
            ("Auto Ride", 80, "Transport", "Commute to meeting"),
        ]
        
        for (desc, amount, category, details) in todayExpenses {
            let expense = Expense(
                amount: Double(amount),
                category: category,
                date: today,
                expenseDescription: details
            )
            expenses.append(expense)
        }
        
        // This week's expenses (last 7 days)
        for i in 1...6 {
            let expenseDate = calendar.date(byAdding: .day, value: -i, to: today)!
            
            let weekExpenses: [(String, Double, String, String)] = [
                ("Dinner", 350, "Food & Dining", "Restaurant with friends"),
                ("Gas", 2000, "Transport", "Fuel for car"),
                ("Clothing", 1200, "Shopping", "New shirt and pants"),
                ("Movie", 250, "Entertainment", "Cinema ticket"),
                ("Books", 450, "Books & Media", "Programming books"),
                ("Gym", 500, "Health & Medical", "Monthly gym membership"),
            ]
            
            if i <= weekExpenses.count {
                let (desc, amount, category, details) = weekExpenses[i-1]
                let expense = Expense(
                    amount: amount,
                    category: category,
                    date: expenseDate,
                    expenseDescription: details
                )
                expenses.append(expense)
            }
        }
        
        // Current month's expenses
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        let monthExpenses: [(Int, String, Double, String, String)] = [
            (5, "Phone Bill", 999, "Utilities", "Monthly mobile plan"),
            (8, "Electricity", 1500, "Housing", "Monthly power bill"),
            (10, "Insurance", 5000, "Debt & Payments", "Car insurance"),
            (12, "Groceries", 2500, "Food & Dining", "Weekly shopping"),
            (15, "Internet", 799, "Utilities", "WiFi bill"),
            (18, "Doctor Visit", 800, "Health & Medical", "Checkup and medicines"),
            (20, "Software Subscription", 399, "Work & Professional", "Dev tools subscription"),
        ]
        
        for (day, desc, amount, category, details) in monthExpenses {
            let expenseDate = calendar.date(byAdding: .day, value: day, to: monthStart)!
            let expense = Expense(
                amount: amount,
                category: category,
                date: expenseDate,
                expenseDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }
        
        // Previous month's expenses
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart)!
        
        let lastMonthExpenses: [(Int, String, Double, String, String)] = [
            (3, "Travel", 8000, "Travel", "Weekend trip accommodation"),
            (8, "Shopping", 3200, "Shopping", "Winter clothes"),
            (15, "Movie", 500, "Entertainment", "Movies with family"),
            (20, "Gifts", 2000, "Gifts", "Birthday gifts for friends"),
            (25, "Education", 5000, "Education", "Online course purchase"),
        ]
        
        for (day, desc, amount, category, details) in lastMonthExpenses {
            let expenseDate = calendar.date(byAdding: .day, value: day, to: lastMonthStart)!
            let expense = Expense(
                amount: amount,
                category: category,
                date: expenseDate,
                expenseDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }
        
        // Previous months (December)
        let decemberStart = calendar.date(byAdding: .month, value: -2, to: monthStart)!
        
        let decemberExpenses: [(Int, String, Double, String, String)] = [
            (5, "Shopping", 4500, "Shopping", "Holiday shopping"),
            (10, "Travel", 12000, "Travel", "Holiday trip booking"),
            (15, "Entertainment", 1500, "Entertainment", "Party and celebration"),
            (20, "Gifts", 3000, "Gifts", "Christmas gifts"),
        ]
        
        for (day, desc, amount, category, details) in decemberExpenses {
            let expenseDate = calendar.date(byAdding: .day, value: day, to: decemberStart)!
            let expense = Expense(
                amount: amount,
                category: category,
                date: expenseDate,
                expenseDescription: desc,
                notes: details
            )
            expenses.append(expense)
        }
        
        return expenses.sorted { $0.date > $1.date }
    }
    
    // MARK: - Budgets
    /// Generate budgets for current and previous months
    static func generateBudgets() -> [MonthlyBudget] {
        var budgets: [MonthlyBudget] = []
        let today = Date()
        let calendar = Calendar.current
        
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        // Current month budget
        budgets.append(MonthlyBudget(year: currentYear, month: currentMonth, limit: 50000))
        
        // Previous month budget
        if currentMonth > 1 {
            budgets.append(MonthlyBudget(year: currentYear, month: currentMonth - 1, limit: 45000))
        } else {
            budgets.append(MonthlyBudget(year: currentYear - 1, month: 12, limit: 45000))
        }
        
        // Two months back
        if currentMonth > 2 {
            budgets.append(MonthlyBudget(year: currentYear, month: currentMonth - 2, limit: 50000))
        } else if currentMonth == 2 {
            budgets.append(MonthlyBudget(year: currentYear - 1, month: 12, limit: 50000))
        } else {
            budgets.append(MonthlyBudget(year: currentYear - 1, month: 11, limit: 50000))
        }
        
        return budgets
    }
    
    // MARK: - Recurring Expenses
    /// Generate recurring expenses
    static func generateRecurringExpenses() -> [RecurringExpense] {
        var recurring: [RecurringExpense] = []
        let today = Date()
        
        let recurringExpenses: [(String, Double, String, String)] = [
            ("Netflix", 649, "Entertainment", "monthly"),
            ("Gym", 500, "Health & Medical", "monthly"),
            ("Insurance", 5000, "Debt & Payments", "monthly"),
            ("Internet", 799, "Utilities", "monthly"),
            ("Lunch", 500, "Food & Dining", "weekly"),
        ]
        
        for (name, amount, category, frequency) in recurringExpenses {
            let expense = RecurringExpense(
                name: name,
                amount: amount,
                category: category,
                frequency: frequency,
                startDate: today
            )
            recurring.append(expense)
        }
        
        return recurring
    }
    
    // MARK: - Group Expenses for Overview
    /// Convert shared expenses to personal expense view for current user
    static func getGroupExpensesForOverview() -> [Expense] {
        var allExpenses: [Expense] = []
        let formatter = ISO8601DateFormatter()
        
        for (groupId, sharedExpenses) in testSharedExpenses {
            let groupName = testGroups.first(where: { $0.id == groupId })?.name ?? "Unknown Group"
            
            for sharedExpense in sharedExpenses {
                // Get the current user's split amount
                if let userSplit = sharedExpense.splits?.first(where: { $0.userId == currentUser.id }),
                   let amount = Double(userSplit.amount) {
                    
                    let expenseDate = formatter.date(from: sharedExpense.createdAt) ?? Date()
                    let expense = Expense(
                        amount: amount,
                        category: sharedExpense.category,
                        date: expenseDate,
                        expenseDescription: "\(sharedExpense.description) (\(groupName))",
                        notes: "Your share from group split",
                        groupId: groupId,
                        groupName: groupName
                    )
                    expense.createdAt = expenseDate
                    allExpenses.append(expense)
                }
            }
        }
        
        return allExpenses
    }
    
    // MARK: - Helper Functions
    static func emailForUser(_ userId: UUID) -> String {
        testUsers.first(where: { $0.id == userId })?.email ?? "Unknown"
    }
    
    static func nameForUser(_ userId: UUID) -> String {
        let email = emailForUser(userId)
        return email.components(separatedBy: "@").first?.capitalized ?? "Unknown"
    }
}
