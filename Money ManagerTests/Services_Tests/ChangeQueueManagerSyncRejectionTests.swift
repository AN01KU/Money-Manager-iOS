//
//  ChangeQueueManagerSyncRejectionTests.swift
//  Money ManagerTests
//

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Tests that ChangeQueueManager correctly handles sync session invalidation.
/// Tests `orphanAll` directly — the networking path is covered by APIErrorSyncSessionTests.
@MainActor
struct ChangeQueueManagerSyncRejectionTests {

    // MARK: - Helpers

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PendingChange.self, OrphanedChange.self, FailedChange.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func insertPendingChange(in context: ModelContext) -> PendingChange {
        let change = PendingChange(
            entityType: "transaction",
            entityID: UUID(),
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: "{}".data(using: .utf8)!
        )
        context.insert(change)
        try? context.save()
        return change
    }

    // MARK: - Tests

    @Test
    func testOrphanAllMovesChangesToOrphanedQueue() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()

        _ = insertPendingChange(in: context)
        _ = insertPendingChange(in: context)

        manager.orphanAll(context: context)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(pending.isEmpty)
        #expect(orphaned.count == 2)
    }

    @Test
    func testOrphanAllClearsAllPendingChanges() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()

        _ = insertPendingChange(in: context)
        _ = insertPendingChange(in: context)
        _ = insertPendingChange(in: context)

        manager.orphanAll(context: context)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(pending.isEmpty)
    }
}
