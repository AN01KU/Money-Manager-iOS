import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetsViewModelMutationTests {

    private func makeService() throws -> (PersistenceService, ModelContext) {
        let context = ModelContext(try makeTestContainer())
        let svc = PersistenceService(
            modelContext: context,
            authService: MockAuthService.shared,
            networkMonitor: MockNetworkMonitor(),
            changeQueue: MockChangeQueueManager.shared
        )
        return (svc, context)
    }

    private func makeViewModel(persistence: PersistenceService) -> BudgetsViewModel {
        let vm = BudgetsViewModel()
        vm.persistence = persistence
        return vm
    }

    // MARK: - saveBudget: create

    @Test
    func testSaveBudget_newLimit_createsUserBudgetInSwiftData() throws {
        let (svc, context) = try makeService()
        let vm = makeViewModel(persistence: svc)

        try vm.saveBudget(limit: 5000)

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 5000)
    }

    // MARK: - saveBudget: update (no duplicate)

    @Test
    func testSaveBudget_existingRow_updatesLimitWithoutDuplicate() throws {
        let (svc, context) = try makeService()
        let vm = makeViewModel(persistence: svc)

        let existing = UserBudget(limit: 3000)
        context.insert(existing)
        try context.save()

        try vm.saveBudget(limit: 4500)

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 4500)
    }

    // MARK: - saveBudget: zero limit rejected

    @Test
    func testSaveBudget_zeroLimit_throwsValidationError() throws {
        let (svc, context) = try makeService()
        let vm = makeViewModel(persistence: svc)

        #expect(throws: BudgetsViewModel.BudgetValidationError.zeroLimit) {
            try vm.saveBudget(limit: 0)
        }

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.isEmpty)
    }

    // MARK: - saveBudget: enqueues sync change

    @Test
    func testSaveBudget_enqueuesPutWithCorrectContract() throws {
        let (svc, _) = try makeService()
        let vm = makeViewModel(persistence: svc)
        MockChangeQueueManager.shared.reset()

        try vm.saveBudget(limit: 2000)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == .budget)
        #expect(log.first?.endpoint == "/me/budget")
        #expect(log.first?.httpMethod == .put)
    }

    @Test
    func testSaveBudget_payloadContainsLimit() throws {
        let (svc, _) = try makeService()
        let vm = makeViewModel(persistence: svc)
        MockChangeQueueManager.shared.reset()

        try vm.saveBudget(limit: 3500)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        if let payload = log.first?.payload,
           let decoded = try? JSONDecoder().decode(APISetBudgetRequest.self, from: payload) {
            #expect(decoded.limit == 3500)
        } else {
            Issue.record("Expected decodable APISetBudgetRequest payload")
        }
    }

    @Test
    func testSaveBudget_existingRow_stillEnqueuesPut() throws {
        let (svc, context) = try makeService()
        let vm = makeViewModel(persistence: svc)

        let existing = UserBudget(limit: 1000)
        context.insert(existing)
        try context.save()

        MockChangeQueueManager.shared.reset()
        try vm.saveBudget(limit: 1500)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.httpMethod == .put)
        #expect(log.first?.endpoint == "/me/budget")
    }

    // MARK: - clearBudget

    @Test
    func testClearBudget_setsLimitToNilInSwiftData() throws {
        let (svc, context) = try makeService()
        let vm = makeViewModel(persistence: svc)

        let existing = UserBudget(limit: 3000)
        context.insert(existing)
        try context.save()

        try vm.clearBudget()

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == nil)
    }

    @Test
    func testClearBudget_whenNoBudgetRow_createsClearedRow() throws {
        let (svc, context) = try makeService()
        let vm = makeViewModel(persistence: svc)

        try vm.clearBudget()

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == nil)
    }

    @Test
    func testClearBudget_enqueuesPutWithNullLimit() throws {
        let (svc, _) = try makeService()
        let vm = makeViewModel(persistence: svc)
        MockChangeQueueManager.shared.reset()

        try vm.clearBudget()

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
