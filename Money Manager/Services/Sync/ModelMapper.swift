//
//  ModelMapper.swift
//  Money Manager
//

import Foundation
import SwiftData

// MARK: - LocalSyncableEntity conformances

extension Transaction: LocalSyncableEntity {
    static var entityType: EntityType { .transaction }
    static var endpoint: String { "/transactions" }

    func createRequestPayload() throws -> Data {
        try AppAPIClient.apiEncoder.encode(toCreateRequest())
    }

    func updateRequestPayload() throws -> Data {
        try AppAPIClient.apiEncoder.encode(toUpdateRequest())
    }
}

extension RecurringTransaction: LocalSyncableEntity {
    static var entityType: EntityType { .recurring }
    static var endpoint: String { "/recurring-transactions" }

    func createRequestPayload() throws -> Data {
        try AppAPIClient.apiEncoder.encode(toCreateRequest())
    }

    func updateRequestPayload() throws -> Data {
        try AppAPIClient.apiEncoder.encode(toUpdateRequest())
    }
}

extension Category: LocalSyncableEntity {
    static var entityType: EntityType { .category }
    static var endpoint: String { "/categories" }

    func createRequestPayload() throws -> Data {
        try AppAPIClient.apiEncoder.encode(toCreateRequest())
    }

    func updateRequestPayload() throws -> Data {
        try AppAPIClient.apiEncoder.encode(toUpdateRequest())
    }
}

// MARK: - Request factories

extension Transaction {
    func toCreateRequest() -> APICreateTransactionRequest {
        APICreateTransactionRequest(
            id: id,
            type: type,
            amount: amount,
            category: category,
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes,
            recurringExpenseId: recurringExpenseId,
            updatedAt: updatedAt
        )
    }

    func toUpdateRequest() -> APIUpdateTransactionRequest {
        APIUpdateTransactionRequest(
            type: type,
            amount: amount,
            category: category,
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes
        )
    }

    func applyRemote(_ api: APITransaction) {
        self.type = api.type
        self.amount = api.amount
        self.category = api.category
        self.date = api.date
        self.time = api.time
        self.transactionDescription = api.description
        self.notes = api.notes
        self.isSoftDeleted = api.isDeleted
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
            amount: amount,
            category: category,
            frequency: frequency.rawValue,
            dayOfMonth: dayOfMonth,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            notes: notes,
            type: type,
            updatedAt: updatedAt
        )
    }

    func toUpdateRequest() -> APIUpdateRecurringTransactionRequest {
        APIUpdateRecurringTransactionRequest(
            name: name,
            amount: amount,
            category: category,
            frequency: frequency.rawValue,
            dayOfMonth: dayOfMonth,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            notes: notes,
            type: type
        )
    }

    func applyRemote(_ api: APIRecurringTransaction) {
        self.name = api.name
        self.amount = api.amount
        self.category = api.category
        self.frequency = RecurringFrequency(rawValue: api.frequency) ?? self.frequency
        self.dayOfMonth = api.dayOfMonth
        self.daysOfWeek = api.daysOfWeek
        self.startDate = api.startDate
        self.endDate = api.endDate
        self.isActive = api.isActive
        self.lastAddedDate = api.lastAddedDate
        self.notes = api.notes
        if let kind = api.type { self.type = kind }
        self.updatedAt = api.updatedAt
    }
}

extension MonthlyBudget {
    func toCreateRequest() -> APICreateBudgetRequest {
        APICreateBudgetRequest(
            id: id,
            year: year,
            month: month,
            limit: limit
        )
    }

    func toUpdateRequest() -> APIUpdateBudgetRequest {
        APIUpdateBudgetRequest(
            year: year,
            month: month,
            limit: limit
        )
    }

    func applyRemote(_ api: APIMonthlyBudget) {
        self.year = api.year
        self.month = api.month
        self.limit = api.limit
        self.updatedAt = api.updatedAt
    }
}

extension Category {
    func toCreateRequest() -> APICreateCategoryRequest {
        if isPredefined, let key = predefinedKey {
            return APICreateCategoryRequest(
                name: isHidden ? nil : name,
                icon: isHidden ? nil : icon,
                color: isHidden ? nil : color,
                isHidden: isHidden ? true : nil,
                predefinedKey: key
            )
        }
        return APICreateCategoryRequest(
            name: name,
            icon: icon,
            color: color,
            isHidden: isHidden ? true : nil,
            predefinedKey: nil
        )
    }
    
    func toUpdateRequest() -> APIUpdateCategoryRequest {
        APIUpdateCategoryRequest(
            name: name,
            icon: icon,
            color: color,
            isHidden: isHidden
        )
    }
    
    func applyRemote(_ api: APICategory) {
        self.key = api.key
        self.name = api.name
        self.icon = api.icon
        self.color = api.color
        self.isHidden = api.isHidden ?? false
        self.isPredefined = api.isPredefined ?? false
        // Normalize legacy camelCase predefinedKey ("foodDining") into the
        // canonical serverKey ("food-dining") so local rows stay consistent.
        self.predefinedKey = api.predefinedKey
            .flatMap { PredefinedCategory.normalizeKey($0) }
            ?? api.predefinedKey
        self.updatedAt = api.updatedAt
    }
}
