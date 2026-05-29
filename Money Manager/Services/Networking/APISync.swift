//
//  APISync.swift
//  Money Manager
//

import Foundation

struct APIMonthlyDashboardResponse: Codable, Sendable {
    let totalTransactions: Double?
    let transactionCount: Int?
    let categoryBreakdown: [APICategoryBreakdown]?
    let budgetStatus: APIBudgetStatus?
    let groupExpensesTotal: Double?
    let netOwed: Double?
    let netOwing: Double?
    let combinedTotal: Double?

    enum CodingKeys: String, CodingKey {
        case totalTransactions = "total_expenses"
        case transactionCount = "expenseCount"
        case categoryBreakdown = "category_breakdown"
        case budgetStatus = "budget_status"
        case groupExpensesTotal = "group_expenses_total"
        case netOwed = "net_owed"
        case netOwing = "net_owing"
        case combinedTotal = "combined_total"
    }
}

struct APICategoryBreakdown: Codable, Sendable {
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

struct APIBudgetStatus: Codable, Sendable {
    let limit: Double
    let spent: Double
    let remaining: Double
    let percentage: Double
}
