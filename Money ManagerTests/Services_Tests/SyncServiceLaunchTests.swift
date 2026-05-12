import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests for SyncService.syncOnLaunch and syncOnReconnect.
/// Uses MockAPIClient + MockAuthService + in-memory SwiftData + SpySyncChangeQueue.
@MainActor
@Suite(.serialized)
struct SyncServiceLaunchTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    /// Builds a SyncService with an injected spy change queue, configured with an
    /// in-memory container + MockAuthService so tests don't hit network or Keychain.
    private func makeSyncService(
        container: ModelContainer,
        changeQueue: SpySyncChangeQueue,
        mock: MockAPIClient
    ) -> SyncService {
        let svc = SyncService(changeQueue: changeQueue)
        MockAuthService.shared.reset()
        svc.configure(container: container, authService: MockAuthService.shared)
        svc.apiClient = mock
        return svc
    }

    /// Returns a MockAPIClient that accepts preflight POST and all GET calls needed by pullFromServer.
    private func mockWithValidPreflight() -> MockAPIClient {
        let mock = MockAPIClient()
        mock.postHandler = { _, _ in
            APISyncPreflightResponse(valid: true, reason: nil)
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

    /// Returns a MockAPIClient whose preflight POST returns invalid.
    private func mockWithInvalidPreflight(reason: String = "SYNC_SESSION_EXPIRED") -> MockAPIClient {
        let mock = MockAPIClient()
        mock.postHandler = { _, _ in
            APISyncPreflightResponse(valid: false, reason: reason)
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

    private func storeSyncSessionID() {
        SessionStore.shared.saveSyncSessionID(UUID())
    }

    private func clearSyncSessionID() {
        SessionStore.shared.clearSyncSessionID()
    }

    // MARK: - syncOnLaunch: valid preflight calls replayAll

    @Test
    func testSyncOnLaunch_withValidPreflight_callsReplayAll() async throws {
        let container = try makeContainer()
        let queue = SpySyncChangeQueue()
        let mock = mockWithValidPreflight()
        let svc = makeSyncService(container: container, changeQueue: queue, mock: mock)

        storeSyncSessionID()
        defer { clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(queue.replayAllCallCount == 1)
    }

    // MARK: - syncOnLaunch: preflight before replayAll (ordering via call log)

    @Test
    func testSyncOnLaunch_withValidPreflight_callsPreflightBeforeReplayAll() async throws {
        let container = try makeContainer()
        let queue = SpySyncChangeQueue()
        let mock = MockAPIClient()
        var callOrder: [String] = []

        mock.postHandler = { endpoint, _ in
            if case .syncPreflight = endpoint {
                callOrder.append("preflight")
            }
            return APISyncPreflightResponse(valid: true, reason: nil)
        }
        mock.getHandler = { endpoint in
            switch endpoint {
            case .predefinedCategories:
                callOrder.append("pull")
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
        queue.onReplayAll = { callOrder.append("replayAll") }

        let svc = makeSyncService(container: container, changeQueue: queue, mock: mock)
        storeSyncSessionID()
        defer { clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(callOrder.first == "preflight")
        #expect(callOrder.contains("replayAll"))
        #expect(callOrder.contains("pull"))
        let replayIdx = callOrder.firstIndex(of: "replayAll") ?? Int.max
        let pullIdx = callOrder.firstIndex(of: "pull") ?? Int.max
        #expect(replayIdx < pullIdx)
    }

    // MARK: - syncOnLaunch: invalid preflight skips replayAll

    @Test
    func testSyncOnLaunch_withInvalidPreflight_doesNotCallReplayAll() async throws {
        let container = try makeContainer()
        let queue = SpySyncChangeQueue()
        let mock = mockWithInvalidPreflight()
        let svc = makeSyncService(container: container, changeQueue: queue, mock: mock)

        storeSyncSessionID()
        defer { clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(queue.replayAllCallCount == 0)
    }

    // MARK: - syncOnLaunch: invalid preflight calls orphanAll

    @Test
    func testSyncOnLaunch_withInvalidPreflight_callsOrphanAll() async throws {
        let container = try makeContainer()
        let queue = SpySyncChangeQueue()
        let mock = mockWithInvalidPreflight()
        let svc = makeSyncService(container: container, changeQueue: queue, mock: mock)

        storeSyncSessionID()
        defer { clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(queue.orphanAllCallCount == 1)
    }

    // MARK: - syncOnLaunch: unauthenticated does nothing

    @Test
    func testSyncOnLaunch_whenNotAuthenticated_doesNotReplay() async throws {
        let container = try makeContainer()
        let queue = SpySyncChangeQueue()
        let mock = mockWithValidPreflight()
        let svc = makeSyncService(container: container, changeQueue: queue, mock: mock)

        MockAuthService.shared.authState = .guest

        storeSyncSessionID()
        defer { clearSyncSessionID() }

        await svc.syncOnLaunch()

        #expect(queue.replayAllCallCount == 0)
    }

    // MARK: - syncOnReconnect: posting notification triggers sync

    @Test
    func testSyncOnReconnect_viaNotification_callsReplayAll() async throws {
        let container = try makeContainer()
        let queue = SpySyncChangeQueue()
        let mock = mockWithValidPreflight()
        let svc = makeSyncService(container: container, changeQueue: queue, mock: mock)

        // Ensure network is marked as connected so syncOnReconnect proceeds
        svc.networkMonitor.isConnected = true
        storeSyncSessionID()
        defer {
            clearSyncSessionID()
            svc.networkMonitor.isConnected = false
        }

        await confirmation("syncOnReconnect called replayAll after notification") { confirm in
            queue.onReplayAll = { confirm() }
            NotificationCenter.default.post(name: .networkDidBecomeAvailable, object: nil)
            // Allow the Task spawned by the notification observer to complete
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        #expect(queue.replayAllCallCount >= 1)
    }
}

// MARK: - Spy

private final class SpySyncChangeQueue: ChangeQueueManagerProtocol {
    var pendingCount: Int { 0 }
    var failedCount: Int { 0 }

    private(set) var replayAllCallCount = 0
    private(set) var orphanAllCallCount = 0
    var onReplayAll: (() -> Void)?

    func configure(container: ModelContainer) {}

    func enqueue(
        entityType: String, entityID: UUID, action: String,
        endpoint: String, httpMethod: String, payload: Data?,
        context: ModelContext
    ) {}

    func replayAll(context: ModelContext, isAuthenticated: Bool) async {
        replayAllCallCount += 1
        onReplayAll?()
    }

    func clearAll(context: ModelContext) {}

    func orphanAll(context: ModelContext) {
        orphanAllCallCount += 1
    }

    func purgeExpiredOrphans(olderThan days: Int, context: ModelContext) {}

    func removeStaleChanges(for entityIDs: Set<UUID>, entityType: String, context: ModelContext) {}
}
