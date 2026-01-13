//
//  DataService.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation
import SwiftData

@MainActor
class DataService {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Expenses
    
    func fetchExpenses(for month: Date? = nil) -> [Expense] {
        let descriptor: FetchDescriptor<Expense>
        
        if let month = month {
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate<Expense> { expense in
                    !expense.isDeleted &&
                    expense.date >= startOfMonth &&
                    expense.date <= endOfMonth
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate<Expense> { expense in
                    !expense.isDeleted
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
        }
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }
    
    func addExpense(_ expense: Expense) {
        modelContext.insert(expense)
        save()
    }
    
    func updateExpense(_ expense: Expense) {
        expense.updatedAt = Date()
        save()
    }
    
    func deleteExpense(_ expense: Expense) {
        expense.isDeleted = true
        expense.updatedAt = Date()
        save()
    }
    
    func totalSpent(for month: Date) -> Double {
        let expenses = fetchExpenses(for: month)
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func expensesByCategory(for month: Date) -> [String: Double] {
        let expenses = fetchExpenses(for: month)
        return Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    // MARK: - Monthly Budget
    
    func getBudget(for year: Int, month: Int) -> MonthlyBudget? {
        let descriptor = FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate<MonthlyBudget> { budget in
                budget.year == year && budget.month == month
            }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching budget: \(error)")
            return nil
        }
    }
    
    func setBudget(year: Int, month: Int, limit: Double) {
        if let existing = getBudget(for: year, month: month) {
            existing.limit = limit
            existing.updatedAt = Date()
        } else {
            let budget = MonthlyBudget(year: year, month: month, limit: limit)
            modelContext.insert(budget)
        }
        save()
    }
    
    // MARK: - Custom Categories
    
    func fetchCustomCategories() -> [CustomCategory] {
        let descriptor = FetchDescriptor<CustomCategory>(
            predicate: #Predicate<CustomCategory> { category in
                !category.isHidden
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching custom categories: \(error)")
            return []
        }
    }
    
    func addCustomCategory(_ category: CustomCategory) {
        modelContext.insert(category)
        save()
    }
    
    // MARK: - Recurring Expenses
    
    func fetchRecurringExpenses() -> [RecurringExpense] {
        let descriptor = FetchDescriptor<RecurringExpense>(
            predicate: #Predicate<RecurringExpense> { recurring in
                recurring.isActive
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching recurring expenses: \(error)")
            return []
        }
    }
    
    // MARK: - Helper
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
