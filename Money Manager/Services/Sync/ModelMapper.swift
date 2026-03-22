//
//  ModelMapper.swift
//  Money Manager
//

import Foundation

extension Expense {
    func toCreateRequest() -> APICreateExpenseRequest {
        APICreateExpenseRequest(
            amount: String(format: "%.2f", amount),
            category: category,
            date: date,
            time: time,
            description: expenseDescription,
            notes: notes,
            recurring_expense_id: recurringExpenseId,
            group_id: groupId,
            group_name: groupName
        )
    }
    
    func toUpdateRequest() -> APIUpdateExpenseRequest {
        APIUpdateExpenseRequest(
            amount: String(format: "%.2f", amount),
            category: category,
            date: date,
            time: time,
            description: expenseDescription,
            notes: notes,
            is_deleted: isDeleted,
            recurring_expense_id: recurringExpenseId,
            group_id: groupId,
            group_name: groupName
        )
    }
    
    func applyRemote(_ api: APIExpense) {
        self.amount = Double(api.amount) ?? self.amount
        self.category = api.category
        self.date = api.date
        self.time = api.time
        self.expenseDescription = api.description
        self.notes = api.notes
        self.isDeleted = api.is_deleted
        self.recurringExpenseId = api.recurring_expense_id
        self.groupId = api.group_id
        self.groupName = api.group_name
        self.updatedAt = api.updated_at
    }
}

extension RecurringExpense {
    func toCreateRequest() -> APICreateRecurringExpenseRequest {
        APICreateRecurringExpenseRequest(
            name: name,
            amount: String(format: "%.2f", amount),
            category: category,
            frequency: frequency,
            day_of_month: dayOfMonth,
            days_of_week: daysOfWeek,
            start_date: startDate,
            end_date: endDate,
            is_active: isActive,
            notes: notes
        )
    }
    
    func toUpdateRequest() -> APIUpdateRecurringExpenseRequest {
        APIUpdateRecurringExpenseRequest(
            name: name,
            amount: String(format: "%.2f", amount),
            category: category,
            frequency: frequency,
            day_of_month: dayOfMonth,
            days_of_week: daysOfWeek,
            start_date: startDate,
            end_date: endDate,
            is_active: isActive,
            notes: notes
        )
    }
    
    func applyRemote(_ api: APIRecurringExpense) {
        self.name = api.name
        self.amount = Double(api.amount) ?? self.amount
        self.category = api.category
        self.frequency = api.frequency
        self.dayOfMonth = api.day_of_month
        self.daysOfWeek = api.days_of_week
        self.startDate = api.start_date
        self.endDate = api.end_date
        self.isActive = api.is_active
        self.lastAddedDate = api.last_added_date
        self.notes = api.notes
        self.updatedAt = api.updated_at
    }
}

extension MonthlyBudget {
    func toCreateRequest() -> APICreateBudgetRequest {
        APICreateBudgetRequest(
            year: year,
            month: month,
            limit: String(format: "%.2f", limit)
        )
    }
    
    func toUpdateRequest() -> APIUpdateBudgetRequest {
        APIUpdateBudgetRequest(
            year: year,
            month: month,
            limit: String(format: "%.2f", limit)
        )
    }
    
    func applyRemote(_ api: APIMonthlyBudget) {
        self.year = api.year
        self.month = api.month
        self.limit = Double(api.limit) ?? self.limit
        self.updatedAt = api.updated_at
    }
}

extension CustomCategory {
    func toCreateRequest() -> APICreateCategoryRequest {
        APICreateCategoryRequest(
            name: name,
            icon: icon,
            color: color
        )
    }
    
    func toUpdateRequest() -> APIUpdateCategoryRequest {
        APIUpdateCategoryRequest(
            name: name,
            icon: icon,
            color: color,
            is_hidden: isHidden
        )
    }
    
    func applyRemote(_ api: APICustomCategory) {
        self.name = api.name
        self.icon = api.icon
        self.color = api.color
        self.isHidden = api.is_hidden
        self.isPredefined = api.is_predefined
        self.predefinedKey = api.predefined_key
        self.updatedAt = api.updated_at
    }
}
