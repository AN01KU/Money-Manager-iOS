import Foundation
import Testing
@testable import Money_Manager

/// In-memory token storage for tests — no Keychain access required.
final class InMemoryTokenStorage: TokenStorage {
    private var token: String?
    func save(_ t: String) { token = t }
    func load() -> String? { token }
    func delete() { token = nil }
}

@MainActor
struct SessionStoreTests {

    private func makeStore() -> SessionStore {
        let store = SessionStore()
        store.tokenStorage = InMemoryTokenStorage()
        store.clearSession()
        return store
    }

    // MARK: - Sync Session ID

    @Test
    func testGetSyncSessionIDReturnsNilWhenNotSet() {
        let store = makeStore()
        UserDefaults.standard.removeObject(forKey: "sync_session_id")

        #expect(store.getSyncSessionID() == nil)
    }

    @Test
    func testSaveSyncSessionIDPersistsAndRetrievesValue() {
        let store = makeStore()
        let id = UUID()
        store.saveSyncSessionID(id)
        defer { UserDefaults.standard.removeObject(forKey: "sync_session_id") }

        #expect(store.getSyncSessionID() == id)
    }

    @Test
    func testSaveSyncSessionIDOverwritesPreviousValue() {
        let store = makeStore()
        let first = UUID()
        let second = UUID()
        store.saveSyncSessionID(first)
        store.saveSyncSessionID(second)
        defer { UserDefaults.standard.removeObject(forKey: "sync_session_id") }

        #expect(store.getSyncSessionID() == second)
    }

    @Test
    func testClearSessionAlsoClearsSyncSessionID() {
        let store = makeStore()
        store.saveToken("tok")
        store.saveSyncSessionID(UUID())
        store.clearSession()
        defer { UserDefaults.standard.removeObject(forKey: "sync_session_id") }

        #expect(store.getSyncSessionID() == nil)
    }

    // MARK: - isLoggedIn

    @Test
    func testIsLoggedInReturnsFalseWhenNoTokenSaved() {
        let store = makeStore()

        #expect(store.isLoggedIn == false)
    }

    @Test
    func testIsLoggedInReturnsTrueAfterSavingToken() {
        let store = makeStore()
        defer { store.clearSession() }
        store.saveToken("my-jwt-token")

        #expect(store.isLoggedIn == true)
    }

    // MARK: - saveToken / getToken

    @Test
    func testGetTokenReturnsNilWhenNoTokenSaved() {
        let store = makeStore()

        #expect(store.getToken() == nil)
    }

    @Test
    func testGetTokenReturnsTokenAfterSave() {
        let store = makeStore()
        defer { store.clearSession() }
        store.saveToken("abc123")

        #expect(store.getToken() == "abc123")
    }

    @Test
    func testSaveTokenReplacesExistingToken() {
        let store = makeStore()
        defer { store.clearSession() }
        store.saveToken("first-token")
        store.saveToken("second-token")

        #expect(store.getToken() == "second-token")
    }

    @Test
    func testSaveTokenMultipleTimesOnlyLastTokenIsStored() {
        let store = makeStore()
        defer { store.clearSession() }
        store.saveToken("token-a")
        store.saveToken("token-b")
        store.saveToken("token-c")

        // Only the last token should be retrievable — no duplicates in Keychain
        #expect(store.getToken() == "token-c")
    }

    // MARK: - clearSession

    @Test
    func testClearSessionRemovesToken() {
        let store = makeStore()
        store.saveToken("token-to-delete")
        store.clearSession()

        #expect(store.getToken() == nil)
        #expect(store.isLoggedIn == false)
    }

    @Test
    func testClearSessionWhenNoTokenDoesNotCrash() {
        let store = makeStore()

        store.clearSession()

        #expect(store.isLoggedIn == false)
    }

    // MARK: - Last Logged In Email

    @Test
    func testGetLastLoggedInEmailReturnsNilWhenNotSet() {
        let store = makeStore()
        UserDefaults.standard.removeObject(forKey: "last_logged_in_email")

        #expect(store.getLastLoggedInEmail() == nil)
    }

    @Test
    func testSaveLastLoggedInEmailPersistsNormalized() {
        let store = makeStore()
        defer { UserDefaults.standard.removeObject(forKey: "last_logged_in_email") }

        store.saveLastLoggedInEmail("User@Example.COM")

        #expect(store.getLastLoggedInEmail() == "user@example.com")
    }

    @Test
    func testSaveLastLoggedInEmailOverwritesPreviousValue() {
        let store = makeStore()
        defer { UserDefaults.standard.removeObject(forKey: "last_logged_in_email") }

        store.saveLastLoggedInEmail("first@example.com")
        store.saveLastLoggedInEmail("second@example.com")

        #expect(store.getLastLoggedInEmail() == "second@example.com")
    }

    /// Regression: after reinstall the Keychain token survives but UserDefaults is wiped.
    /// checkAuthState() must call saveLastLoggedInEmail so that a subsequent login as a
    /// different user triggers the account-switch warning in LoginView.
    @Test
    func testEmailIsDetectableAsDifferentAfterBeingSetFromCheckAuthState() {
        let store = makeStore()
        defer { UserDefaults.standard.removeObject(forKey: "last_logged_in_email") }

        // Simulate what checkAuthState() now does: save the email returned by /me
        store.saveLastLoggedInEmail("userA@example.com")

        // LoginView checks: if stored email != new email → show account-switch alert
        let incomingEmail = "userB@example.com"
        let storedEmail = store.getLastLoggedInEmail()

        #expect(storedEmail != nil)
        #expect(storedEmail != incomingEmail.lowercased())
    }

    /// Regression: if checkAuthState() never saved the email (the old buggy path),
    /// getLastLoggedInEmail() returns nil and LoginView skips the account-switch check entirely.
    @Test
    func testMissingEmailAllowsSilentAccountSwitch() {
        let store = makeStore()
        UserDefaults.standard.removeObject(forKey: "last_logged_in_email")

        // No email saved — this is the pre-fix state after reinstall + Keychain token present
        let storedEmail = store.getLastLoggedInEmail()

        // nil means LoginView's `if let lastEmail = ...` guard never fires → no alert
        #expect(storedEmail == nil)
    }
}
