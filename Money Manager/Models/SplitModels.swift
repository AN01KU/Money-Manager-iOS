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
// MARK: - Budget Models

struct BudgetResponse: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: String
    let month: Int
    let year: Int
    let createdAt: String
    let updatedAt: String
}

struct SetBudgetRequest: Encodable {
    let amount: String
    let month: Int
    let year: Int
}

// MARK: - Category Models

struct CategoryResponse: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let color: String
    let icon: String
    let createdAt: String
}

struct CreateCategoryRequest: Encodable {
    let name: String
    let color: String
    let icon: String
}

struct UpdateCategoryRequest: Encodable {
    let name: String?
    let color: String?
    let icon: String?
}

// MARK: - Personal Expense Models

struct PersonalExpenseResponse: Decodable, Identifiable {
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

struct CreatePersonalExpenseRequest: Encodable {
    let categoryId: UUID?
    let amount: String
    let description: String?
    let notes: String?
    let expenseDate: String
}

struct UpdatePersonalExpenseRequest: Encodable {
    let amount: String?
    let description: String?
    let notes: String?
}

struct PaginatedPersonalExpensesResponse: Decodable {
    let expenses: [PersonalExpenseResponse]
    let pagination: Pagination
}

// MARK: - Dashboard Models

struct DashboardResponse: Decodable {
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

struct CategoryBreakdown: Decodable {
    let categoryId: UUID?
    let categoryName: String?
    let totalAmount: String
    let expenseCount: Int
}

// MARK: - Utility Models

struct MessageResponse: Decodable {
    let message: String
}