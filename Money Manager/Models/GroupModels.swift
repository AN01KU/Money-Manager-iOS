//
//  GroupModels.swift
//  Money Manager
//

import Foundation
import SwiftData

@Model
final class SplitGroupModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdBy: UUID
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \GroupMemberModel.group)
    var members: [GroupMemberModel] = []

    @Relationship(deleteRule: .cascade, inverse: \GroupExpenseModel.group)
    var expenses: [GroupExpenseModel] = []

    @Relationship(deleteRule: .cascade, inverse: \GroupBalanceModel.group)
    var balances: [GroupBalanceModel] = []

    init(id: UUID, name: String, createdBy: UUID, createdAt: Date) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

@Model
final class GroupMemberModel {
    @Attribute(.unique) var id: UUID
    var email: String
    var username: String
    var joinedAt: Date

    var group: SplitGroupModel?

    init(id: UUID, email: String, username: String, joinedAt: Date) {
        self.id = id
        self.email = email
        self.username = username
        self.joinedAt = joinedAt
    }
}

@Model
final class GroupExpenseModel {
    @Attribute(.unique) var id: UUID
    var expenseDescription: String
    var totalAmount: Double
    var paidBy: UUID
    var createdAt: Date

    var group: SplitGroupModel?

    init(id: UUID, description: String, totalAmount: Double, paidBy: UUID, createdAt: Date) {
        self.id = id
        self.expenseDescription = description
        self.totalAmount = totalAmount
        self.paidBy = paidBy
        self.createdAt = createdAt
    }
}

@Model
final class GroupBalanceModel {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var amount: Double

    var group: SplitGroupModel?

    init(id: UUID = UUID(), userId: UUID, amount: Double) {
        self.id = id
        self.userId = userId
        self.amount = amount
    }
}
