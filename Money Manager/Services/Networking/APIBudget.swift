//
//  APIBudget.swift
//  Money Manager
//

import Foundation

struct APIMonthlyBudget: Codable, Sendable {
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

struct APICreateBudgetRequest: Codable, Sendable {
    let id: UUID?
    let year: Int
    let month: Int
    let limit: Double
}

struct APIUpdateBudgetRequest: Codable, Sendable {
    let year: Int?
    let month: Int?
    let limit: Double?
}

struct APIUserBudget: Codable, Sendable {
    let limit: Double?
}

struct APISetBudgetRequest: Codable, Sendable {
    let limit: Double?
}
