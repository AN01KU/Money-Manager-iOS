//
//  APIClientSyncHeaderTests.swift
//  Money ManagerTests
//

import Foundation
import Testing
@testable import Money_Manager

/// Tests that APIClient attaches the correct sync headers on write requests.
///
/// Tests `buildRequest` directly to avoid network calls and concurrency issues
/// with shared URLProtocol stubs.
@MainActor
struct APIClientSyncHeaderTests {

    // MARK: - Helper

    private func makeClient(syncSessionID: UUID?) -> APIClient {
        // Ensure shared SessionStore doesn't leak a stale value into the test
        UserDefaults.standard.removeObject(forKey: "sync_session_id")

        let client = APIClient.makeForTesting(session: .shared)
        client.setTestToken("test-jwt")
        client.setTestSyncSessionID(syncSessionID)
        return client
    }

    // MARK: - Tests

    @Test
    func testPostRequestIncludesSyncSessionIDWhenSet() throws {
        let id = UUID()
        let client = makeClient(syncSessionID: id)

        let request = try client.buildRequest(endpoint: "/transactions", method: "POST")

        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == id.uuidString)
    }

    @Test
    func testPostRequestIncludesSyncVersionWhenSessionSet() throws {
        let client = makeClient(syncSessionID: UUID())

        let request = try client.buildRequest(endpoint: "/transactions", method: "POST")

        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == "1")
    }

    @Test
    func testGetRequestDoesNotIncludeSyncSessionIDHeader() throws {
        let client = makeClient(syncSessionID: UUID())

        let request = try client.buildRequest(endpoint: "/transactions", method: "GET")

        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == nil)
    }

    @Test
    func testGetRequestDoesNotIncludeSyncVersionHeader() throws {
        let client = makeClient(syncSessionID: UUID())

        let request = try client.buildRequest(endpoint: "/transactions", method: "GET")

        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == nil)
    }

    @Test
    func testPostRequestOmitsSyncHeadersWhenNoSessionIDSet() throws {
        let client = makeClient(syncSessionID: nil)

        let request = try client.buildRequest(endpoint: "/transactions", method: "POST")

        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == nil)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == nil)
    }

    @Test
    func testPutRequestIncludesSyncHeadersWhenSessionSet() throws {
        let id = UUID()
        let client = makeClient(syncSessionID: id)

        let request = try client.buildRequest(endpoint: "/budgets/1", method: "PUT")

        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == id.uuidString)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == "1")
    }

    @Test
    func testDeleteRequestIncludesSyncHeadersWhenSessionSet() throws {
        let id = UUID()
        let client = makeClient(syncSessionID: id)

        let request = try client.buildRequest(endpoint: "/transactions/1", method: "DELETE")

        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == id.uuidString)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == "1")
    }
}
