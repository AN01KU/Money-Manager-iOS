//
//  APIModels.swift
//  Money Manager
//

import Foundation

// MARK: - Transaction

struct APITransaction: Codable {
    let id: UUID
    let user_id: UUID
    let type: String          // "expense" or "income"
    let amount: String
    let category: String
    let date: Date
    let time: Date?
    let description: String?
    let notes: String?
    let created_at: Date
    let updated_at: Date
    let is_deleted: Bool
    let recurring_expense_id: UUID?
    let group_transaction_id: UUID?
    let group_id: UUID?
    let group_name: String?
    let settlement_id: UUID?
}

struct APIRecurringTransaction: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let amount: String
    let category: String
    let frequency: String
    let day_of_month: Int?
    let days_of_week: [Int]?
    let start_date: Date
    let end_date: Date?
    let is_active: Bool
    let last_added_date: Date?
    let notes: String?
    let created_at: Date
    let updated_at: Date
    let type: String?
}

struct APIMonthlyBudget: Codable {
    let id: UUID
    let user_id: UUID
    let year: Int
    let month: Int
    let limit: String
    let created_at: Date
    let updated_at: Date
}

struct APICustomCategory: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let icon: String
    let color: String
    let is_hidden: Bool
    let is_predefined: Bool
    let predefined_key: String?
    let created_at: Date
    let updated_at: Date
}

struct APIUser: Codable {
    let id: UUID
    let email: String
    let username: String
    let created_at: Date
}

struct APIAuthResponse: Codable {
    let token: String
    let user: APIUser
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
    let invite_code: String
}

struct APILoginRequest: Codable {
    let email: String
    let password: String
}

struct APICreateTransactionRequest: Codable {
    let id: UUID?
    let type: String          // "expense" or "income"
    let amount: String
    let category: String
    let date: Date
    let time: Date?
    let description: String?
    let notes: String?
    let recurring_expense_id: UUID?
}

struct APIUpdateTransactionRequest: Codable {
    let type: String?
    let amount: String?
    let category: String?
    let date: Date?
    let time: Date?
    let description: String?
    let notes: String?
}

struct APICreateRecurringTransactionRequest: Codable {
    let id: UUID?
    let name: String
    let amount: String
    let category: String
    let frequency: String
    let day_of_month: Int?
    let days_of_week: [Int]?
    let start_date: Date
    let end_date: Date?
    let is_active: Bool
    let notes: String?
    let type: String
}

struct APIUpdateRecurringTransactionRequest: Codable {
    let name: String?
    let amount: String?
    let category: String?
    let frequency: String?
    let day_of_month: Int?
    let days_of_week: [Int]?
    let start_date: Date?
    let end_date: Date?
    let is_active: Bool?
    let notes: String?
    let type: String?
}

struct APICreateBudgetRequest: Codable {
    let id: UUID?
    let year: Int
    let month: Int
    let limit: String
}

struct APIUpdateBudgetRequest: Codable {
    let year: Int?
    let month: Int?
    let limit: String?
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
    let created_by: UUID
    let created_at: Date

    static func == (lhs: APIGroup, rhs: APIGroup) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APIGroupMember: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let username: String
    let joined_at: Date?
}

struct APIGroupBalance: Codable, Sendable {
    let user_id: UUID
    let amount: String
}

struct APIGroupWithDetails: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let created_by: UUID
    let created_at: Date
    let members: [APIGroupMember]
    let balances: [APIGroupBalance]

    static func == (lhs: APIGroupWithDetails, rhs: APIGroupWithDetails) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct APIGroupTransaction: Codable, Identifiable, Sendable {
    let id: UUID
    let group_id: UUID
    let paid_by_user_id: UUID
    let total_amount: String
    let category: String
    let date: Date
    let description: String?
    let notes: String?
    let is_deleted: Bool
    let created_at: Date
    let updated_at: Date
    let splits: [APIGroupTransactionSplit]
}

struct APIGroupTransactionSplit: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    let amount: String
    let transaction_id: UUID?
}

struct APIGroupDetails: Codable, Sendable {
    let group: APIGroupDetailsBody
    let is_member: Bool
}

struct APIGroupDetailsBody: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let created_by: UUID
    let created_at: Date
    let members: [APIGroupMember]
    let balances: [APIGroupBalance]
    let settlements: [APISettlement]?
}

struct APIGroupTransactionSplitInput: Codable, Sendable {
    let user_id: UUID
    let amount: String
}

struct APICreateGroupRequest: Codable, Sendable {
    let name: String
}

struct APIAddMemberRequest: Codable, Sendable {
    let email: String
}

struct APICreateGroupTransactionRequest: Codable, Sendable {
    let paid_by_user_id: UUID
    let total_amount: String
    let category: String
    let date: Date
    let description: String?
    let notes: String?
    let splits: [APIGroupTransactionSplitInput]
}

struct APIGroupMembersResponse: Codable, Sendable {
    let members: [APIGroupMember]
}

struct APIGroupsListResponse: Codable, Sendable {
    let data: [APIGroupWithDetails]
}

struct APICreateSettlementRequest: Codable, Sendable {
    let group_id: UUID
    let from_user: UUID
    let to_user: UUID
    let amount: String
    let notes: String?

    init(group_id: UUID, from_user: UUID, to_user: UUID, amount: String, notes: String? = nil) {
        self.group_id = group_id
        self.from_user = from_user
        self.to_user = to_user
        self.amount = amount
        self.notes = notes
    }
}

struct APISettlement: Codable, Identifiable, Sendable {
    let id: UUID
    let group_id: UUID?
    let from_user: UUID
    let to_user: UUID
    let amount: String
    let notes: String?
    let created_at: Date
}

// MARK: - Dashboard

struct APIMonthlyDashboardResponse: Codable {
    let totalTransactions: String?
    let transactionCount: Int?
    let categoryBreakdown: [APICategoryBreakdown]?
    let category_breakdown: [APICategoryBreakdown]?
    let budgetStatus: APIBudgetStatus?
    let budget_status: APIBudgetStatus?

    enum CodingKeys: String, CodingKey {
        case totalTransactions = "total_expenses"
        case transactionCount = "expenseCount"
        case categoryBreakdown = "categoryBreakdown"
        case category_breakdown = "category_breakdown"
        case budgetStatus = "budgetStatus"
        case budget_status = "budget_status"
    }
}

struct APICategoryBreakdown: Codable {
    let category: String?
    let total: String?
    let amount: String?
    let count: Int?

    enum CodingKeys: String, CodingKey {
        case category
        case total
        case amount
        case count
    }
}

struct APIBudgetStatus: Codable {
    let limit: String
    let spent: String
    let remaining: String
    let percentage: Double
}
