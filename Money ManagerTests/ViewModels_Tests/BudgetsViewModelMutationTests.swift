import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct BudgetsViewModelMutationTests {

    private func makeContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    private func makeViewModel(selectedMonth: Date = Date()) -> BudgetsViewModel {
        let vm = BudgetsViewModel()
        vm.selectedMonth = selectedMonth
        return vm
    }

    private func fixedMonth() -> Date {
        Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
    }

    // MARK: - saveBudget: create

    @Test
    func testSaveBudget_newLimit_createsBudgetInSwiftData() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())

        try vm.saveBudget(limit: 5000, context: context, changeQueue: MockChangeQueueManager.shared)

        let all = try context.fetch(FetchDescriptor<MonthlyBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 5000)
        #expect(all.first?.year == 2025)
        #expect(all.first?.month == 6)
    }

    // MARK: - saveBudget: update (no duplicate)

    @Test
    func testSaveBudget_existingMonth_updatesRecordWithoutDuplicate() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())

        let existing = MonthlyBudget(year: 2025, month: 6, limit: 3000)
        context.insert(existing)
        try context.save()

        try vm.saveBudget(limit: 4500, context: context, changeQueue: MockChangeQueueManager.shared)

        let all = try context.fetch(FetchDescriptor<MonthlyBudget>())
        #expect(all.count == 1)
        #expect(all.first?.limit == 4500)
    }

    // MARK: - saveBudget: zero limit rejected

    @Test
    func testSaveBudget_zeroLimit_throwsValidationError() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())

        #expect(throws: BudgetsViewModel.BudgetValidationError.zeroLimit) {
            try vm.saveBudget(limit: 0, context: context, changeQueue: MockChangeQueueManager.shared)
        }

        let all = try context.fetch(FetchDescriptor<MonthlyBudget>())
        #expect(all.isEmpty)
    }

    // MARK: - saveBudget: enqueues sync change

    @Test
    func testSaveBudget_newBudget_enqueuesCreateWithCorrectContract() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())
        MockChangeQueueManager.shared.reset()

        try vm.saveBudget(limit: 2000, context: context, changeQueue: MockChangeQueueManager.shared)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == "budget")
        #expect(log.first?.action == "create")
        #expect(log.first?.endpoint == "/budgets")
        #expect(log.first?.httpMethod == "POST")
    }

    @Test
    func testSaveBudget_existingBudget_enqueuesUpdateWithCorrectContract() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())

        let existing = MonthlyBudget(year: 2025, month: 6, limit: 1000)
        context.insert(existing)
        try context.save()

        MockChangeQueueManager.shared.reset()
        try vm.saveBudget(limit: 1500, context: context, changeQueue: MockChangeQueueManager.shared)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == "budget")
        #expect(log.first?.action == "update")
        #expect(log.first?.httpMethod == "PATCH")
    }

    // MARK: - deleteBudget

    @Test
    func testDeleteBudget_removesMonthlyBudgetFromSwiftData() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())

        let budget = MonthlyBudget(year: 2025, month: 6, limit: 3000)
        context.insert(budget)
        try context.save()

        try vm.deleteBudget(context: context, changeQueue: MockChangeQueueManager.shared)

        let all = try context.fetch(FetchDescriptor<MonthlyBudget>())
        #expect(all.isEmpty)
    }

    @Test
    func testDeleteBudget_enqueuesDeleteWithCorrectContract() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())

        let budget = MonthlyBudget(year: 2025, month: 6, limit: 3000)
        context.insert(budget)
        try context.save()

        MockChangeQueueManager.shared.reset()
        try vm.deleteBudget(context: context, changeQueue: MockChangeQueueManager.shared)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.count == 1)
        #expect(log.first?.entityType == "budget")
        #expect(log.first?.action == "delete")
        #expect(log.first?.httpMethod == "DELETE")
    }

    @Test
    func testDeleteBudget_whenNoBudgetExists_doesNothing() throws {
        let context = try makeContext()
        let vm = makeViewModel(selectedMonth: fixedMonth())
        MockChangeQueueManager.shared.reset()

        // Should not throw and should not enqueue anything
        try vm.deleteBudget(context: context, changeQueue: MockChangeQueueManager.shared)

        let log = MockChangeQueueManager.shared.enqueueCallLog
        #expect(log.isEmpty)
    }
}
