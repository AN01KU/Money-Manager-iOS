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
        ChangeQueueManager()
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
    func testReplayAllSkipsWhenNotAuthenticated() async throws {
        MockAuthService.shared.authState = .guest
        defer { MockAuthService.shared.authState = .authenticated(APIUser(id: UUID(), email: "", username: "", created_at: Date())) }

        let container = try makeContainer()
        let context = ModelContext(container)
        enqueueChange(in: context)

        let manager = makeManager()
        manager.configure(container: container)

        await manager.replayAll(context: context, isAuthenticated: false)

        let remaining = try context.fetch(FetchDescriptor<PendingChange>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.retryCount == 0)
    }

    // MARK: - Enqueue + deduplication

    @Test
    func testEnqueueCreateThenUpdateMergesPayload() throws {
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
        #expect(all.count == 1)
        #expect(all.first?.action == "create")
        let payloadString = all.first?.payload.flatMap { String(data: $0, encoding: .utf8) }
        #expect(payloadString == #"{"amount":"200"}"#)
    }

    @Test
    func testEnqueueCreateThenDeleteCancelsOut() throws {
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
        #expect(all.count == 0)
    }

    @Test
    func testEnqueueUpdateThenDeleteBecomesDelete() throws {
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
    func testEnqueueDifferentEntitiesAreKeptSeparate() throws {
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
    func testClearAllRemovesAllPendingChanges() throws {
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
    func testPendingCountReflectsQueueSize() throws {
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
