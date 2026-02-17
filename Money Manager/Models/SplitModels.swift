import Foundation

struct AuthRequest: Encodable {
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: APIUser
}

struct APIUser: Decodable, Identifiable {
    let id: UUID
    let email: String
    let createdAt: String
}

struct SplitGroup: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let createdBy: UUID
    let createdAt: String
}

struct CreateGroupRequest: Encodable {
    let name: String
}

struct AddMemberRequest: Encodable {
    let userId: UUID
}

struct AddMemberResponse: Decodable {
    let message: String
}

struct ExpenseSplit: Codable {
    let userId: UUID
    let amount: String
}

struct SharedExpense: Decodable, Identifiable {
    let id: UUID
    let groupId: UUID
    let description: String
    let category: String
    let totalAmount: String
    let paidBy: UUID
    let createdAt: String
    let splits: [ExpenseSplit]?
}

struct PaginatedExpensesResponse: Decodable {
    let expenses: [SharedExpense]
    let pagination: Pagination
}

struct Pagination: Decodable {
    let limit: Int
    let offset: Int
    let total: Int
}

struct HealthResponse: Decodable {
    let status: String
    let database: String
}

struct CreateSharedExpenseRequest: Encodable {
    let groupId: UUID
    let description: String
    let category: String
    let totalAmount: String
    let splits: [ExpenseSplit]
}

struct UserBalance: Decodable {
    let userId: UUID
    let amount: String
}

struct Settlement: Decodable, Identifiable {
    let id: UUID
    let groupId: UUID
    let fromUser: UUID
    let toUser: UUID
    let amount: String
    let createdAt: String
}

struct CreateSettlementRequest: Encodable {
    let groupId: UUID
    let fromUser: UUID
    let toUser: UUID
    let amount: String
}
