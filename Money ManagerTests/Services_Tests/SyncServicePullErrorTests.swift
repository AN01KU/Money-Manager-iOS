import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests that recordSyncError() is called on failure for each pull method.
@MainActor
@Suite(.serialized)
struct SyncServicePullErrorTests {

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    private func makeSyncService(container: ModelContainer, mock: MockAPIClient) -> SyncService {
        let svc = SyncService(changeQueue: NoOpChangeQueue())
        MockAuthService.shared.reset()
        svc.configure(container: container, authService: MockAuthService.shared)
        svc.apiClient = mock
        return svc
    }

    // MARK: - pullPredefinedCategories increments syncFailureCount on error

    @Test
    func testPullPredefinedCategories_onFailure_incrementsSyncFailureCount() async throws {
        let container = try makeContainer()
        let mock = MockAPIClient()
        mock.getHandler = { endpoint in
            switch endpoint {
            case .predefinedCategories:
                throw MockAPIClient.MockError.notConfigured
            case .syncCategories:
                return APIListResponse<APICategory>(data: [])
            case .getBudget:
                return APIUserBudget(limit: nil)
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
        mock.postHandler = { _, _ in APISyncPreflightResponse(valid: true, reason: nil) }
        let svc = makeSyncService(container: container, mock: mock)

        SessionStore.shared.saveSyncSessionID(UUID())
        defer { SessionStore.shared.clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(svc.syncFailureCount == 1)
    }

    // MARK: - pullCategories increments syncFailureCount on error

    @Test
    func testPullCategories_onFailure_incrementsSyncFailureCount() async throws {
        let container = try makeContainer()
        let mock = MockAPIClient()
        mock.getHandler = { endpoint in
            switch endpoint {
            case .predefinedCategories:
                return APIListResponse<APIPredefinedCategory>(data: [])
            case .syncCategories:
                throw MockAPIClient.MockError.notConfigured
            case .getBudget:
                return APIUserBudget(limit: nil)
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
        mock.postHandler = { _, _ in APISyncPreflightResponse(valid: true, reason: nil) }
        let svc = makeSyncService(container: container, mock: mock)

        SessionStore.shared.saveSyncSessionID(UUID())
        defer { SessionStore.shared.clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(svc.syncFailureCount == 1)
    }

    // MARK: - No error: syncFailureCount stays zero

    @Test
    func testPullPredefinedCategories_onSuccess_doesNotIncrementSyncFailureCount() async throws {
        let container = try makeContainer()
        let mock = MockAPIClient()
        mock.getHandler = { endpoint in
            switch endpoint {
            case .predefinedCategories:
                return APIListResponse<APIPredefinedCategory>(data: [])
            case .syncCategories:
                return APIListResponse<APICategory>(data: [])
            case .getBudget:
                return APIUserBudget(limit: nil)
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
        mock.postHandler = { _, _ in APISyncPreflightResponse(valid: true, reason: nil) }
        let svc = makeSyncService(container: container, mock: mock)

        SessionStore.shared.saveSyncSessionID(UUID())
        defer { SessionStore.shared.clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(svc.syncFailureCount == 0)
    }
}

// MARK: - Stub

private final class NoOpChangeQueue: ChangeQueueManagerProtocol {
    var pendingCount: Int { 0 }
    var failedCount: Int { 0 }
    func configure(container: ModelContainer) {}
    func enqueue(
        entityType: String, entityID: UUID, action: String,
        endpoint: String, httpMethod: String, payload: Data?,
        context: ModelContext
    ) {}
    func replayAll(context: ModelContext, isAuthenticated: Bool) async {}
    func clearAll(context: ModelContext) {}
    func orphanAll(context: ModelContext) {}
    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext) {}
    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: String, context: ModelContext) {}
}
