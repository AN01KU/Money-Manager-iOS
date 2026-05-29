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
        ModelContext(try makeTestContainer())
    }

    private func insertPendingChange(in context: ModelContext, entityType: EntityType = .transaction) -> ChangeRecord {
        let change = ChangeRecord(
            entityType: entityType,
            entityID: UUID(),
            action: .create,
            endpoint: "/transactions",
            httpMethod: .post,
            payload: nil
        )
        context.insert(change)
        try? context.save()
        return change
    }

    private func insertOrphanedChange(orphanedAt: Date, in context: ModelContext) {
        let orphan = ChangeRecord(
            entityType: .transaction,
            entityID: UUID(),
            action: .create,
            endpoint: "/transactions",
            httpMethod: .post,
            payload: nil,
            status: .orphaned,
            orphanedAt: orphanedAt
        )
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

        let pending = try context.fetch(makeDescriptor(statusRaw: "pending"))
        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(pending.isEmpty)
        #expect(orphaned.count == 2)
    }

    @Test
    func testOrphanAllClearsPendingQueue() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        _ = insertPendingChange(in: context)

        manager.orphanAll(context: context)

        let pending = try context.fetch(makeDescriptor(statusRaw: "pending"))
        #expect(pending.isEmpty)
    }

    @Test
    func testOrphanAllOnEmptyQueueDoesNothing() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()

        manager.orphanAll(context: context)

        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(orphaned.isEmpty)
    }

    @Test
    func testOrphanAllPreservesPayloadAndMetadata() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        let payload = "test-payload".data(using: .utf8)!
        let change = ChangeRecord(
            entityType: .budget,
            entityID: UUID(),
            action: .create,
            endpoint: "/budgets",
            httpMethod: .post,
            payload: payload
        )
        context.insert(change)
        try? context.save()

        manager.orphanAll(context: context)

        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(orphaned.count == 1)
        #expect(orphaned.first?.entityType == EntityType.budget.rawValue)
        #expect(orphaned.first?.payload == payload)
        #expect(orphaned.first?.httpMethod == HTTPMethod.post.rawValue)
    }

    // MARK: - purgeExpiredOrphans

    @Test
    func testPurgeExpiredOrphansDeletesRecordsOlderThanCutoff() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        let eightDaysAgo = Date(timeIntervalSinceNow: -8 * 86400)
        insertOrphanedChange(orphanedAt: eightDaysAgo, in: context)

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(orphaned.isEmpty)
    }

    @Test
    func testPurgeExpiredOrphansKeepsRecordsWithinCutoff() throws {
        let context = try makeContext()
        let manager = ChangeQueueManager()
        let threeDaysAgo = Date(timeIntervalSinceNow: -3 * 86400)
        insertOrphanedChange(orphanedAt: threeDaysAgo, in: context)

        manager.purgeExpiredOrphans(olderThan: 7, context: context)

        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
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

        let orphaned = try context.fetch(makeDescriptor(statusRaw: "orphaned"))
        #expect(orphaned.count == 1)
        #expect(orphaned.first?.orphanedAt == oneDayAgo)
    }
}
