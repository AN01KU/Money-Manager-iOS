//
//  APIRecurringTransaction.swift
//  Money Manager
//

import Foundation

struct APIRecurringTransaction: Codable, Sendable {
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
    let type: TransactionKind?

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

struct APICreateRecurringTransactionRequest: Codable, Sendable {
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
    let type: TransactionKind
    var updatedAt: Date? = nil

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
        case updatedAt = "updated_at"
    }
}

struct APIUpdateRecurringTransactionRequest: Codable, Sendable {
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
    let type: TransactionKind?

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
