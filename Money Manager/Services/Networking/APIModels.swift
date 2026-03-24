//
//  APIModels.swift
//  Money Manager
//

import Foundation

struct APIExpense: Codable {
    let id: UUID
    let user_id: UUID
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
    let group_id: UUID?
    let group_name: String?
}

struct APIRecurringExpense: Codable {
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
}

struct APILoginRequest: Codable {
    let email: String
    let password: String
}

struct APICreateExpenseRequest: Codable {
    let amount: String
    let category: String
    let date: Date
    let time: Date?
    let description: String?
    let notes: String?
    let recurring_expense_id: UUID?
    let group_id: UUID?
    let group_name: String?
}

struct APIUpdateExpenseRequest: Codable {
    let amount: String?
    let category: String?
    let date: Date?
    let time: Date?
    let description: String?
    let notes: String?
    let is_deleted: Bool?
    let recurring_expense_id: UUID?
    let group_id: UUID?
    let group_name: String?
}

struct APICreateRecurringExpenseRequest: Codable {
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
}

struct APIUpdateRecurringExpenseRequest: Codable {
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
}

struct APICreateBudgetRequest: Codable {
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

struct APIMonthlyDashboardResponse: Codable {
    let totalExpenses: String?
    let total_expenses: String?
    let expenseCount: Int?
    let expense_count: Int?
    let categoryBreakdown: [APICategoryBreakdown]?
    let category_breakdown: [APICategoryBreakdown]?
    let budgetStatus: APIBudgetStatus?
    let budget_status: APIBudgetStatus?

    enum CodingKeys: String, CodingKey {
        case totalExpenses = "totalExpenses"
        case total_expenses = "total_expenses"
        case expenseCount = "expenseCount"
        case expense_count = "expense_count"
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
