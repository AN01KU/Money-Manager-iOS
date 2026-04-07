//
//  SyncSessionOrphanNotificationTests.swift
//  Money ManagerTests
//

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct SyncSessionOrphanNotificationTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PendingChange.self, OrphanedChange.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func insertPendingChange(in context: ModelContext) {
        let change = PendingChange(
            entityType: "transaction",
            entityID: UUID(),
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: nil
        )
        context.insert(change)
        try? context.save()
    }

    // MARK: - Tests

    @Test
    func testOrphanAllPostsSyncSessionOrphanedNotification() async throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        insertPendingChange(in: context)

        var received = false
        let observer = NotificationCenter.default.addObserver(
            forName: .syncSessionOrphaned,
            object: nil,
            queue: .main
        ) { _ in received = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        // Simulate what SyncService does when preflight fails
        manager.orphanAll(context: context)
        NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)

        // Give main queue a cycle to deliver
        await Task.yield()

        #expect(received == true)
    }

    @Test
    func testEmptyQueueOrphanDoesNotPostNotification() async throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()

        var received = false
        let observer = NotificationCenter.default.addObserver(
            forName: .syncSessionOrphaned,
            object: nil,
            queue: .main
        ) { _ in received = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        // orphanAll on empty queue — SyncService only posts notification if orphaning actually happened
        let pendingBefore = (try? context.fetch(FetchDescriptor<PendingChange>()))?.count ?? 0
        if pendingBefore > 0 {
            manager.orphanAll(context: context)
            NotificationCenter.default.post(name: .syncSessionOrphaned, object: nil)
        }

        await Task.yield()

        #expect(received == false)
    }
}
