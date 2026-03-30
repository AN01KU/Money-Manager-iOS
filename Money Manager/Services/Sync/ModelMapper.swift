//
//  ModelMapper.swift
//  Money Manager
//

import Foundation

extension Transaction {
    func toCreateRequest() -> APICreateTransactionRequest {
        APICreateTransactionRequest(
            id: id,
            type: type,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes,
            recurring_expense_id: recurringExpenseId
        )
    }

    func toUpdateRequest() -> APIUpdateTransactionRequest {
        APIUpdateTransactionRequest(
            type: type,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes
        )
    }

    func applyRemote(_ api: APITransaction) {
        self.type = api.type
        self.amount = Double(api.amount) ?? self.amount
        self.category = api.category
        self.date = api.date
        self.time = api.time
        self.transactionDescription = api.description
        self.notes = api.notes
        self.isDeleted = api.is_deleted
        self.recurringExpenseId = api.recurring_expense_id
        self.groupTransactionId = api.group_transaction_id
        self.groupId = api.group_id
        self.groupName = api.group_name
        self.settlementId = api.settlement_id
        self.updatedAt = api.updated_at
    }
}

extension RecurringTransaction {
    func toCreateRequest() -> APICreateRecurringTransactionRequest {
        APICreateRecurringTransactionRequest(
            id: id,
            name: name,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            frequency: frequency,
            day_of_month: dayOfMonth,
            days_of_week: daysOfWeek,
            start_date: startDate,
            end_date: endDate,
            is_active: isActive,
            notes: notes,
            type: type
        )
    }

    func toUpdateRequest() -> APIUpdateRecurringTransactionRequest {
        APIUpdateRecurringTransactionRequest(
            name: name,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            frequency: frequency,
            day_of_month: dayOfMonth,
            days_of_week: daysOfWeek,
            start_date: startDate,
            end_date: endDate,
            is_active: isActive,
            notes: notes,
            type: type
        )
    }

    func applyRemote(_ api: APIRecurringTransaction) {
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
        self.type = api.type ?? self.type
        self.updatedAt = api.updated_at
    }
}

extension MonthlyBudget {
    func toCreateRequest() -> APICreateBudgetRequest {
        APICreateBudgetRequest(
            id: id,
            year: year,
            month: month,
            limit: limit.formatted(.number.precision(.fractionLength(2)).grouping(.never))
        )
    }
    
    func toUpdateRequest() -> APIUpdateBudgetRequest {
        APIUpdateBudgetRequest(
            year: year,
            month: month,
            limit: limit.formatted(.number.precision(.fractionLength(2)).grouping(.never))
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
            id: id,
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
