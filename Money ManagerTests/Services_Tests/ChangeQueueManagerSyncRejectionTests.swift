//
//  ChangeQueueManagerSyncRejectionTests.swift
//  Money ManagerTests
//

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests that ChangeQueueManager correctly handles a 409 syncSessionInvalid error
/// received mid-replay: stops the batch, orphans remaining changes, and posts notification.
///
/// Strategy: use a URLProtocol stub that always returns a 409 with a
/// SYNC_SESSION_MISMATCH body. Register it on the APIClient test session so
/// any POST from replayAll hits the stub.
@MainActor
struct ChangeQueueManagerSyncRejectionTests {

    // MARK: - 409 Stub

    final class SessionMismatchProtocol: URLProtocol, @unchecked Sendable {
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let body = #"{"valid":false,"reason":"SYNC_SESSION_MISMATCH"}"#.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 409,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PendingChange.self, OrphanedChange.self, FailedChange.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func insertPendingChange(in context: ModelContext, endpoint: String = "/transactions") -> PendingChange {
        let payload = "{}".data(using: .utf8)!
        let change = PendingChange(
            entityType: "transaction",
            entityID: UUID(),
            action: "create",
            endpoint: endpoint,
            httpMethod: "POST",
            payload: payload
        )
        context.insert(change)
        try? context.save()
        return change
    }

    // MARK: - Tests

    @Test
    func testReplayAllOrphansRemainingChangesOnSyncSessionInvalid() async throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()

        // Insert two pending changes
        _ = insertPendingChange(in: context)
        _ = insertPendingChange(in: context)

        // Configure APIClient to return 409 SYNC_SESSION_MISMATCH for all requests
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SessionMismatchProtocol.self]
        let testSession = URLSession(configuration: config)
        let client = APIClient.makeForTesting(session: testSession)
        client.setTestToken("tok")

        // Inject the test client into ChangeQueueManager
        manager.setAPIClientForTesting(client)

        await manager.replayAll(context: context, isAuthenticated: true)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(pending.isEmpty)
        #expect(orphaned.count == 2)
    }

    @Test
    func testReplayAllPostsSyncSessionOrphanedNotificationOnRejection() async throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        _ = insertPendingChange(in: context)

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SessionMismatchProtocol.self]
        let testSession = URLSession(configuration: config)
        let client = APIClient.makeForTesting(session: testSession)
        client.setTestToken("tok")
        manager.setAPIClientForTesting(client)

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .syncSessionOrphaned,
            object: nil,
            queue: .main
        ) { _ in notificationReceived = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        await manager.replayAll(context: context, isAuthenticated: true)
        await Task.yield()

        #expect(notificationReceived == true)
    }
}
