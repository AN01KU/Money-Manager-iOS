//
//  AuthServiceProtocol.swift
//  Money Manager
//

import Foundation

protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    var hasCheckedAuth: Bool { get }
    var currentUser: APIUser? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func checkAuthState() async
    func login(email: String, password: String) async throws
    func signup(email: String, username: String, password: String) async throws
    func logout()
}
