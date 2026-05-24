//
//  GroupDomainModels.swift
//  Money Manager
//

import Foundation

// MARK: - Mapping errors

enum GroupMappingError: Error, Equatable {
    case emptyCategory
    case emptyName
    case invalidAmount
}

// MARK: - SplitGroup

struct SplitGroup: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let createdBy: UUID
    let createdAt: Date
    let members: [GroupMember]
    let balances: [GroupBalance]
    let settlements: [Settlement]

    init(from dto: APIGroupWithDetails) throws {
        let trimmed = dto.name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw GroupMappingError.emptyName }
        self.id = dto.id
        self.name = trimmed
        self.createdBy = dto.createdBy
        self.createdAt = dto.createdAt
        self.members = dto.members.map { GroupMember(from: $0) }
        self.balances = dto.balances.map { GroupBalance(from: $0) }
        self.settlements = []
    }

    init(from dto: APIGroupDetailsBody) throws {
        let trimmed = dto.name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw GroupMappingError.emptyName }
        self.id = dto.id
        self.name = trimmed
        self.createdBy = dto.createdBy
        self.createdAt = dto.createdAt
        self.members = dto.members.map { GroupMember(from: $0) }
        self.balances = dto.balances.map { GroupBalance(from: $0) }
        self.settlements = (dto.settlements ?? []).map { Settlement(from: $0) }
    }
}

// MARK: - GroupMember

struct GroupMember: Identifiable, Hashable, Sendable {
    let id: UUID
    let email: String
    let username: String
    let joinedAt: Date?

    init(from dto: APIGroupMember) {
        self.id = dto.id
        self.email = dto.email
        self.username = dto.username
        self.joinedAt = dto.joinedAt
    }
}

// MARK: - GroupBalance

struct GroupBalance: Hashable, Sendable {
    let userId: UUID
    let amount: Double

    init(from dto: APIGroupBalance) {
        self.userId = dto.userId
        self.amount = dto.amount
    }
}

// MARK: - GroupTransactionSplit

struct GroupTransactionSplit: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let amount: Double
    let transactionId: UUID?

    init(from dto: APIGroupTransactionSplit) {
        self.id = dto.id
        self.userId = dto.userId
        self.amount = dto.amount
        self.transactionId = dto.transactionId
    }
}

// MARK: - GroupTransaction

struct GroupTransaction: Identifiable, Hashable, Sendable {
    let id: UUID
    let groupId: UUID
    let paidByUserId: UUID
    let totalAmount: Double
    let category: String
    let date: Date
    let description: String?
    let notes: String?
    let isDeleted: Bool
    let createdAt: Date
    let updatedAt: Date
    let splits: [GroupTransactionSplit]

    init(from dto: APIGroupTransaction) throws {
        let trimmed = dto.category.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw GroupMappingError.emptyCategory }
        guard dto.totalAmount >= 0 else { throw GroupMappingError.invalidAmount }
        self.id = dto.id
        self.groupId = dto.groupId
        self.paidByUserId = dto.paidByUserId
        self.totalAmount = dto.totalAmount
        self.category = trimmed
        self.date = dto.date
        self.description = dto.description
        self.notes = dto.notes
        self.isDeleted = dto.isDeleted
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.splits = dto.splits.map { GroupTransactionSplit(from: $0) }
    }
}

// MARK: - Settlement

struct Settlement: Identifiable, Hashable, Sendable {
    let id: UUID
    let groupId: UUID?
    let fromUser: UUID
    let toUser: UUID
    let amount: Double
    let notes: String?
    let createdAt: Date

    init(from dto: APISettlement) {
        self.id = dto.id
        self.groupId = dto.groupId
        self.fromUser = dto.fromUser
        self.toUser = dto.toUser
        self.amount = dto.amount
        self.notes = dto.notes
        self.createdAt = dto.createdAt
    }
}
