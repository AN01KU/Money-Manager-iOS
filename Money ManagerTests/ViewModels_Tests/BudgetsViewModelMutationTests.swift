import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetsViewModelMutationTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeViewModel() -> BudgetsViewModel {
        BudgetsViewModel()
    }

    // MARK: - saveBudget: create

    @Test
    func testSaveBudget_newLimit_createsUserBudgetInSwiftData() throws {
        let context = try makeContext()
        let vm = makeViewModel()

        try vm.saveBudget(limit: 5000, context: context, changeQueue: MockChangeQueueManager.shared)

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 5000)
    }

    // MARK: - saveBudget: update (no duplicate)

    @Test
    func testSaveBudget_existingRow_updatesLimitWithoutDuplicate() throws {
        let context = try makeContext()
        let vm = makeViewModel()

        let existing = UserBudget(limit: 3000)
        context.insert(existing)
        try context.save()

        try vm.saveBudget(limit: 4500, context: context, changeQueue: MockChangeQueueManager.shared)

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 4500)
    }

    // MARK: - saveBudget: zero limit rejected

    @Test
    func testSaveBudget_zeroLimit_throwsValidationError() throws {
        let context = try makeContext()
        let vm = makeViewModel()

        #expect(throws: BudgetsViewModel.BudgetValidationError.zeroLimit) {
            try vm.saveBudget(limit: 0, context: context, changeQueue: MockChangeQueueManager.shared)
        }

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.isEmpty)
    }

    // MARK: - saveBudget: enqueues sync change

    @Test
    func testSaveBudget_enqueuesPutWithCorrectContract() throws {
        let context = try makeContext()
        let vm = makeViewModel()
        MockChangeQueueManager.shared.reset()

        try vm.saveBudget(limit: 2000, context: context, changeQueue: MockChangeQueueManager.shared)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == "budget")
        #expect(log.first?.endpoint == "/me/budget")
        #expect(log.first?.httpMethod == "PUT")
    }

    @Test
    func testSaveBudget_payloadContainsLimit() throws {
        let context = try makeContext()
        let vm = makeViewModel()
        MockChangeQueueManager.shared.reset()

        try vm.saveBudget(limit: 3500, context: context, changeQueue: MockChangeQueueManager.shared)

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
        let context = try makeContext()
        let vm = makeViewModel()

        let existing = UserBudget(limit: 1000)
        context.insert(existing)
        try context.save()

        MockChangeQueueManager.shared.reset()
        try vm.saveBudget(limit: 1500, context: context, changeQueue: MockChangeQueueManager.shared)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.httpMethod == "PUT")
        #expect(log.first?.endpoint == "/me/budget")
    }

    // MARK: - clearBudget

    @Test
    func testClearBudget_setsLimitToNilInSwiftData() throws {
        let context = try makeContext()
        let vm = makeViewModel()

        let existing = UserBudget(limit: 3000)
        context.insert(existing)
        try context.save()

        try vm.clearBudget(context: context, changeQueue: MockChangeQueueManager.shared)

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == nil)
    }

    @Test
    func testClearBudget_whenNoBudgetRow_createsClearedRow() throws {
        let context = try makeContext()
        let vm = makeViewModel()

        try vm.clearBudget(context: context, changeQueue: MockChangeQueueManager.shared)

        let all = try context.fetch(FetchDescriptor<UserBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == nil)
    }

    @Test
    func testClearBudget_enqueuesPutWithNullLimit() throws {
        let context = try makeContext()
        let vm = makeViewModel()
        MockChangeQueueManager.shared.reset()

        try vm.clearBudget(context: context, changeQueue: MockChangeQueueManager.shared)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == "budget")
        #expect(log.first?.endpoint == "/me/budget")
        #expect(log.first?.httpMethod == "PUT")

        if let payload = log.first?.payload,
           let decoded = try? JSONDecoder().decode(APISetBudgetRequest.self, from: payload) {
            #expect(decoded.limit == nil)
        } else {
            Issue.record("Expected decodable APISetBudgetRequest payload with null limit")
        }
    }
}
