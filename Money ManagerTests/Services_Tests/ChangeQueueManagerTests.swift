import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct ChangeQueueManagerTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: PendingChange.self, configurations: config)
    }

    private func makeManager() -> ChangeQueueManager {
        let manager = ChangeQueueManager()
        return manager
    }

    private func enqueueChange(in context: ModelContext) {
        let change = PendingChange(
            entityType: "budget",
            entityID: UUID(),
            action: "create",
            endpoint: "/budgets",
            httpMethod: "POST",
            payload: "{}".data(using: .utf8)
        )
        context.insert(change)
        try? context.save()
    }

    // MARK: - Auth guard

    @Test
    func test_replayAll_skips_whenNotAuthenticated() async throws {
        // MockAuthService defaults to isAuthenticated = true — flip it
        MockAuthService.shared.isAuthenticated = false
        defer { MockAuthService.shared.isAuthenticated = true }

        let container = try makeContainer()
        let context = ModelContext(container)
        enqueueChange(in: context)

        let manager = makeManager()
        manager.configure(container: container)

        await manager.replayAll(context: context)

        // PendingChange should still be in the queue — nothing was replayed
        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.count == 1)
    }

    @Test
    func test_replayAll_whenAuthenticated_attemptsReplay() async throws {
        // MockAuthService is authenticated by default
        #expect(MockAuthService.shared.isAuthenticated == true)

        let container = try makeContainer()
        let context = ModelContext(container)
        enqueueChange(in: context)

        let manager = makeManager()
        manager.configure(container: container)

        // replayAll will attempt the API call, which will fail (no real server).
        // The key assertion is that it DID attempt — change stays in queue with incremented retryCount.
        await manager.replayAll(context: context)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        // Either retried (retryCount > 0) or removed on success — either way it attempted
        let attempted = remaining.isEmpty || (remaining.first?.retryCount ?? 0) > 0
        #expect(attempted == true)
    }

    // MARK: - Enqueue + deduplication

    @Test
    func test_enqueue_createThenUpdate_mergesPayload() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager()
        manager.configure(container: container)
        let entityID = UUID()

        manager.enqueue(
            entityType: "expense",
            entityID: entityID,
            action: "create",
            endpoint: "/expenses",
            httpMethod: "POST",
            payload: #"{"amount":"100"}"#.data(using: .utf8),
            context: context
        )
        manager.enqueue(
            entityType: "expense",
            entityID: entityID,
            action: "update",
            endpoint: "/expenses",
            httpMethod: "PUT",
            payload: #"{"amount":"200"}"#.data(using: .utf8),
            context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        // create + update should collapse into one create with updated payload
        #expect(all.count == 1)
        #expect(all.first?.action == "create")
        let payloadString = all.first?.payload.flatMap { String(data: $0, encoding: .utf8) }
        #expect(payloadString == #"{"amount":"200"}"#)
    }

    @Test
    func test_enqueue_createThenDelete_cancelsOut() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager()
        manager.configure(container: container)
        let entityID = UUID()

        manager.enqueue(
            entityType: "expense",
            entityID: entityID,
            action: "create",
            endpoint: "/expenses",
            httpMethod: "POST",
            payload: nil,
            context: context
        )
        manager.enqueue(
            entityType: "expense",
            entityID: entityID,
            action: "delete",
            endpoint: "/expenses",
            httpMethod: "DELETE",
            payload: nil,
            context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        // Created and then immediately deleted — nothing needs to be synced
        #expect(all.count == 0)
    }

    @Test
    func test_enqueue_updateThenDelete_becomesDelete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager()
        manager.configure(container: container)
        let entityID = UUID()

        manager.enqueue(
            entityType: "budget",
            entityID: entityID,
            action: "update",
            endpoint: "/budgets",
            httpMethod: "PUT",
            payload: #"{"limit":"5000"}"#.data(using: .utf8),
            context: context
        )
        manager.enqueue(
            entityType: "budget",
            entityID: entityID,
            action: "delete",
            endpoint: "/budgets",
            httpMethod: "DELETE",
            payload: nil,
            context: context
        )

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 1)
        #expect(all.first?.action == "delete")
        #expect(all.first?.payload == nil)
    }

    @Test
    func test_enqueue_differentEntities_areKeptSeparate() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager()
        manager.configure(container: container)

        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)
        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 2)
    }

    // MARK: - clearAll

    @Test
    func test_clearAll_removesAllPendingChanges() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let manager = makeManager()
        manager.configure(container: container)

        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)
        manager.enqueue(entityType: "budget", entityID: UUID(), action: "create",
                        endpoint: "/budgets", httpMethod: "POST", payload: nil, context: context)

        manager.clearAll(context: context)

        let all = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(all.count == 0)
    }

    // MARK: - pendingCount

    @Test
    func test_pendingCount_reflectsQueueSize() throws {
        let container = try makeContainer()
        let manager = makeManager()
        manager.configure(container: container)
        let context = ModelContext(container)

        #expect(manager.pendingCount == 0)

        manager.enqueue(entityType: "expense", entityID: UUID(), action: "create",
                        endpoint: "/expenses", httpMethod: "POST", payload: nil, context: context)
        #expect(manager.pendingCount == 1)

        manager.enqueue(entityType: "budget", entityID: UUID(), action: "create",
                        endpoint: "/budgets", httpMethod: "POST", payload: nil, context: context)
        #expect(manager.pendingCount == 2)
    }
}
