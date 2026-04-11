//
//  AuthService.swift
//  Money Manager
//

import Foundation

@Observable
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    var authState: AuthState = .unknown
    var hasCheckedAuth: Bool = false
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
                self.authState = .expired
                self.session.clearSession()
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
            AppLogger.auth.info("checkAuthState: no token — setting guest")
            authState = .guest
            hasCheckedAuth = true
            return
        }
        do {
            let user: APIUser = try await apiClient.get("/me")
            AppLogger.auth.info("checkAuthState: authenticated as \(user.email, privacy: .private)")
            session.saveLastLoggedInEmail(user.email.lowercased())
            authState = .authenticated(user)
        } catch let error as APIError where error == .unauthorized {
            AppLogger.auth.warning("checkAuthState: token rejected (401) — clearing session")
            authState = .expired
            session.clearSession()
        } catch {
            // Server unreachable — never degrade an existing token to guest.
            // Leave authState as-is (.unknown or .authenticated) so the UI can
            // show an offline/loading state rather than kicking the user to login.
            if session.isLoggedIn {
                AppLogger.auth.warning("checkAuthState: network error with valid token — keeping \(String(describing: self.authState)) — \(error.localizedDescription)")
            } else {
                authState = .guest
            }
        }
        hasCheckedAuth = true
    }

    @MainActor
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        // If a different user was previously logged in, wipe their local data first
        let normalizedEmail = email.lowercased()
        if let lastEmail = session.getLastLoggedInEmail(), lastEmail != normalizedEmail {
            SyncService.shared.clearAllUserData()
        }

        do {
            let request = APILoginRequest(email: email, password: password)
            let response: APIAuthResponse = try await apiClient.post("/auth/login", body: request)
            session.saveToken(response.token)
            session.saveSyncSessionID(response.syncSessionId)
            session.saveLastLoggedInEmail(normalizedEmail)
            authState = .authenticated(response.user)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            throw error
        }
    }

    @MainActor
    func signup(email: String, username: String, password: String, inviteCode: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let request = APISignupRequest(email: email, username: username, password: password, inviteCode: inviteCode)
            let response: APIAuthResponse = try await apiClient.post("/auth/signup", body: request)
            session.saveToken(response.token)
            session.saveSyncSessionID(response.syncSessionId)
            session.saveLastLoggedInEmail(email.lowercased())
            authState = .authenticated(response.user)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            throw error
        }
    }

    @MainActor
    func logout() {
        let syncSessionID = session.getSyncSessionID()
        session.clearSession()
        UserDefaults.standard.removeObject(forKey: "last_sync_at")
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
        authState = .guest

        if let id = syncSessionID {
            Task {
                let body = APILogoutRequest(syncSessionId: id)
                try? await apiClient.post("/auth/logout", body: body) as EmptyResponse
            }
        }
    }
}
