import Foundation
import Testing
@testable import Money_Manager

/// Tests for ServiceFactory: verifies that the factory returns the correct
/// service types in both default (test) and explicit mock mode.
@MainActor
struct ServiceFactoryTests {

    @Test func testFactoryDefaultReturnsAuthService() {
        // In test environment (isRunningTests == true), should return MockAuthService
        var factory = ServiceFactory()
        let auth = factory.authService
        #expect(auth is MockAuthService)
    }

    @Test func testFactoryDefaultReturnsMockSyncService() {
        var factory = ServiceFactory()
        let sync = factory.syncService
        #expect(sync is MockSyncService)
    }

    @Test func testFactoryDefaultReturnsMockChangeQueueManager() {
        var factory = ServiceFactory()
        let cqm = factory.changeQueueManager
        #expect(cqm is MockChangeQueueManager)
    }

    @Test func testFactoryDefaultReturnsMockGroupService() {
        var factory = ServiceFactory()
        let gs = factory.groupService
        #expect(gs is MockGroupService)
    }

    @Test func testFactoryExplicitMocksReturnsAuthService() {
        var factory = ServiceFactory(true)
        let auth = factory.authService
        #expect(auth is MockAuthService)
    }

    @Test func testFactoryExplicitMocksReturnsSyncService() {
        var factory = ServiceFactory(true)
        let sync = factory.syncService
        #expect(sync is MockSyncService)
    }

    @Test func testFactoryExplicitMocksReturnsChangeQueueManager() {
        var factory = ServiceFactory(true)
        let cqm = factory.changeQueueManager
        #expect(cqm is MockChangeQueueManager)
    }

    @Test func testFactoryExplicitMocksReturnsGroupService() {
        var factory = ServiceFactory(true)
        let gs = factory.groupService
        #expect(gs is MockGroupService)
    }
}
