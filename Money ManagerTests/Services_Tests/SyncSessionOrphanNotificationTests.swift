//
//  SyncSessionOrphanNotificationTests.swift
//  Money ManagerTests
//

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests that SyncService posts `.syncSessionOrphaned` when preflight returns `.invalid`.
/// The notification must originate from SyncService's invalid-preflight branch —
/// not from a manual NotificationCenter.post in the test.
@MainActor
@Suite(.serialized)
struct SyncSessionOrphanNotificationTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    /// MockAPIClient that returns an invalid preflight response (simulates expired sync session).
    private func mockWithInvalidPreflight() -> MockAPIClient {
        let mock = MockAPIClient()
        mock.postHandler = { _, _ in
            APISyncPreflightResponse(valid: false, reason: "SYNC_SESSION_EXPIRED")
        }
        mock.getHandler = { endpoint in
            switch endpoint {
            case .predefinedCategories:
                return APIListResponse<APIPredefinedCategory>(data: [])
            case .syncCategories:
                return APIListResponse<APICategory>(data: [])
            case .syncBudgets:
                return APIListResponse<APIMonthlyBudget>(data: [])
            case .syncRecurring:
                return APIListResponse<APIRecurringTransaction>(data: [])
            case .syncTransactions:
                return APIPaginatedResponse<APITransaction>(
                    data: [],
                    pagination: .init(limit: 100, offset: 0, total: 0)
                )
            default:
                throw MockAPIClient.MockError.notConfigured
            }
        }
        return mock
    }

    // MARK: - Tests

    /// The notification must fire because SyncService's invalid-preflight branch posts it.
    /// If that branch is removed, this test fails.
    @Test
    func testOrphanAllPostsSyncSessionOrphanedNotification() async throws {
        let container = try makeContainer()
        let mock = mockWithInvalidPreflight()

        let svc = SyncService(changeQueue: ChangeQueueManager())
        MockAuthService.shared.reset()
        svc.configure(container: container, authService: MockAuthService.shared)
        svc.apiClient = mock

        // Store a sync session ID so runPreflight actually calls the API
        SessionStore.shared.saveSyncSessionID(UUID())
        defer { SessionStore.shared.clearSyncSessionID() }

        var received = false
        let observer = NotificationCenter.default.addObserver(
            forName: .syncSessionOrphaned,
            object: nil,
            queue: .main
        ) { _ in received = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        // Drive the invalid-preflight path — SyncService posts .syncSessionOrphaned
        await svc.syncOnLaunch()

        // Give the main queue one cycle to deliver the notification
        await Task.yield()

        #expect(received == true)
    }
}
