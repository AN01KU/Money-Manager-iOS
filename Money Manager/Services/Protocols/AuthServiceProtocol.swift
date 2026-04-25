//
//  AuthServiceProtocol.swift
//  Money Manager
//

import Foundation
import Observation

enum AuthState: Equatable {
    case unknown
    case guest
    case authenticated(APIUser)
    case expired

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.guest, .guest), (.expired, .expired): return true
        case (.authenticated(let a), .authenticated(let b)): return a.id == b.id
        default: return false
        }
    }
}

protocol AuthServiceProtocol: AnyObject, Observable {
    var authState: AuthState { get }
    var hasCheckedAuth: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    // Convenience accessors
    var isAuthenticated: Bool { get }
    var currentUser: APIUser? { get }

    func checkAuthState() async
    func login(email: String, password: String) async throws
    func signup(email: String, username: String, password: String, inviteCode: String) async throws
    func verifyEmail(code: String) async throws
    func resendVerification() async throws
    func updateProfile(username: String?, email: String?, password: String?) async throws
    func updateCurrency(_ code: String) async throws
    func logout()
}

extension AuthServiceProtocol {
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }
    var currentUser: APIUser? {
        if case .authenticated(let user) = authState { return user }
        return nil
    }
}
