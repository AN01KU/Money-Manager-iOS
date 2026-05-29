//
//  ChangeRecordTests.swift
//  Money ManagerTests
//

import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct ChangeRecordTests {

    private func makePending() -> ChangeRecord {
        ChangeRecord(
            entityType: .expense,
            entityID: UUID(),
            action: .create,
            endpoint: "/expenses",
            httpMethod: .post,
            payload: Data("{}".utf8)
        )
    }

    // MARK: - Factory defaults

    @Test func newRecordIsPendingWithNoTimestamps() {
        let record = makePending()
        #expect(record.status == .pending)
        #expect(record.retryCount == 0)
        #expect(record.nextRetryAt == nil)
        #expect(record.failedAt == nil)
        #expect(record.lastError == nil)
        #expect(record.orphanedAt == nil)
    }

    // MARK: - scheduleRetry

    @Test func scheduleRetrySetsNextRetryAt() {
        let record = makePending()
        let next = Date().addingTimeInterval(60)
        record.scheduleRetry(at: next)
        #expect(record.nextRetryAt == next)
        #expect(record.status == .pending)
    }

    // MARK: - fail

    @Test func failTransitionsToFailedAndStampsFailedAt() {
        let record = makePending()
        let now = Date(timeIntervalSince1970: 1_000_000)
        record.fail(reason: "boom", at: now)

        #expect(record.status == .failed)
        #expect(record.failedAt == now)
        #expect(record.lastError == "boom")
        #expect(record.nextRetryAt == nil)
    }

    @Test func failClearsAnyPendingRetrySchedule() {
        let record = makePending()
        record.scheduleRetry(at: Date().addingTimeInterval(60))
        record.fail(reason: "boom")
        #expect(record.nextRetryAt == nil)
    }

    // MARK: - orphan

    @Test func orphanTransitionsToOrphanedAndStampsOrphanedAt() {
        let record = makePending()
        let now = Date(timeIntervalSince1970: 2_000_000)
        record.orphan(at: now)

        #expect(record.status == .orphaned)
        #expect(record.orphanedAt == now)
        #expect(record.nextRetryAt == nil)
    }

    // MARK: - Audit trail

    @Test func pendingToFailToOrphanPreservesCoreFields() {
        let entityID = UUID()
        let createdAt = Date(timeIntervalSince1970: 500_000)
        let payload = Data("{\"amount\":100}".utf8)
        let record = ChangeRecord(
            entityType: .expense,
            entityID: entityID,
            action: .update,
            endpoint: "/expenses",
            httpMethod: .put,
            payload: payload,
            createdAt: createdAt
        )

        record.fail(reason: "500 error", at: Date(timeIntervalSince1970: 600_000))
        record.orphan(at: Date(timeIntervalSince1970: 700_000))

        // Status now orphaned, but historic side-fields preserved
        #expect(record.status == .orphaned)
        #expect(record.entityID == entityID)
        #expect(record.entityType == EntityType.expense.rawValue)
        #expect(record.action == ChangeAction.update.rawValue)
        #expect(record.endpoint == "/expenses")
        #expect(record.httpMethod == HTTPMethod.put.rawValue)
        #expect(record.payload == payload)
        #expect(record.createdAt == createdAt)
        #expect(record.failedAt == Date(timeIntervalSince1970: 600_000))
        #expect(record.lastError == "500 error")
        #expect(record.orphanedAt == Date(timeIntervalSince1970: 700_000))
    }
}
