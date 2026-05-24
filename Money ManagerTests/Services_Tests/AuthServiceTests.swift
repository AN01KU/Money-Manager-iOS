import Foundation
import Testing
@testable import Money_Manager

@Suite(.serialized)
@MainActor
struct AuthServiceTests {

    private func makeUser(
        id: UUID = UUID(),
        email: String = "user@example.com",
        username: String = "User",
        currency: String = "INR"
    ) -> APIUser {
        APIUser(
            id: id,
            email: email,
            username: username,
            emailVerified: true,
            currency: currency,
            timezone: "UTC",
            createdAt: Date()
        )
    }

    private func makeAuthResponse(user: APIUser) -> APIAuthResponse {
        APIAuthResponse(token: "test-token", syncSessionId: UUID(), user: user)
    }

    private func makeService() -> (svc: AuthService, mock: MockAPIClient, session: SessionStore) {
        let mock = MockAPIClient()
        let session = SessionStore()
        session.tokenStorage = InMemoryTokenStorage()
        let svc = AuthService.shared
        svc.apiClient = mock
        svc.session = session
        svc.authState = .unknown
        svc.hasCheckedAuth = false
        svc.errorMessage = nil
        return (svc, mock, session)
    }

    @Test
    func testLogin_withValidCredentials_storesTokenAndAuthenticates() async throws {
        let (svc, mock, session) = makeService()
        let user = makeUser()
        let response = makeAuthResponse(user: user)
        mock.postHandler = { _, _ in response }

        try await svc.login(email: "user@example.com", password: "pass")

        #expect(session.isLoggedIn)
        #expect(session.getToken() == "test-token")
        if case .authenticated(let u) = svc.authState {
            #expect(u.id == user.id)
        } else {
            Issue.record("Expected .authenticated")
        }
    }

    @Test
    func testLogin_withInvalidCredentials_doesNotStoreTokenAndSetsErrorMessage() async throws {
        let (svc, mock, session) = makeService()
        mock.postHandler = { _, _ in throw APIError.unauthorized }

        do {
            try await svc.login(email: "user@example.com", password: "wrong")
            Issue.record("Expected login to throw")
        } catch {
            #expect(!session.isLoggedIn)
            #expect(svc.errorMessage != nil)
        }
    }

    @Test
    func testLogin_withInvalidCredentials_authStateRemainsUnchanged() async throws {
        let (svc, mock, _) = makeService()
        svc.authState = .guest
        mock.postHandler = { _, _ in throw APIError.unauthorized }

        do {
            try await svc.login(email: "user@example.com", password: "wrong")
        } catch {}

        #expect(svc.authState == .guest)
    }

    @Test
    func testSignup_withDifferentUser_postsUserDidSwitchAccountNotification() async throws {
        let (svc, mock, session) = makeService()
        session.saveLastLoggedInEmail("old@example.com")
        let user = makeUser(email: "new@example.com", username: "New")
        let response = makeAuthResponse(user: user)
        mock.postHandler = { _, _ in response }

        var notificationFired = false
        let token = NotificationCenter.default.addObserver(
            forName: .userDidSwitchAccount,
            object: nil,
            queue: .main
        ) { _ in notificationFired = true }
        defer { NotificationCenter.default.removeObserver(token) }

        try await svc.signup(email: "new@example.com", username: "New", password: "pass", inviteCode: "INV")

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(notificationFired)
    }

    @Test
    func testSignup_withSameUser_doesNotPostUserDidSwitchAccountNotification() async throws {
        let (svc, mock, session) = makeService()
        session.saveLastLoggedInEmail("same@example.com")
        let user = makeUser(email: "same@example.com", username: "Same")
        let response = makeAuthResponse(user: user)
        mock.postHandler = { _, _ in response }

        var notificationFired = false
        let token = NotificationCenter.default.addObserver(
            forName: .userDidSwitchAccount,
            object: nil,
            queue: .main
        ) { _ in notificationFired = true }
        defer { NotificationCenter.default.removeObserver(token) }

        try await svc.signup(email: "same@example.com", username: "Same", password: "pass", inviteCode: "INV")

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(!notificationFired)
    }

    @Test
    func testSignup_withDuplicateEmail_surfacesConflictError() async throws {
        let (svc, mock, _) = makeService()
        mock.postHandler = { _, _ in throw APIError.conflict }

        do {
            try await svc.signup(email: "dup@example.com", username: "User", password: "pass", inviteCode: "INV")
            Issue.record("Expected signup to throw")
        } catch let error as APIError {
            #expect(error == .conflict)
            #expect(svc.errorMessage != nil)
        }
    }

