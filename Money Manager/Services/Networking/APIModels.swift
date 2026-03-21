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

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: Pagination
}

struct ListResponse<T: Codable>: Codable {
    let data: [T]
}

struct Pagination: Codable {
    let limit: Int
    let offset: Int
    let total: Int
}

struct MessageResponse: Codable {
    let message: String
}

struct AuthResponse: Codable {
    let token: String
    let user: APIUser
}

struct APIUser: Codable {
    let id: UUID
    let email: String
    let username: String
    let created_at: Date
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let username: String
    let password: String
}

struct CreateExpenseRequest: Codable {
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

struct UpdateExpenseRequest: Codable {
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

struct CreateRecurringExpenseRequest: Codable {
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

struct UpdateRecurringExpenseRequest: Codable {
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

struct CreateBudgetRequest: Codable {
    let year: Int
    let month: Int
    let limit: String
}

struct UpdateBudgetRequest: Codable {
    let year: Int?
    let month: Int?
    let limit: String?
}

struct CreateCategoryRequest: Codable {
    let name: String
    let icon: String
    let color: String
}

struct UpdateCategoryRequest: Codable {
    let name: String?
    let icon: String?
    let color: String?
    let is_hidden: Bool?
}
