import Foundation

struct AuthRequest: Encodable, Sendable {
    let email: String
    let password: String
}

struct AuthResponse: Decodable, Sendable {
    let token: String
    let user: APIUser
}

struct APIUser: Decodable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let createdAt: String
}

struct SplitGroup: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let createdBy: UUID
    let createdAt: String
}

struct CreateGroupRequest: Encodable, Sendable {
    let name: String
}

struct AddMemberRequest: Encodable, Sendable {
    let userId: UUID
}

struct AddMemberResponse: Decodable, Sendable {
    let message: String
}

struct ExpenseSplit: Codable, Sendable {
    let userId: UUID
    let amount: String
}

struct SharedExpense: Decodable, Identifiable, Sendable {
    let id: UUID
    let groupId: UUID
    let description: String
    let category: String
    let totalAmount: String
    let paidBy: UUID
    let createdAt: String
    let splits: [ExpenseSplit]?
}

struct PaginatedExpensesResponse: Decodable, Sendable {
    let expenses: [SharedExpense]
    let pagination: Pagination
}

struct Pagination: Decodable, Sendable {
    let limit: Int
    let offset: Int
    let total: Int
}

struct HealthResponse: Decodable, Sendable {
    let status: String
    let database: String
}

struct CreateSharedExpenseRequest: Codable, Sendable {
    let groupId: UUID
    let description: String
    let category: String
    let totalAmount: String
    let splits: [ExpenseSplit]
}

struct UserBalance: Decodable, Sendable {
    let userId: UUID
    let amount: String
}

struct Settlement: Decodable, Identifiable, Sendable {
    let id: UUID
    let groupId: UUID
    let fromUser: UUID
    let toUser: UUID
    let amount: String
    let createdAt: String
}

struct CreateSettlementRequest: Encodable, Sendable {
    let groupId: UUID
    let fromUser: UUID
    let toUser: UUID
    let amount: String
}

struct BudgetResponse: Decodable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let amount: String
    let month: Int
    let year: Int
    let createdAt: String
    let updatedAt: String
}

struct SetBudgetRequest: Codable, Sendable {
    let amount: String
    let month: Int
    let year: Int
}

struct CategoryResponse: Decodable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let name: String
    let color: String
    let icon: String
    let createdAt: String
}

struct CreateCategoryRequest: Codable, Sendable {
    let name: String
    let color: String
    let icon: String
}

struct UpdateCategoryRequest: Encodable, Sendable {
    let name: String?
    let color: String?
    let icon: String?
}

struct PersonalExpenseResponse: Decodable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let categoryId: UUID?
    let amount: String
    let description: String?
    let notes: String?
    let expenseDate: String
    let createdAt: String
    let updatedAt: String
}

struct CreatePersonalExpenseRequest: Codable, Sendable {
    let categoryId: UUID?
    let amount: String
    let description: String?
    let notes: String?
    let expenseDate: String
}

struct UpdatePersonalExpenseRequest: Encodable, Sendable {
    let amount: String?
    let description: String?
    let notes: String?
}

struct PaginatedPersonalExpensesResponse: Decodable, Sendable {
    let expenses: [PersonalExpenseResponse]
    let pagination: Pagination
}

struct DashboardResponse: Decodable, Sendable {
    let month: Int
    let year: Int
    let budget: String?
    let totalSpent: String
    let remainingBudget: String?
    let daysInMonth: Int
    let daysElapsed: Int
    let daysRemaining: Int
    let dailyAverageSpent: String
    let projectedSpending: String
    let isOverBudget: Bool
    let expenseCount: Int
    let categoryBreakdown: [CategoryBreakdown]
}

struct CategoryBreakdown: Decodable, Sendable {
    let categoryId: UUID?
    let categoryName: String?
    let totalAmount: String
    let expenseCount: Int
}

struct MessageResponse: Decodable, Sendable {
    let message: String
}
