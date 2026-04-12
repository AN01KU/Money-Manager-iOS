//
//  OrphanedQueueTests.swift
//  Money ManagerTests
//

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct OrphanedQueueTests {

    // MARK: - Setup

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PendingChange.self, OrphanedChange.self,
            configurations: config
        )
        return ModelContext(container)
    }

    private func insertPendingChange(in context: ModelContext, entityType: String = "transaction") -> PendingChange {
        let change = PendingChange(
            entityType: entityType,
            entityID: UUID(),
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: nil
        )
        context.insert(change)
        try? context.save()
        return change
    }

    private func insertOrphanedChange(orphanedAt: Date, in context: ModelContext) {
        let orphan = OrphanedChange(
            entityType: "transaction",
            entityID: UUID(),
            action: "create",
            endpoint: "/transactions",
            httpMethod: "POST",
            payload: nil,
            createdAt: Date()
        )
        orphan.orphanedAt = orphanedAt
        context.insert(orphan)
        try? context.save()
    }

    // MARK: - orphanAll

    @Test
    func testOrphanAllMovesPendingChangesToOrphanedStore() throws {
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
    func testOrphanAllClearsPendingQueue() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        _ = insertPendingChange(in: context)

        manager.orphanAll(context: context)

        let pending = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(pending.isEmpty)
    }

    @Test
    func testOrphanAllOnEmptyQueueDoesNothing() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()

        manager.orphanAll(context: context)

        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(orphaned.isEmpty)
    }

    @Test
    func testOrphanAllPreservesPayloadAndMetadata() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        let payload = "test-payload".data(using: .utf8)!
        let change = PendingChange(
            entityType: "budget",
            entityID: UUID(),
            action: "create",
            endpoint: "/budgets",
            httpMethod: "POST",
            payload: payload
        )
        context.insert(change)
        try? context.save()

        manager.orphanAll(context: context)

        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(orphaned.count == 1)
        #expect(orphaned.first?.entityType == "budget")
        #expect(orphaned.first?.payload == payload)
        #expect(orphaned.first?.httpMethod == "POST")
    }

    // MARK: - purgeExpiredOrphans

    @Test
    func testPurgeExpiredOrphansDeletesRecordsOlderThanCutoff() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        let eightDaysAgo = Date(timeIntervalSinceNow: -8 * 86400)
        insertOrphanedChange(orphanedAt: eightDaysAgo, in: context)

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(orphaned.isEmpty)
    }

    @Test
    func testPurgeExpiredOrphansKeepsRecordsWithinCutoff() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        let threeDaysAgo = Date(timeIntervalSinceNow: -3 * 86400)
        insertOrphanedChange(orphanedAt: threeDaysAgo, in: context)

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(orphaned.count == 1)
    }

    @Test
    func testPurgeExpiredOrphansOnlyDeletesExpiredOnes() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        let eightDaysAgo = Date(timeIntervalSinceNow: -8 * 86400)
        let oneDayAgo = Date(timeIntervalSinceNow: -1 * 86400)
        insertOrphanedChange(orphanedAt: eightDaysAgo, in: context)
        insertOrphanedChange(orphanedAt: oneDayAgo, in: context)

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let orphaned = try context.fetch(FetchDescriptor<OrphanedChange>())
        #expect(orphaned.count == 1)
        #expect(orphaned.first?.orphanedAt == oneDayAgo)
    }
}
