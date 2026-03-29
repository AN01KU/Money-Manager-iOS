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
    created_at: Date()
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

    func signup(email: String, username: String, password: String) async throws {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
        authState = .authenticated(APIUser(id: UUID(), email: email, username: username, created_at: Date()))
    }

    func logout() {
        authState = .guest
    }
}
#endif
