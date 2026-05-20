//
//  APIGroup.swift
//  Money Manager
//

import Foundation

struct APIGroup: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let createdBy: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    static func == (lhs: APIGroup, rhs: APIGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APIGroupMember: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let username: String
    let joinedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case joinedAt = "joined_at"
    }
}

struct APIGroupBalance: Codable, Sendable {
    let userId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case amount
    }
}

struct APIGroupWithDetails: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let createdBy: UUID
    let createdAt: Date
    let members: [APIGroupMember]
    let balances: [APIGroupBalance]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdBy = "created_by"
        case createdAt = "created_at"
        case members
        case balances
    }

    static func == (lhs: APIGroupWithDetails, rhs: APIGroupWithDetails) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APIGroupTransaction: Codable, Identifiable, Sendable {
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
    let splits: [APIGroupTransactionSplit]

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case paidByUserId = "paid_by_user_id"
        case totalAmount = "total_amount"
        case category
        case date
        case description
        case notes
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case splits
    }
}

struct APIGroupTransactionSplit: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let amount: Double
    let transactionId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case transactionId = "transaction_id"
    }
}

struct APIGroupDetails: Codable, Sendable {
    let group: APIGroupDetailsBody
    let isMember: Bool

    enum CodingKeys: String, CodingKey {
        case group
        case isMember = "is_member"
    }
}

struct APIGroupDetailsBody: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let createdBy: UUID
    let createdAt: Date
    let members: [APIGroupMember]
    let balances: [APIGroupBalance]
    let settlements: [APISettlement]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdBy = "created_by"
        case createdAt = "created_at"
        case members
        case balances
        case settlements
    }
}

struct APIGroupTransactionSplitInput: Codable, Sendable {
    let userId: UUID
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case amount
    }
}

struct APICreateGroupRequest: Codable, Sendable {
    let name: String
}

struct APIRenameGroupRequest: Codable, Sendable {
    let name: String
}

struct APIAddMemberRequest: Codable, Sendable {
    let email: String

    init(email: String) {
        self.email = email.lowercased()
    }
}

struct APICreateGroupTransactionRequest: Codable, Sendable {
    let paidByUserId: UUID
    let totalAmount: Double
    let category: String
    let date: Date
    let description: String?
    let notes: String?
    let splits: [APIGroupTransactionSplitInput]
    var updatedAt: Date? = nil

    enum CodingKeys: String, CodingKey {
        case paidByUserId = "paid_by_user_id"
        case totalAmount = "total_amount"
        case category
        case date
        case description
        case notes
        case splits
        case updatedAt = "updated_at"
    }
}

struct APIUpdateGroupTransactionRequest: Codable, Sendable {
    let category: String?
    let date: Date?
    let description: String?
    let notes: String?
    let updatedAt: Date?
    let paidByUserId: UUID?

    enum CodingKeys: String, CodingKey {
        case category, date, description, notes
        case updatedAt = "updated_at"
        case paidByUserId = "paid_by_user_id"
    }
}

struct APICreateSettlementRequest: Codable, Sendable {
    let groupId: UUID
    let fromUser: UUID
    let toUser: UUID
    let amount: Double
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case fromUser = "from_user"
        case toUser = "to_user"
        case amount
        case notes
    }
}

struct APISettlement: Codable, Identifiable, Sendable {
    let id: UUID
    let groupId: UUID?
    let fromUser: UUID
    let toUser: UUID
    let amount: Double
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case fromUser = "from_user"
        case toUser = "to_user"
        case amount
        case notes
        case createdAt = "created_at"
    }
}

// Typealiases for backward compatibility — callers can migrate to APIListResponse<T> directly.
typealias APIGroupsListResponse = APIListResponse<APIGroupWithDetails>
typealias APIGroupMembersResponse = APIListResponse<APIGroupMember>
