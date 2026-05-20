//
//  APITransaction.swift
//  Money Manager
//

import Foundation

struct APITransaction: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let type: TransactionKind
    let amount: Double
    let category: String
    let date: Date
    let time: Date?
    let description: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let isDeleted: Bool
    let recurringExpenseId: UUID?
    let groupTransactionId: UUID?
    let groupId: UUID?
    let groupName: String?
    let settlementId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case amount
        case category
        case date
        case time
        case description
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
        case recurringExpenseId = "recurring_transaction_id"
        case groupTransactionId = "group_transaction_id"
        case groupId = "group_id"
        case groupName = "group_name"
        case settlementId = "settlement_id"
    }
}

struct APICreateTransactionRequest: Codable, Sendable {
    let id: UUID?
    let type: TransactionKind
    let amount: Double
    let category: String
    let date: Date
    let time: Date?
    let description: String?
    let notes: String?
    let recurringExpenseId: UUID?
    var updatedAt: Date? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case amount
        case category
        case date
        case time
        case description
        case notes
        case recurringExpenseId = "recurring_transaction_id"
        case updatedAt = "updated_at"
    }
}

struct APIUpdateTransactionRequest: Codable, Sendable {
    let type: TransactionKind?
    let amount: Double?
    let category: String?
    let date: Date?
    let time: Date?
    let description: String?
    let notes: String?
}
