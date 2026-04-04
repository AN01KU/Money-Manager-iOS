//
//  ModelMapper.swift
//  Money Manager
//

import Foundation

extension Transaction {
    func toCreateRequest() -> APICreateTransactionRequest {
        APICreateTransactionRequest(
            id: id,
            type: type.rawValue,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes,
            recurringExpenseId: recurringExpenseId
        )
    }

    func toUpdateRequest() -> APIUpdateTransactionRequest {
        APIUpdateTransactionRequest(
            type: type.rawValue,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes
        )
    }

    func applyRemote(_ api: APITransaction) {
        self.type = TransactionKind(rawValue: api.type) ?? self.type
        self.amount = Double(api.amount) ?? self.amount
        self.category = api.category
        self.date = api.date
        self.time = api.time
        self.transactionDescription = api.description
        self.notes = api.notes
        self.isDeleted = api.isDeleted
        self.recurringExpenseId = api.recurringExpenseId
        self.groupTransactionId = api.groupTransactionId
        self.groupId = api.groupId
        self.groupName = api.groupName
        self.settlementId = api.settlementId
        self.updatedAt = api.updatedAt
    }
}

extension RecurringTransaction {
    func toCreateRequest() -> APICreateRecurringTransactionRequest {
        APICreateRecurringTransactionRequest(
            id: id,
            name: name,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            frequency: frequency.rawValue,
            dayOfMonth: dayOfMonth,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            notes: notes,
            type: type.rawValue
        )
    }

    func toUpdateRequest() -> APIUpdateRecurringTransactionRequest {
        APIUpdateRecurringTransactionRequest(
            name: name,
            amount: amount.formatted(.number.precision(.fractionLength(2)).grouping(.never)),
            category: category,
            frequency: frequency.rawValue,
            dayOfMonth: dayOfMonth,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            notes: notes,
            type: type.rawValue
        )
    }

    func applyRemote(_ api: APIRecurringTransaction) {
        self.name = api.name
        self.amount = Double(api.amount) ?? self.amount
        self.category = api.category
        self.frequency = RecurringFrequency(rawValue: api.frequency) ?? self.frequency
        self.dayOfMonth = api.dayOfMonth
        self.daysOfWeek = api.daysOfWeek
        self.startDate = api.startDate
        self.endDate = api.endDate
        self.isActive = api.isActive
        self.lastAddedDate = api.lastAddedDate
        self.notes = api.notes
        if let apiType = api.type, let kind = TransactionKind(rawValue: apiType) {
            self.type = kind
        }
        self.updatedAt = api.updatedAt
    }
}

extension MonthlyBudget {
    func toCreateRequest() -> APICreateBudgetRequest {
        APICreateBudgetRequest(
            id: id,
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
        self.updatedAt = api.updatedAt
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
            is_hidden: isHidden  // is_hidden intentionally left as-is per refactor rules
        )
    }
    
    func applyRemote(_ api: APICustomCategory) {
        self.name = api.name
        self.icon = api.icon
        self.color = api.color
        self.isHidden = api.isHidden
        self.isPredefined = api.isPredefined
        self.predefinedKey = api.predefinedKey
        self.updatedAt = api.updatedAt
    }
}
