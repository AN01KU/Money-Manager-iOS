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

    // MARK: - isLoggedIn

    @Test
    func test_isLoggedIn_returnsFalse_whenNoTokenSaved() throws {
        let store = try makeStore()

        #expect(store.isLoggedIn == false)
    }

    @Test
    func test_isLoggedIn_returnsTrue_afterSavingToken() throws {
        let store = try makeStore()
        store.saveToken("my-jwt-token")

        #expect(store.isLoggedIn == true)
    }

    // MARK: - saveToken / getToken

    @Test
    func test_getToken_returnsNil_whenNoTokenSaved() throws {
        let store = try makeStore()

        #expect(store.getToken() == nil)
    }

    @Test
    func test_getToken_returnsToken_afterSave() throws {
        let store = try makeStore()
        store.saveToken("abc123")

        #expect(store.getToken() == "abc123")
    }

    @Test
    func test_saveToken_replacesExistingToken() throws {
        let store = try makeStore()
        store.saveToken("first-token")
        store.saveToken("second-token")

        // Only one token should exist and it should be the latest
        #expect(store.getToken() == "second-token")
    }

    @Test
    func test_saveToken_multipleTimes_noDuplicatesExist() throws {
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
    func test_clearSession_removesToken() throws {
        let store = try makeStore()
        store.saveToken("token-to-delete")
        store.clearSession()

        #expect(store.getToken() == nil)
        #expect(store.isLoggedIn == false)
    }

    @Test
    func test_clearSession_whenNoToken_doesNotCrash() throws {
        let store = try makeStore()

        // Should not throw or crash on empty state
        store.clearSession()

        #expect(store.isLoggedIn == false)
    }

    // MARK: - Unconfigured store (no container set)

    @Test
    func test_getToken_returnsNil_whenNotConfigured() {
        let store = SessionStore()
        // No configure() called

        #expect(store.getToken() == nil)
        #expect(store.isLoggedIn == false)
    }

    @Test
    func test_saveToken_doesNotCrash_whenNotConfigured() {
        let store = SessionStore()
        // No configure() called — should silently do nothing

        store.saveToken("some-token")

        #expect(store.getToken() == nil)
    }
}
