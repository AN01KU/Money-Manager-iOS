//
//  APIModels.swift
//  Money Manager
//

import Foundation

// MARK: - Transaction

struct APITransaction: Codable {
    let id: UUID
    let userId: UUID
    let type: String          // "expense" or "income"
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
        case recurringExpenseId = "recurring_expense_id"
        case groupTransactionId = "group_transaction_id"
        case groupId = "group_id"
        case groupName = "group_name"
        case settlementId = "settlement_id"
    }
}

struct APIRecurringTransaction: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let amount: Double
    let category: String
    let frequency: String
    let dayOfMonth: Int?
    let daysOfWeek: [Int]?
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let lastAddedDate: Date?
    let nextOccurrence: Date?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case category
        case frequency
        case dayOfMonth = "day_of_month"
        case daysOfWeek = "days_of_week"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case lastAddedDate = "last_added_date"
        case nextOccurrence = "next_occurrence"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case type
    }
}

struct APIMonthlyBudget: Codable {
    let id: UUID
    let userId: UUID
    let year: Int
    let month: Int
    let limit: Double
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case year
        case month
        case limit
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APICustomCategory: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let icon: String
    let color: String
    let isHidden: Bool
    let isPredefined: Bool
    let predefinedKey: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case icon
        case color
        case isHidden = "is_hidden"
        case isPredefined = "is_predefined"
        case predefinedKey = "predefined_key"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APIUser: Codable {
    let id: UUID
    let email: String
    let username: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case createdAt = "created_at"
    }
}

struct APIAuthResponse: Codable {
    let token: String
    let syncSessionId: UUID
    let user: APIUser

    enum CodingKeys: String, CodingKey {
        case token
        case syncSessionId = "sync_session_id"
        case user
    }
}

struct APIPaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: APIPagination
}

struct APIListResponse<T: Codable>: Codable {
    let data: [T]
}

struct APIPagination: Codable {
    let limit: Int
    let offset: Int
    let total: Int
}

struct APIMessageResponse: Codable {
    let message: String
}

struct APISignupRequest: Codable {
    let email: String
    let username: String
    let password: String
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case email
        case username
        case password
        case inviteCode = "invite_code"
    }
}

struct APILoginRequest: Codable {
    let email: String
    let password: String
}

struct APILogoutRequest: Codable {
    let syncSessionId: UUID

    enum CodingKeys: String, CodingKey {
        case syncSessionId = "sync_session_id"
    }
}

struct APISyncPreflightRequest: Codable, Sendable {
    let syncSessionId: UUID

    enum CodingKeys: String, CodingKey {
        case syncSessionId = "sync_session_id"
    }
}

struct APISyncPreflightResponse: Codable, Sendable {
    let valid: Bool
    let reason: String?
}

struct APICreateTransactionRequest: Codable {
    let id: UUID?
    let type: String          // "expense" or "income"
    let amount: Double
    let category: String
    let date: Date
    let time: Date?
    let description: String?
    let notes: String?
    let recurringExpenseId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case amount
        case category
        case date
        case time
        case description
        case notes
        case recurringExpenseId = "recurring_expense_id"
    }
}

struct APIUpdateTransactionRequest: Codable {
    let type: String?
    let amount: Double?
    let category: String?
    let date: Date?
    let time: Date?
    let description: String?
    let notes: String?
}

struct APICreateRecurringTransactionRequest: Codable {
    let id: UUID?
    let name: String
    let amount: Double
    let category: String
    let frequency: String
    let dayOfMonth: Int?
    let daysOfWeek: [Int]?
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let notes: String?
    let type: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case amount
        case category
        case frequency
        case dayOfMonth = "day_of_month"
        case daysOfWeek = "days_of_week"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case notes
        case type
    }
}

struct APIUpdateRecurringTransactionRequest: Codable {
    let name: String?
    let amount: Double?
    let category: String?
    let frequency: String?
    let dayOfMonth: Int?
    let daysOfWeek: [Int]?
    let startDate: Date?
    let endDate: Date?
    let isActive: Bool?
    let notes: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case category
        case frequency
        case dayOfMonth = "day_of_month"
        case daysOfWeek = "days_of_week"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case notes
        case type
    }
}

struct APICreateBudgetRequest: Codable {
    let id: UUID?
    let year: Int
    let month: Int
    let limit: Double
}

struct APIUpdateBudgetRequest: Codable {
    let year: Int?
    let month: Int?
    let limit: Double?
}

struct APICreateCategoryRequest: Codable {
    let id: UUID?
    let name: String
    let icon: String
    let color: String
}

struct APIUpdateCategoryRequest: Codable {
    let name: String?
    let icon: String?
    let color: String?
    let is_hidden: Bool?
}

// MARK: - Group API Models

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

struct APIAddMemberRequest: Codable, Sendable {
    let email: String
}

struct APICreateGroupTransactionRequest: Codable, Sendable {
    let paidByUserId: UUID
    let totalAmount: Double
    let category: String
    let date: Date
    let description: String?
    let notes: String?
    let splits: [APIGroupTransactionSplitInput]

    enum CodingKeys: String, CodingKey {
        case paidByUserId = "paid_by_user_id"
        case totalAmount = "total_amount"
        case category
        case date
        case description
        case notes
        case splits
    }
}

struct APIGroupMembersResponse: Codable, Sendable {
    let members: [APIGroupMember]
}

struct APIGroupsListResponse: Codable, Sendable {
    let data: [APIGroupWithDetails]
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

// MARK: - Dashboard

struct APIMonthlyDashboardResponse: Codable {
    let totalTransactions: Double?
    let transactionCount: Int?
    let categoryBreakdown: [APICategoryBreakdown]?
    let budgetStatus: APIBudgetStatus?

    enum CodingKeys: String, CodingKey {
        case totalTransactions = "total_expenses"
        case transactionCount = "expenseCount"
        case categoryBreakdown = "category_breakdown"
        case budgetStatus = "budget_status"
    }
}

struct APICategoryBreakdown: Codable {
    let category: String?
    let total: Double?
    let amount: Double?
    let count: Int?

    enum CodingKeys: String, CodingKey {
        case category
        case total
        case amount
        case count
    }
}

struct APIBudgetStatus: Codable {
    let limit: Double
    let spent: Double
    let remaining: Double
    let percentage: Double
}
