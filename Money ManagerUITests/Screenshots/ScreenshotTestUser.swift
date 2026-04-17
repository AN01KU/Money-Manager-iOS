//
//  ScreenshotTestUser.swift
//  Money Manager UITests
//
//  Creates a throw-away user for screenshot runs and seeds it with realistic
//  test data. Call `setUp()` before launching the app, `tearDown()` after all
//  screenshots are captured — it deletes the account from the backend.
//

import Foundation
import XCTest

// MARK: - ScreenshotTestUser

final class ScreenshotTestUser {

    // Credentials generated fresh each run so parallel CI lanes can't clash.
    let email: String
    let password = "Screenshot1!"
    let username = "ScreenshotUser"

    private let inviteCode = "ankush@money.manager"
    private var token: String?
    private let baseURL: URL

    init() {
        let shortID = UUID().uuidString.prefix(8).lowercased()
        email = "screenshot_\(shortID)@test.internal"

        let host = Bundle(for: type(of: XCTestCase())).object(forInfoDictionaryKey: "API_BASE_HOST") as? String
                ?? (ProcessInfo.processInfo.environment["API_BASE_HOST"] ?? "")
        baseURL = URL(string: "https://\(host)")!
    }

    // MARK: - Public API

    /// Signs up, seeds test data, returns token for use as a launch argument.
    func setUp() async throws -> String {
        token = try await signUp()
        try await seedTransactions()
        try await seedBudget()
        try await seedRecurring()
        try await seedGroup()
        return token!
    }

    /// Deletes the backend account — call from `tearDownWithError`.
    func tearDown() async {
        guard let token else { return }
        try? await delete("/me", token: token)
    }

    // MARK: - Sign Up

    private func signUp() async throws -> String {
        let body: [String: Any] = [
            "email": email,
            "username": username,
            "password": password,
            "invite_code": inviteCode
        ]
        let response = try await post("/auth/signup", body: body, token: nil)
        guard let token = response["token"] as? String else {
            throw ScreenshotUserError.missingToken
        }
        return token
    }

    // MARK: - Seed Data

    private func seedTransactions() async throws {
        guard let token else { return }
        let now = Date()

        let transactions: [[String: Any]] = [
            // Expenses across categories to make the overview look rich
            ["type": "expense", "amount": 450,    "category": "Food & Dining",        "date": ms(now, daysAgo: 0),  "description": "Dinner with friends"],
            ["type": "expense", "amount": 1200,   "category": "Shopping",             "date": ms(now, daysAgo: 1),  "description": "New headphones"],
            ["type": "expense", "amount": 350,    "category": "Transport",            "date": ms(now, daysAgo: 2),  "description": "Monthly Metro pass"],
            ["type": "expense", "amount": 799,    "category": "Entertainment",        "date": ms(now, daysAgo: 3),  "description": "Movie night"],
            ["type": "expense", "amount": 2500,   "category": "Health & Medical",     "date": ms(now, daysAgo: 4),  "description": "Gym membership"],
            ["type": "expense", "amount": 180,    "category": "Food & Dining",        "date": ms(now, daysAgo: 5),  "description": "Coffee & snacks"],
            ["type": "expense", "amount": 3200,   "category": "Bills & Utilities",    "date": ms(now, daysAgo: 6),  "description": "Electricity bill"],
            ["type": "expense", "amount": 650,    "category": "Shopping",             "date": ms(now, daysAgo: 8),  "description": "Books"],
            ["type": "expense", "amount": 420,    "category": "Food & Dining",        "date": ms(now, daysAgo: 10), "description": "Weekly groceries"],
            ["type": "expense", "amount": 1500,   "category": "Education",            "date": ms(now, daysAgo: 12), "description": "Online course"],
            // Income
            ["type": "income",  "amount": 85000,  "category": "Work & Professional",  "date": ms(now, daysAgo: 1),  "description": "Monthly salary"],
            ["type": "income",  "amount": 5000,   "category": "Work & Professional",  "date": ms(now, daysAgo: 7),  "description": "Freelance project"],
        ]

        for tx in transactions {
            try await post("/transactions", body: tx, token: token)
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    private func seedBudget() async throws {
        guard let token else { return }
        let month = Calendar.current.component(.month, from: Date())
        let year  = Calendar.current.component(.year,  from: Date())
        let body: [String: Any] = ["year": year, "month": month, "limit": 20000]
        try await post("/budgets", body: body, token: token)
    }

    private func seedRecurring() async throws {
        guard let token else { return }
        let startMs = ms(Date(), daysAgo: 0)
        let items: [[String: Any]] = [
            ["name": "Netflix", "amount": 649, "category": "Entertainment",
             "frequency": "monthly", "day_of_month": 5, "start_date": startMs,
             "is_active": true, "type": "expense"],
            ["name": "Gym",     "amount": 2500, "category": "Health & Medical",
             "frequency": "monthly", "day_of_month": 1, "start_date": startMs,
             "is_active": true, "type": "expense"],
        ]
        for item in items {
            try await post("/recurring-transactions", body: item, token: token)
        }
    }

    private func seedGroup() async throws {
        guard let token else { return }
        let groupBody: [String: Any] = ["name": "Goa Trip 🏖️"]
        let groupResponse = try await post("/groups", body: groupBody, token: token)
        guard let groupId = groupResponse["id"] as? String else { return }

        let membersResponse = try await get("/groups/\(groupId)/members", token: token)
        guard let membersData = membersResponse["data"] as? [[String: Any]],
              let memberId = membersData.first?["id"] as? String else { return }

        let txBody: [String: Any] = [
            "paid_by_user_id": memberId,
            "total_amount": 3600,
            "category": "Food & Dining",
            "date": ms(Date(), daysAgo: 1),
            "description": "Beach dinner",
            "splits": [["user_id": memberId, "amount": 3600]]
        ]
        try await post("/groups/\(groupId)/transactions", body: txBody, token: token)
    }

    // MARK: - HTTP Helpers

    @discardableResult
    private func post(_ path: String, body: [String: Any], token: String?) async throws -> [String: Any] {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data, path: path)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func get(_ path: String, token: String) async throws -> [String: Any] {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data, path: path)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func delete(_ path: String, token: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data, path: path)
    }

    private func validate(_ response: URLResponse, data: Data, path: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ScreenshotUserError.invalidResponse(path)
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ScreenshotUserError.httpError(path, http.statusCode, body)
        }
    }

    // MARK: - Helpers

    /// Current time offset by `daysAgo` days, as milliseconds since epoch.
    private func ms(_ base: Date, daysAgo: Int) -> Int64 {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: base) ?? base
        return Int64(date.timeIntervalSince1970 * 1000)
    }
}

// MARK: - Errors

private enum ScreenshotUserError: LocalizedError {
    case missingToken
    case invalidResponse(String)
    case httpError(String, Int, String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Sign-up response did not contain a token"
        case .invalidResponse(let path):
            return "Non-HTTP response for \(path)"
        case .httpError(let path, let status, let body):
            return "HTTP \(status) for \(path): \(body)"
        }
    }
}
