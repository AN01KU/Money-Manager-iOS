//
//  APIBudget.swift
//  Money Manager
//

import Foundation

struct APIUserBudget: Codable, Sendable {
    let limit: Double?
}

struct APISetBudgetRequest: Codable, Sendable {
    let limit: Double?
}
