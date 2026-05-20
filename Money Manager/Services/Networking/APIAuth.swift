//
//  APIAuth.swift
//  Money Manager
//

import Foundation

struct APIUser: Codable, Sendable {
    let id: UUID
    let email: String
    let username: String
    let emailVerified: Bool
    let currency: String
    let timezone: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case emailVerified = "email_verified"
        case currency
        case timezone
        case createdAt = "created_at"
    }
}

struct APIVerifyEmailRequest: Codable, Sendable {
    let code: String
}

struct APIAuthResponse: Codable, Sendable {
    let token: String
    let syncSessionId: UUID
    let user: APIUser

    enum CodingKeys: String, CodingKey {
        case token
        case syncSessionId = "sync_session_id"
        case user
    }
}

struct APIUpdateMeRequest: Codable, Sendable {
    let username: String?
    let email: String?
    let password: String?
    let currency: String?

    init(username: String? = nil, email: String? = nil, password: String? = nil, currency: String? = nil) {
        self.username = username
        self.email = email?.normalizedEmail
        self.password = password
        self.currency = currency
    }
}

struct APISignupRequest: Codable, Sendable {
    let email: String
    let username: String
    let password: String
    let inviteCode: String
    let timezone: String

    init(email: String, username: String, password: String, inviteCode: String) {
        self.email = email.normalizedEmail
        self.username = username
        self.password = password
        self.inviteCode = inviteCode
        self.timezone = TimeZone.current.identifier
    }

    enum CodingKeys: String, CodingKey {
        case email
        case username
        case password
        case inviteCode = "invite_code"
        case timezone
    }
}

struct APILoginRequest: Codable, Sendable {
    let email: String
    let password: String

    init(email: String, password: String) {
        self.email = email.normalizedEmail
        self.password = password
    }
}

struct APILogoutRequest: Codable, Sendable {
    let syncSessionId: UUID

    enum CodingKeys: String, CodingKey {
        case syncSessionId = "sync_session_id"
    }
}

struct APISyncPreflightRequest: Codable, Sendable {
    let syncSessionId: UUID

    enum CodingKeys: String, CodingKey {
        case syncSessionId = "sync_session_id"
    }
}

struct APISyncPreflightResponse: Codable, Sendable {
    let valid: Bool
    let reason: String?
}
