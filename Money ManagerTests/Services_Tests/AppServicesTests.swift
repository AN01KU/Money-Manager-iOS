import Foundation
import Testing
import SwiftData
@testable import Money_Manager

@MainActor
struct AppServicesTests {

    // MARK: - uiTestMocks smoke test

    @Test func testUITestMocksConstructsWithoutCrashing() {
        let services = AppServices.uiTestMocks()
        #expect(services.authService is MockAuthService)
        #expect(services.syncService is MockSyncService)
        #expect(services.changeQueueManager is MockChangeQueueManager)
        #expect(services.groupService is GroupService)
    }

    @Test func testUITestMocksReturnsFreshInstanceEachCall() {
        let a = AppServices.uiTestMocks()
        let b = AppServices.uiTestMocks()
        // Persistence contexts should be independent (different in-memory containers)
        #expect(a.persistence.modelContext !== b.persistence.modelContext)
    }

    // MARK: - preview smoke test

    @Test func testPreviewConstructsWithoutCrashing() {
        let services = AppServices.preview
        #expect(services.authService is MockAuthService)
        #expect(services.syncService is MockSyncService)
        #expect(services.changeQueueManager is MockChangeQueueManager)
        #expect(services.groupService is GroupService)
    }

    // MARK: - live smoke test

    @Test func testLiveConstructsWithoutCrashing() throws {
        let schema = Schema([
            Transaction.self, RecurringTransaction.self, UserBudget.self, Category.self,
            PendingChange.self, FailedChange.self, OrphanedChange.self,
            SplitGroupModel.self, GroupMemberModel.self, GroupTransactionModel.self, GroupBalanceModel.self
        ])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let services = AppServices.live(container: container)
        #expect(services.authService is AuthService)
        #expect(services.syncService is SyncService)
        #expect(services.changeQueueManager is ChangeQueueManager)
        #expect(services.groupService is GroupService)
    }
}
