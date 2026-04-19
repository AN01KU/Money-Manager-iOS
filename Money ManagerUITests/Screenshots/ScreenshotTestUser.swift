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

    let email: String
    let password = "Screenshot1!"
    let username = "ScreenshotUser"

    private let inviteCode = "ankush@money.manager"
    private var token: String?
    private var groupId: String?
    // Second member created for realistic group splits — deleted after the run.
    private var memberToken: String?
    private let baseURL: URL

    init() {
        let shortID = UUID().uuidString.prefix(8).lowercased()
        email = "screenshot_\(shortID)@test.internal"

        let env = ProcessInfo.processInfo.environment
        let host = Bundle(for: type(of: XCTestCase())).object(forInfoDictionaryKey: "API_BASE_HOST") as? String
                ?? env["API_BASE_HOST"]
                ?? env["TEST_RUNNER_API_BASE_HOST"]
                ?? "moneymanager.ankushganesh.cloud"
        baseURL = URL(string: "https://\(host)")!
    }

    // MARK: - Public API

    func setUp() async throws -> String {
        token = try await signUp(email: email, username: username)
        try await seedCategories()
        try await seedTransactions()
        try await seedBudgets()
        try await seedRecurring()
        try await seedGroup()
        return token!
    }

    /// Deletes group first (backend blocks account deletion for group creators), then both accounts.
    func tearDown() async {
        guard let token else { return }
        if let groupId {
            try? await delete("/groups/\(groupId)", token: token)
        }
        if let memberToken {
            try? await delete("/me", token: memberToken)
        }
        try? await delete("/me", token: token)
    }

    // MARK: - Sign Up

    private func signUp(email: String, username: String) async throws -> String {
        let body: [String: Any] = [
            "email": email,
            "username": username,
            "password": password,
            "invite_code": inviteCode
        ]
        let response = try await post("/auth/signup", body: body, token: nil)
        guard let t = response["token"] as? String else {
            throw ScreenshotUserError.missingToken
        }
        return t
    }

    // MARK: - Seed: Custom Categories

    private func seedCategories() async throws {
        guard let token else { return }
        // Two custom categories so the "Your Categories" section is populated.
        let categories: [[String: Any]] = [
            ["name": "Subscriptions", "icon": "antenna.radiowaves.left.and.right", "color": "#AF52DE"],
            ["name": "Investments",   "icon": "chart.line.uptrend.xyaxis",         "color": "#30B0C7"],
        ]
        for cat in categories {
            try await post("/categories", body: cat, token: token)
        }
    }

    // MARK: - Seed: Transactions

    private func seedTransactions() async throws {
        guard let token else { return }
        let now = Date()

        let transactions: [[String: Any]] = [
            // Current month — expenses across categories for a rich overview
            ["type": "expense", "amount": 450,   "category": "Food & Dining",     "date": ms(now, daysAgo: 0),  "description": "Dinner with friends"],
            ["type": "expense", "amount": 1200,  "category": "Shopping",          "date": ms(now, daysAgo: 1),  "description": "New headphones"],
            ["type": "expense", "amount": 350,   "category": "Transport",         "date": ms(now, daysAgo: 2),  "description": "Monthly Metro pass"],
            ["type": "expense", "amount": 799,   "category": "Entertainment",     "date": ms(now, daysAgo: 3),  "description": "Movie night"],
            ["type": "expense", "amount": 2500,  "category": "Health & Medical",  "date": ms(now, daysAgo: 4),  "description": "Gym membership"],
            ["type": "expense", "amount": 180,   "category": "Food & Dining",     "date": ms(now, daysAgo: 5),  "description": "Coffee & snacks"],
            ["type": "expense", "amount": 3200,  "category": "Bills & Utilities", "date": ms(now, daysAgo: 6),  "description": "Electricity bill"],
            ["type": "expense", "amount": 649,   "category": "Subscriptions",     "date": ms(now, daysAgo: 7),  "description": "Netflix"],
            ["type": "expense", "amount": 650,   "category": "Shopping",          "date": ms(now, daysAgo: 8),  "description": "Books"],
            ["type": "expense", "amount": 5000,  "category": "Investments",       "date": ms(now, daysAgo: 9),  "description": "SIP — Index Fund"],
            ["type": "expense", "amount": 420,   "category": "Food & Dining",     "date": ms(now, daysAgo: 10), "description": "Weekly groceries"],
            ["type": "expense", "amount": 1500,  "category": "Education",         "date": ms(now, daysAgo: 12), "description": "Online course"],
            // Income
            ["type": "income",  "amount": 85000, "category": "Work & Professional", "date": ms(now, daysAgo: 1), "description": "Monthly salary"],
            ["type": "income",  "amount": 5000,  "category": "Work & Professional", "date": ms(now, daysAgo: 7), "description": "Freelance project"],
        ]

        for tx in transactions {
            try await post("/transactions", body: tx, token: token)
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    // MARK: - Seed: Budgets

    private func seedBudgets() async throws {
        guard let token else { return }
        let cal = Calendar.current
        let now = Date()
        let currentMonth = cal.component(.month, from: now)
        let currentYear  = cal.component(.year,  from: now)

        // Current month budget — spending is ~₹16,000 against ₹20,000 limit (80%) for a meaningful bar.
        let budgets: [(month: Int, year: Int, limit: Int)] = [
            (currentMonth, currentYear, 20000),
            (previousMonth(from: now, offset: 1), previousYear(from: now, offset: 1), 18000),
            (previousMonth(from: now, offset: 2), previousYear(from: now, offset: 2), 18000),
        ]
        for b in budgets {
            let body: [String: Any] = ["year": b.year, "month": b.month, "limit": b.limit]
            try await post("/budgets", body: body, token: token)
        }
    }

    // MARK: - Seed: Recurring Transactions

    private func seedRecurring() async throws {
        guard let token else { return }
        let startMs = ms(Date(), daysAgo: 0)
        let items: [[String: Any]] = [
            ["name": "Netflix",    "amount": 649,  "category": "Subscriptions",    "type": "expense",
             "frequency": "monthly", "day_of_month": 5,  "start_date": startMs, "is_active": true],
            ["name": "Gym",        "amount": 2500, "category": "Health & Medical", "type": "expense",
             "frequency": "monthly", "day_of_month": 1,  "start_date": startMs, "is_active": true],
            ["name": "SIP",        "amount": 5000, "category": "Investments",      "type": "expense",
             "frequency": "monthly", "day_of_month": 10, "start_date": startMs, "is_active": true],
            ["name": "Salary",     "amount": 85000, "category": "Work & Professional", "type": "income",
             "frequency": "monthly", "day_of_month": 1,  "start_date": startMs, "is_active": true],
        ]
        for item in items {
            try await post("/recurring-transactions", body: item, token: token)
        }
    }

    // MARK: - Seed: Group with Real Member & Unsettled Balance

    private func seedGroup() async throws {
        guard let token else { return }

        // Create a second throwaway user to be the group member.
        let shortID = UUID().uuidString.prefix(8).lowercased()
        let memberEmail = "screenshot_member_\(shortID)@test.internal"
        memberToken = try await signUp(email: memberEmail, username: "Rahul")

        // Create the group.
        let groupResponse = try await post("/groups", body: ["name": "Goa Trip 🏖️"], token: token)
        guard let gid = groupResponse["id"] as? String else { return }
        groupId = gid

        // Invite the second user so the Members tab shows 2 people.
        try await post("/groups/\(gid)/add-member", body: ["email": memberEmail], token: token)

        // Fetch members to resolve UUIDs for the split.
        let membersResponse = try await get("/groups/\(gid)/members", token: token)
        guard let membersData = membersResponse["data"] as? [[String: Any]],
              membersData.count >= 2 else { return }

        let payerId = membersData[0]["id"] as? String ?? ""
        let otherId = membersData[1]["id"] as? String ?? ""

        // Two transactions so the list is non-trivial.
        let txs: [[String: Any]] = [
            [
                "paid_by_user_id": payerId,
                "total_amount": 3600,
                "category": "Food & Dining",
                "date": ms(Date(), daysAgo: 1),
                "description": "Beach dinner",
                "splits": [
                    ["user_id": payerId, "amount": 1800],
                    ["user_id": otherId, "amount": 1800],
                ]
            ],
            [
                "paid_by_user_id": payerId,
                "total_amount": 2400,
                "category": "Transport",
                "date": ms(Date(), daysAgo: 3),
                "description": "Cab to airport",
                "splits": [
                    ["user_id": payerId, "amount": 1200],
                    ["user_id": otherId, "amount": 1200],
                ]
            ],
        ]
        for tx in txs {
            try await post("/groups/\(gid)/transactions", body: tx, token: token)
        }
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

    // MARK: - Date Helpers

    private func ms(_ base: Date, daysAgo: Int) -> Int64 {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: base) ?? base
        return Int64(date.timeIntervalSince1970 * 1000)
    }

    private func previousMonth(from date: Date, offset: Int) -> Int {
        let cal = Calendar.current
        let shifted = cal.date(byAdding: .month, value: -offset, to: date) ?? date
        return cal.component(.month, from: shifted)
    }

    private func previousYear(from date: Date, offset: Int) -> Int {
        let cal = Calendar.current
        let shifted = cal.date(byAdding: .month, value: -offset, to: date) ?? date
        return cal.component(.year, from: shifted)
    }
}

// MARK: - Errors

private enum ScreenshotUserError: LocalizedError {
    case missingToken
    case invalidResponse(String)
    case httpError(String, Int, String)

    var errorDescription: String? {
        switch self {
        case .missingToken:                           return "Sign-up response did not contain a token"
        case .invalidResponse(let path):              return "Non-HTTP response for \(path)"
        case .httpError(let path, let status, let b): return "HTTP \(status) for \(path): \(b)"
        }
    }
}
