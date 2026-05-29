//
//  ModelMapper.swift
//  Money Manager
//

import Foundation
import SwiftData

// MARK: - LocalSyncableEntity conformances

extension Transaction: SoftDeletableEntity {}
extension RecurringTransaction: SoftDeletableEntity {}

extension Transaction: LocalSyncableEntity {
    static var entityType: EntityType { .transaction }
    static var endpoint: String { "/transactions" }

    func createRequestPayload() throws -> Data {
        let categories = (try? modelContext?.fetch(FetchDescriptor<Category>())) ?? []
        return try AppAPIClient.apiEncoder.encode(toCreateRequest(categories: categories))
    }

    func updateRequestPayload() throws -> Data {
        let categories = (try? modelContext?.fetch(FetchDescriptor<Category>())) ?? []
        return try AppAPIClient.apiEncoder.encode(toUpdateRequest(categories: categories))
    }
}

extension RecurringTransaction: LocalSyncableEntity {
    static var entityType: EntityType { .recurring }
    static var endpoint: String { "/recurring-transactions" }

    func createRequestPayload() throws -> Data {
        let categories = (try? modelContext?.fetch(FetchDescriptor<Category>())) ?? []
        return try AppAPIClient.apiEncoder.encode(toCreateRequest(categories: categories))
    }

    func updateRequestPayload() throws -> Data {
        let categories = (try? modelContext?.fetch(FetchDescriptor<Category>())) ?? []
        return try AppAPIClient.apiEncoder.encode(toUpdateRequest(categories: categories))
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
    @MainActor func toCreateRequest(categories: [Category]) -> APICreateTransactionRequest {
        APICreateTransactionRequest(
            id: id,
            type: type,
            amount: amount,
            category: CategorySyncHelpers.serverKey(for: categoryId, in: categories),
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes,
            recurringExpenseId: recurringExpenseId,
            updatedAt: updatedAt
        )
    }

    @MainActor func toUpdateRequest(categories: [Category]) -> APIUpdateTransactionRequest {
        APIUpdateTransactionRequest(
            type: type,
            amount: amount,
            category: CategorySyncHelpers.serverKey(for: categoryId, in: categories),
            date: date,
            time: time,
            description: transactionDescription,
            notes: notes
        )
    }

    @MainActor func applyRemote(_ api: APITransaction, keyToUUID: [String: UUID], otherUUID: UUID) {
        self.type = api.type
        self.amount = api.amount
        self.categoryId = CategorySyncHelpers.resolveKey(api.category, keyToUUID: keyToUUID, otherUUID: otherUUID)
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
    @MainActor func toCreateRequest(categories: [Category]) -> APICreateRecurringTransactionRequest {
        APICreateRecurringTransactionRequest(
            id: id,
            name: name,
            amount: amount,
            category: CategorySyncHelpers.serverKey(for: categoryId, in: categories),
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

    @MainActor func toUpdateRequest(categories: [Category]) -> APIUpdateRecurringTransactionRequest {
        APIUpdateRecurringTransactionRequest(
            name: name,
            amount: amount,
            category: CategorySyncHelpers.serverKey(for: categoryId, in: categories),
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

    @MainActor func applyRemote(_ api: APIRecurringTransaction, keyToUUID: [String: UUID], otherUUID: UUID) {
        self.name = api.name
        self.amount = api.amount
        self.categoryId = CategorySyncHelpers.resolveKey(api.category, keyToUUID: keyToUUID, otherUUID: otherUUID)
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
