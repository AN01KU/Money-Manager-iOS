//
//  MockAuthService.swift
//  Money Manager
//

#if DEBUG
import Foundation

private let mockUser = APIUser(
    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
    email: "test@example.com",
    username: "Test User",
    emailVerified: true,
    currency: "INR",
    timezone: TimeZone.current.identifier,
    createdAt: Date()
)

@Observable
final class MockAuthService: AuthServiceProtocol {
    static let shared = MockAuthService()

    enum CallRecord: Equatable {
        case checkAuthState
        case login(email: String, password: String)
        case signup(email: String, username: String, password: String, inviteCode: String)
        case verifyEmail(code: String)
        case resendVerification
        case updateProfile(username: String?, email: String?, password: String?, currentPassword: String?)
        case updateCurrency(String)
        case logout
    }

    var authState: AuthState = .authenticated(mockUser)
    var hasCheckedAuth: Bool = true
    var isLoading: Bool = false
    var errorMessage: String?

    // Stubbable outcomes
    var loginResult: Result<Void, Error> = .success(())
    var signupResult: Result<Void, Error> = .success(())
    var logoutSideEffect: (() -> Void)? = nil
    var checkAuthStateHandler: (() -> AuthState)? = nil
    var updateProfileResult: Result<Void, Error> = .success(())
    var updateCurrencyResult: Result<Void, Error> = .success(())

    private(set) var callLog: [CallRecord] = []

    private init() {}

    func reset() {
        callLog = []
        loginResult = .success(())
        signupResult = .success(())
        logoutSideEffect = nil
        checkAuthStateHandler = nil
        updateProfileResult = .success(())
        updateCurrencyResult = .success(())
        authState = .authenticated(mockUser)
        hasCheckedAuth = true
        isLoading = false
        errorMessage = nil
    }

    func checkAuthState() async {
        callLog.append(.checkAuthState)
        if let handler = checkAuthStateHandler {
            authState = handler()
        } else {
            authState = .authenticated(mockUser)
        }
        hasCheckedAuth = true
    }

    func login(email: String, password: String) async throws {
        callLog.append(.login(email: email, password: password))
        isLoading = true
        defer { isLoading = false }
        switch loginResult {
        case .success:
            authState = .authenticated(mockUser)
        case .failure(let error):
            throw error
        }
    }

    func signup(email: String, username: String, password: String, inviteCode: String) async throws {
        callLog.append(.signup(email: email, username: username, password: password, inviteCode: inviteCode))
        isLoading = true
        defer { isLoading = false }
        switch signupResult {
        case .success:
            authState = .authenticated(APIUser(id: UUID(), email: email, username: username, emailVerified: false, currency: "INR", timezone: TimeZone.current.identifier, createdAt: Date()))
        case .failure(let error):
            throw error
        }
    }

    func verifyEmail(code: String) async throws {
        callLog.append(.verifyEmail(code: code))
        if case .authenticated(let user) = authState {
            authState = .authenticated(APIUser(
                id: user.id,
                email: user.email,
                username: user.username,
                emailVerified: true,
                currency: user.currency,
                timezone: user.timezone,
                createdAt: user.createdAt
            ))
        }
    }

    func resendVerification() async throws {
        callLog.append(.resendVerification)
    }

    func updateProfile(username: String?, email: String?, password: String?, currentPassword: String?) async throws {
        callLog.append(.updateProfile(username: username, email: email, password: password, currentPassword: currentPassword))
        switch updateProfileResult {
        case .success:
            if case .authenticated(let user) = authState {
                authState = .authenticated(APIUser(
                    id: user.id,
                    email: email ?? user.email,
                    username: username ?? user.username,
                    emailVerified: user.emailVerified,
                    currency: user.currency,
                    timezone: user.timezone,
                    createdAt: user.createdAt
                ))
            }
        case .failure(let error):
            throw error
        }
    }

    func updateCurrency(_ code: String) async throws {
        callLog.append(.updateCurrency(code))
        switch updateCurrencyResult {
        case .success:
            UserDefaults.standard.set(code, forKey: "selectedCurrency")
            if case .authenticated(let user) = authState {
                authState = .authenticated(APIUser(
                    id: user.id,
                    email: user.email,
                    username: user.username,
                    emailVerified: user.emailVerified,
                    currency: code,
                    timezone: user.timezone,
                    createdAt: user.createdAt
                ))
            }
        case .failure(let error):
            throw error
        }
    }

    func logout() {
        callLog.append(.logout)
        authState = .guest
        logoutSideEffect?()
    }
}
#endif
