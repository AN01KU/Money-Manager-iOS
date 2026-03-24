//
//  MockAuthService.swift
//  Money Manager
//

#if DEBUG
import Foundation

@Observable
final class MockAuthService: AuthServiceProtocol {
    static let shared = MockAuthService()

    var isAuthenticated: Bool = true
    var hasCheckedAuth: Bool = true
    var currentUser: APIUser? = APIUser(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        email: "test@example.com",
        username: "Test User",
        created_at: Date()
    )
    var isLoading: Bool = false
    var errorMessage: String?

    private init() {}

    func checkAuthState() async {
        isAuthenticated = true
        hasCheckedAuth = true
    }

    func login(email: String, password: String) async throws {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
        isAuthenticated = true
    }

    func signup(email: String, username: String, password: String) async throws {
        isLoading = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
        isAuthenticated = true
        currentUser = APIUser(
            id: UUID(),
            email: email,
            username: username,
            created_at: Date()
        )
    }

    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
}
#endif
