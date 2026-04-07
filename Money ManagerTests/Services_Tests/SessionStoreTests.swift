import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct SessionStoreTests {

    private func makeStore() throws -> SessionStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AuthToken.self, configurations: config)
        let store = SessionStore()
        store.configure(container: container)
        return store
    }

    // MARK: - Sync Session ID

    @Test
    func testGetSyncSessionIDReturnsNilWhenNotSet() throws {
        let store = try makeStore()
        UserDefaults.standard.removeObject(forKey: "sync_session_id")

        #expect(store.getSyncSessionID() == nil)
    }

    @Test
    func testSaveSyncSessionIDPersistsAndRetrievesValue() throws {
        let store = try makeStore()
        let id = UUID()
        store.saveSyncSessionID(id)
        defer { UserDefaults.standard.removeObject(forKey: "sync_session_id") }

        #expect(store.getSyncSessionID() == id)
    }

    @Test
    func testSaveSyncSessionIDOverwritesPreviousValue() throws {
        let store = try makeStore()
        let first = UUID()
        let second = UUID()
        store.saveSyncSessionID(first)
        store.saveSyncSessionID(second)
        defer { UserDefaults.standard.removeObject(forKey: "sync_session_id") }

        #expect(store.getSyncSessionID() == second)
    }

    @Test
    func testClearSessionAlsoClearsSyncSessionID() throws {
        let store = try makeStore()
        store.saveToken("tok")
        store.saveSyncSessionID(UUID())
        store.clearSession()
        defer { UserDefaults.standard.removeObject(forKey: "sync_session_id") }

        #expect(store.getSyncSessionID() == nil)
    }

    // MARK: - isLoggedIn

    @Test
    func testIsLoggedInReturnsFalseWhenNoTokenSaved() throws {
        let store = try makeStore()

        #expect(store.isLoggedIn == false)
    }

    @Test
    func testIsLoggedInReturnsTrueAfterSavingToken() throws {
        let store = try makeStore()
        store.saveToken("my-jwt-token")

        #expect(store.isLoggedIn == true)
    }

    // MARK: - saveToken / getToken

    @Test
    func testGetTokenReturnsNilWhenNoTokenSaved() throws {
        let store = try makeStore()

        #expect(store.getToken() == nil)
    }

    @Test
    func testGetTokenReturnsTokenAfterSave() throws {
        let store = try makeStore()
        store.saveToken("abc123")

        #expect(store.getToken() == "abc123")
    }

    @Test
    func testSaveTokenReplacesExistingToken() throws {
        let store = try makeStore()
        store.saveToken("first-token")
        store.saveToken("second-token")

        #expect(store.getToken() == "second-token")
    }

    @Test
    func testSaveTokenMultipleTimesNoDuplicatesExist() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AuthToken.self, configurations: config)
        let store = SessionStore()
        store.configure(container: container)

        store.saveToken("token-a")
        store.saveToken("token-b")
        store.saveToken("token-c")

        let context = container.mainContext
        let all = try context.fetch(FetchDescriptor<AuthToken>())
        #expect(all.count == 1)
        #expect(all.first?.token == "token-c")
    }

    // MARK: - clearSession

    @Test
    func testClearSessionRemovesToken() throws {
        let store = try makeStore()
        store.saveToken("token-to-delete")
        store.clearSession()

        #expect(store.getToken() == nil)
        #expect(store.isLoggedIn == false)
    }

    @Test
    func testClearSessionWhenNoTokenDoesNotCrash() throws {
        let store = try makeStore()

        store.clearSession()

        #expect(store.isLoggedIn == false)
    }

    // MARK: - Unconfigured store (no container set)

    @Test
    func testGetTokenReturnsNilWhenNotConfigured() {
        let store = SessionStore()

        #expect(store.getToken() == nil)
        #expect(store.isLoggedIn == false)
    }

    @Test
    func testSaveTokenDoesNotCrashWhenNotConfigured() {
        let store = SessionStore()

        store.saveToken("some-token")

        #expect(store.getToken() == nil)
    }
}
