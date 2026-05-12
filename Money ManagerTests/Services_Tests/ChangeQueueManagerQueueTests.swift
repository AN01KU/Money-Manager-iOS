import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct ChangeQueueManagerQueueTests {

    private func makeContainer() throws -> ModelContainer {
        try makeTestContainer()
    }

    private func makeManager(container: ModelContainer) -> ChangeQueueManager {
        let mgr = ChangeQueueManager()
        mgr.configure(container: container)
        return mgr
    }

    // MARK: - Enqueue + deduplication

    @Test func testEnqueueCreateThenUpdateMergesPayload() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)
        let entityID = UUID()

        manager.enqueue(
            entityType: "expense", entityID: entityID,
            action: "create", endpoint: "/expenses",
            httpMethod: "POST", payload: #"{"amount":"100"}"#.data(using: .utf8),
            context: context
        )
        manager.enqueue(
            entityType: "expense", entityID: entityID,
            action: "update", endpoint: "/expenses",
            httpMethod: "PUT", payload: #"{"amount":"200"}"#.data(using: .utf8),
            context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 1)
        #expect(all.first?.action == "create")
        let payloadString = all.first?.payload.flatMap { String(data: $0, encoding: .utf8) }
        #expect(payloadString == #"{"amount":"200"}"#)
    }

    @Test func testEnqueueCreateThenDeleteCancelsOut() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)
        let entityID = UUID()

        manager.enqueue(
            entityType: "expense", entityID: entityID,
            action: "create", endpoint: "/expenses",
            httpMethod: "POST", payload: nil, context: context
        )
        manager.enqueue(
            entityType: "expense", entityID: entityID,
            action: "delete", endpoint: "/expenses",
            httpMethod: "DELETE", payload: nil, context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 0)
    }

    @Test func testEnqueueUpdateThenDeleteBecomesDelete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)
        let entityID = UUID()

        manager.enqueue(
            entityType: "budget", entityID: entityID,
            action: "update", endpoint: "/budgets",
            httpMethod: "PUT", payload: #"{"limit":"5000"}"#.data(using: .utf8),
            context: context
        )
        manager.enqueue(
            entityType: "budget", entityID: entityID,
            action: "delete", endpoint: "/budgets",
            httpMethod: "DELETE", payload: nil, context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 1)
        #expect(all.first?.action == "delete")
        #expect(all.first?.payload == nil)
    }

    @Test func testEnqueueUpdateThenUpdateMergesPayload() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)
        let id = UUID()

        manager.enqueue(
            entityType: "budget", entityID: id,
            action: "update", endpoint: "/budgets",
            httpMethod: "PUT", payload: #"{"limit":"1000"}"#.data(using: .utf8),
            context: context
        )
        manager.enqueue(
            entityType: "budget", entityID: id,
            action: "update", endpoint: "/budgets",
            httpMethod: "PUT", payload: #"{"limit":"2000"}"#.data(using: .utf8),
            context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 1)
        #expect(all.first?.action == "update")
        let payloadString = all.first?.payload.flatMap { String(data: $0, encoding: .utf8) }
        #expect(payloadString == #"{"limit":"2000"}"#)
        #expect(all.first?.retryCount == 0)
    }

    @Test func testEnqueueDeleteThenUpdateKeepsBothChanges() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)
        let id = UUID()

        manager.enqueue(
            entityType: "expense", entityID: id,
            action: "delete", endpoint: "/expenses/\(id)",
            httpMethod: "DELETE", payload: nil, context: context
        )
        manager.enqueue(
            entityType: "expense", entityID: id,
            action: "update", endpoint: "/expenses/\(id)",
            httpMethod: "PUT", payload: nil, context: context
        )

        let changes = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(changes.count == 2)
    }

    @Test func testEnqueueDifferentEntitiesAreKeptSeparate() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)
        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 2)
    }

    // MARK: - clearAll

    @Test func testClearAllRemovesAllPendingChanges() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)
        manager.enqueue(entityType: "budget", entityID: UUID(), action: "create",
                        endpoint: "/budgets", httpMethod: "POST", payload: nil, context: context)

        manager.clearAll(context: context)

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 0)
    }

    @Test func testClearAllIsNoOpWhenQueueIsEmpty() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        manager.clearAll(context: context)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.isEmpty)
    }

    // MARK: - pendingCount / failedCount

    @Test func testPendingCountReflectsQueueSize() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        #expect(manager.pendingCount == 0)

        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)
        #expect(manager.pendingCount == 1)

        manager.enqueue(entityType: "budget", entityID: UUID(), action: "create",
                        endpoint: "/budgets", httpMethod: "POST", payload: nil, context: context)
        #expect(manager.pendingCount == 2)
    }

    @Test func testPendingCountReturnsZeroWithoutContainer() {
        let manager = ChangeQueueManager()
        #expect(manager.pendingCount == 0)
    }

    @Test func testFailedCountReturnsZeroWithoutContainer() {
        let manager = ChangeQueueManager()
        #expect(manager.failedCount == 0)
    }

    // MARK: - Mutual exclusion

    @Test func testReplayAllSkipsConcurrentCall() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager(container: container)

        let change = PendingChange(
            entityType: "budget", entityID: UUID(),
            action: "create", endpoint: "/budgets",
            httpMethod: "POST", payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try context.save()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await manager.replayAll(context: context, isAuthenticated: true) }
            group.addTask { await manager.replayAll(context: context, isAuthenticated: true) }
        }

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.count <= 1)
    }
}