    @Test
    func testSignup_withValidData_storesTokenAndAuthenticates() async throws {
        let (svc, mock, session) = makeService()
        let user = makeUser(email: "new@example.com", username: "New")
        let response = makeAuthResponse(user: user)
        mock.postHandler = { _, _ in response }

        try await svc.signup(email: "new@example.com", username: "New", password: "pass", inviteCode: "INV")

        #expect(session.isLoggedIn)
        if case .authenticated(let u) = svc.authState {
            #expect(u.email == "new@example.com")
        } else {
            Issue.record("Expected .authenticated")
        }
    }

    @Test
    func testLogout_clearsStoredTokenAndTransitionsToGuest() async throws {
        let (svc, mock, session) = makeService()
        let user = makeUser()
        let response = makeAuthResponse(user: user)
        mock.postHandler = { _, _ in response }
        try await svc.login(email: "user@example.com", password: "pass")
        mock.postHandler = { _, _ in EmptyResponse() }

        svc.logout()

        #expect(!session.isLoggedIn)
        #expect(svc.authState == .guest)
    }

    @Test
    func testCheckAuthState_withValidStoredToken_transitionsToAuthenticated() async {
        let (svc, mock, session) = makeService()
        session.saveToken("existing-token")
        let user = makeUser()
        mock.getHandler = { _ in user }

        await svc.checkAuthState()

        if case .authenticated(let u) = svc.authState {
            #expect(u.id == user.id)
        } else {
            Issue.record("Expected .authenticated")
        }
        #expect(svc.hasCheckedAuth)
    }

    @Test
    func testCheckAuthState_withNoStoredToken_transitionsToGuest() async {
        let (svc, _, session) = makeService()
        session.clearSession()

        await svc.checkAuthState()

        #expect(svc.authState == .guest)
        #expect(svc.hasCheckedAuth)
    }

    @Test
    func testCheckAuthState_whenTokenRejectedBy401_transitionsToExpiredAndClearsSession() async {
        let (svc, mock, session) = makeService()
        session.saveToken("stale-token")
        mock.getHandler = { _ in throw APIError.unauthorized }

        await svc.checkAuthState()

        #expect(svc.authState == .expired)
        #expect(!session.isLoggedIn)
    }

    @Test
    func testAuthSessionExpiredNotification_triggersLogoutWhenAuthenticated() async throws {
        let (svc, mock, session) = makeService()
        let user = makeUser()
        let response = makeAuthResponse(user: user)
        mock.postHandler = { _, _ in response }
        try await svc.login(email: "user@example.com", password: "pass")
        mock.postHandler = { _, _ in EmptyResponse() }

        NotificationCenter.default.post(name: .authSessionExpired, object: nil)

        // The observer is registered on DispatchQueue.main and enqueues Task { @MainActor in ... }.
        // Wait on DispatchQueue.main to let both the observer block and the inner Task run.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                continuation.resume()
            }
        }

        #expect(svc.authState == .expired)
        #expect(!session.isLoggedIn)
    }

    @Test
    func testUpdateProfile_persistsNewUsernameAndUpdatesAuthState() async throws {
        let (svc, mock, _) = makeService()
        let originalUser = makeUser(username: "Old Name")
        let updatedUser = makeUser(id: originalUser.id, email: originalUser.email, username: "New Name")
        svc.authState = .authenticated(originalUser)
        mock.patchHandler = { _, _ in updatedUser }
        mock.postHandler = { _, _ in EmptyResponse() }

        try await svc.updateProfile(username: "New Name", email: nil, password: nil, currentPassword: nil)

        if case .authenticated(let u) = svc.authState {
            #expect(u.username == "New Name")
        } else {
            Issue.record("Expected .authenticated")
        }
        #expect(mock.patchCalls.count == 1)
        #expect(mock.patchCalls[0].endpoint == .updateMe)
    }

    @Test
    func testUpdateCurrency_storesNewCurrencyCodeInUserDefaultsAndUpdatesAuthState() async throws {
        let (svc, mock, _) = makeService()
        let user = makeUser(currency: "INR")
        let updatedUser = makeUser(id: user.id, email: user.email, username: user.username, currency: "USD")
        svc.authState = .authenticated(user)
        mock.patchHandler = { _, _ in updatedUser }
        defer { UserDefaults.standard.removeObject(forKey: UserDefaults.Keys.selectedCurrency.rawValue) }

        try await svc.updateCurrency("USD")

        #expect(UserDefaults.standard.string(forKey: UserDefaults.Keys.selectedCurrency.rawValue) == "USD")
        if case .authenticated(let u) = svc.authState {
            #expect(u.currency == "USD")
        } else {
            Issue.record("Expected .authenticated")
        }
    }
}
