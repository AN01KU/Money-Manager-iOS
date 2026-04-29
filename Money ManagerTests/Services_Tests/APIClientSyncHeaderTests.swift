//
//  APIClientSyncHeaderTests.swift
//  Money ManagerTests
//

import Foundation
import Testing
@testable import Money_Manager

/// Tests that SyncSessionInterceptor attaches the correct sync headers on write requests.
@MainActor
struct APIClientSyncHeaderTests {

    // MARK: - Helper

    private func makeRequest(method: String, path: String = "/transactions") -> URLRequest {
        var request = URLRequest(url: URL(string: "https://example.com\(path)")!)
        request.httpMethod = method
        return request
    }

    private func adapted(_ request: URLRequest, syncSessionID: UUID?) async throws -> URLRequest {
        // Set up SessionStore state
        UserDefaults.standard.removeObject(forKey: "sync_session_id")
        if let id = syncSessionID {
            SessionStore.shared.saveSyncSessionID(id)
        }
        return try await SyncSessionInterceptor().adapt(request)
    }

    // MARK: - Tests

    @Test
    func testPostRequestIncludesSyncSessionIDWhenSet() async throws {
        let id = UUID()
        let request = try await adapted(makeRequest(method: "POST"), syncSessionID: id)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == id.uuidString)
    }

    @Test
    func testPostRequestIncludesSyncVersionWhenSessionSet() async throws {
        let request = try await adapted(makeRequest(method: "POST"), syncSessionID: UUID())
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == "1")
    }

    @Test
    func testGetRequestDoesNotIncludeSyncSessionIDHeader() async throws {
        let request = try await adapted(makeRequest(method: "GET"), syncSessionID: UUID())
        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == nil)
    }

    @Test
    func testGetRequestDoesNotIncludeSyncVersionHeader() async throws {
        let request = try await adapted(makeRequest(method: "GET"), syncSessionID: UUID())
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == nil)
    }

    @Test
    func testPostRequestOmitsSyncHeadersWhenNoSessionIDSet() async throws {
        let request = try await adapted(makeRequest(method: "POST"), syncSessionID: nil)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == nil)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == nil)
    }

    @Test
    func testPutRequestIncludesSyncHeadersWhenSessionSet() async throws {
        let id = UUID()
        let request = try await adapted(makeRequest(method: "PUT", path: "/budgets/1"), syncSessionID: id)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == id.uuidString)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == "1")
    }

    @Test
    func testDeleteRequestIncludesSyncHeadersWhenSessionSet() async throws {
        let id = UUID()
        let request = try await adapted(makeRequest(method: "DELETE", path: "/transactions/1"), syncSessionID: id)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Session-ID") == id.uuidString)
        #expect(request.value(forHTTPHeaderField: "X-Sync-Version") == "1")
    }
}
