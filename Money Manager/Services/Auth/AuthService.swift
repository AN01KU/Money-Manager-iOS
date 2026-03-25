//
//  AuthService.swift
//  Money Manager
//

import Foundation

@Observable
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    var isAuthenticated: Bool = false
    var hasCheckedAuth: Bool = false
    var currentUser: APIUser?
    var isLoading: Bool = false
    var errorMessage: String?

    private let session = SessionStore.shared
    private let apiClient = APIClient.shared

    nonisolated(unsafe) private var sessionExpiredObserver: Any?

    private init() {
        sessionExpiredObserver = NotificationCenter.default.addObserver(
            forName: .authSessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isAuthenticated else { return }
            Task { @MainActor in
                self.logout()
            }
        }
    }

    deinit {
        if let observer = sessionExpiredObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @MainActor
    func checkAuthState() async {
        guard session.isLoggedIn else {
            hasCheckedAuth = true
            return
        }
        do {
            let user: APIUser = try await apiClient.get("/me")
            currentUser = user
            isAuthenticated = true
        } catch {
            // Token is invalid or server unreachable — keep authenticated if token exists
            isAuthenticated = session.isLoggedIn
        }
        hasCheckedAuth = true
    }

    @MainActor
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let request = APILoginRequest(email: email, password: password)
            let response: APIAuthResponse = try await apiClient.post("/auth/login", body: request)
            session.saveToken(response.token)
            currentUser = response.user
            isAuthenticated = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            throw error
        }
    }

    @MainActor
    func signup(email: String, username: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let request = APISignupRequest(email: email, username: username, password: password)
            let response: APIAuthResponse = try await apiClient.post("/auth/signup", body: request)
            session.saveToken(response.token)
            currentUser = response.user
            isAuthenticated = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            throw error
        }
    }

    @MainActor
    func logout() {
        session.clearSession()
        UserDefaults.standard.removeObject(forKey: "last_sync_at")
        syncService.clearGroupData()
        currentUser = nil
        isAuthenticated = false
    }
}
