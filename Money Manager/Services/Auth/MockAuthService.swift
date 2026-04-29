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

    var authState: AuthState = .authenticated(mockUser)
    var hasCheckedAuth: Bool = true
    var isLoading: Bool = false
    var errorMessage: String?

    private init() {}

    func checkAuthState() async {
        authState = .authenticated(mockUser)
        hasCheckedAuth = true
    }

    func login(email: String, password: String) async throws {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
        authState = .authenticated(mockUser)
    }

    func signup(email: String, username: String, password: String, inviteCode: String) async throws {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
        authState = .authenticated(APIUser(id: UUID(), email: email, username: username, emailVerified: false, currency: "INR", timezone: TimeZone.current.identifier, createdAt: Date()))
    }

    func verifyEmail(code: String) async throws {
        try? await Task.sleep(nanoseconds: 300_000_000)
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
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    func updateProfile(username: String?, email: String?, password: String?) async throws {
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
    }

    func updateCurrency(_ code: String) async throws {
        if case .authenticated(let user) = authState {
            UserDefaults.standard.set(code, forKey: "selectedCurrency")
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
    }

    func logout() {
        authState = .guest
    }
}
#endif
