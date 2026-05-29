import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetRepositoryTests {

    private func makeRepository() throws -> (BudgetRepository, ModelContext) {
        let context = ModelContext(try makeTestContainer())
        let svc = PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
        return (BudgetRepository(persistence: svc), context)
    }

    // MARK: - currentBudget

    @Test
    func testCurrentBudget_returnsNilWhenNoBudgetRow() throws {
        let (repo, _) = try makeRepository()
        #expect(repo.currentBudget() == nil)
    }

    @Test
    func testCurrentBudget_returnsExistingRow() throws {
        let (repo, context) = try makeRepository()
        context.insert(UserBudget(limit: 3000))
        try context.save()
        #expect(repo.currentBudget()?.limit == 3000)
    }

    // MARK: - setLimit: create

    @Test
    func testSetLimit_createsUserBudgetInSwiftData() throws {
        let (repo, context) = try makeRepository()
        try repo.setLimit(5000)
        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 5000)
    }

    // MARK: - setLimit: update (no duplicate)

    @Test
    func testSetLimit_existingRow_updatesLimitWithoutDuplicate() throws {
        let (repo, context) = try makeRepository()
        context.insert(UserBudget(limit: 1000))
        try context.save()

        try repo.setLimit(4500)

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 4500)
    }

    // MARK: - setLimit: zero rejected

    @Test
    func testSetLimit_zeroLimit_throwsValidationError() throws {
        let (repo, context) = try makeRepository()
        #expect(throws: BudgetRepository.BudgetValidationError.zeroLimit) {
            try repo.setLimit(0)
        }
        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.isEmpty)
    }

    // MARK: - setLimit: enqueues sync change

    @Test
    func testSetLimit_enqueuesPutWithCorrectContract() throws {
        let (repo, _) = try makeRepository()
        MockChangeQueueManager.shared.reset()
        try repo.setLimit(2000)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == .budget)
        #expect(log.first?.endpoint == "/me/budget")
        #expect(log.first?.httpMethod == .put)
    }

    @Test
    func testSetLimit_payloadContainsLimit() throws {
        let (repo, _) = try makeRepository()
        MockChangeQueueManager.shared.reset()
        try repo.setLimit(3500)
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        if let payload = log.first?.payload,
           let decoded = try? JSONDecoder().decode(APISetBudgetRequest.self, from: payload) {
            #expect(decoded.limit == 3500)
        } else {
            Issue.record("Expected decodable APISetBudgetRequest payload")
        }
    }

    // MARK: - clear

    @Test
    func testClear_setsLimitToNilInSwiftData() throws {
        let (repo, context) = try makeRepository()
        context.insert(UserBudget(limit: 3000))
        try context.save()

        try repo.clear()

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == nil)
    }

    @Test
    func testClear_whenNoBudgetRow_createsClearedRow() throws {
        let (repo, context) = try makeRepository()
        try repo.clear()
        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == nil)
    }

    @Test
    func testClear_enqueuesPutWithNullLimit() throws {
        let (repo, _) = try makeRepository()
        MockChangeQueueManager.shared.reset()
        try repo.clear()
        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == .budget)
        #expect(log.first?.endpoint == "/me/budget")
        #expect(log.first?.httpMethod == .put)
        if let payload = log.first?.payload,
           let decoded = try? JSONDecoder().decode(APISetBudgetRequest.self, from: payload) {
            #expect(decoded.limit == nil)
        } else {
            Issue.record("Expected decodable APISetBudgetRequest payload with null limit")
        }
    }
}
