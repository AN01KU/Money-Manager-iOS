import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Unit tests for `CategoryPullHandler` — verifies insert, LWW, validation,
/// predefined-key matching, purge, pending-guard, and count tracking
/// independently of `SyncService`.
@MainActor
struct CategoryPullHandlerTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer { try makeTestContainer() }

    private func makeChangeQueue() -> MockChangeQueueManager { MockChangeQueueManager.shared }

    private func makeAPIClient(categories: [APICategory]) -> MockAPIClient {
        let mock = MockAPIClient()
        mock.getHandler = { _ in APIListResponse(data: categories) }
        return mock
    }

    private func apiCategory(
        id: UUID = UUID(),
        key: String = "custom-key",
        name: String = "Custom",
        icon: String = "star",
        color: String = "#FF0000",
        isPredefined: Bool = false,
        predefinedKey: String? = nil,
        isHidden: Bool = false,
        updatedAt: Date = Date()
    ) -> APICategory {
        APICategory(
            id: id, userId: UUID(),
            key: key,
            name: name, icon: icon, color: color,
            isHidden: isHidden,
            isPredefined: isPredefined,
            predefinedKey: predefinedKey,
            createdAt: Date(), updatedAt: updatedAt
        )
    }

    // MARK: - Insert new category from server

    @Test func testPullInsertsNewCategoryFromServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = CategoryPullHandler()
        let remote = apiCategory(name: "Travel", icon: "airplane", color: "#0000FF")

        try await handler.pull(api: makeAPIClient(categories: [remote]), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.count == 1)
        #expect(local.first?.name == "Travel")
        #expect(local.first?.color == "#0000FF")
    }

    // MARK: - LWW: server wins when newer

    @Test func testPullAppliesServerUpdateWhenNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let catId = UUID()
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        let localCat = Money_Manager.Category(id: catId, name: "OldName", icon: "star", color: "#FF0000")
        localCat.updatedAt = old
        context.insert(localCat)
        try context.save()

        let remote = apiCategory(id: catId, name: "NewName", icon: "leaf", color: "#00FF00", updatedAt: newer)
        let handler = CategoryPullHandler()
        try await handler.pull(api: makeAPIClient(categories: [remote]), changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(all.count == 1)
        #expect(all.first?.name == "NewName")
    }

    // MARK: - LWW: local wins when newer

    @Test func testPullKeepsLocalWhenLocalIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let catId = UUID()
        let newer = Date(timeIntervalSinceNow: -10)
        let older = Date(timeIntervalSinceNow: -3600)

        let localCat = Money_Manager.Category(id: catId, name: "LocalName", icon: "star", color: "#FF0000")
        localCat.updatedAt = newer
        context.insert(localCat)
        try context.save()

        let remote = apiCategory(id: catId, name: "ServerName", updatedAt: older)
        let handler = CategoryPullHandler()
        try await handler.pull(api: makeAPIClient(categories: [remote]), changeQueue: makeChangeQueue(), context: context)

        let all = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(all.count == 1)
        #expect(all.first?.name == "LocalName")
    }

    // MARK: - Validation: skip category with empty name

    @Test func testPullSkipsCategoryWithEmptyName() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = CategoryPullHandler()
        let invalid = apiCategory(name: "   ")

        try await handler.pull(api: makeAPIClient(categories: [invalid]), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.isEmpty)
    }

    // MARK: - Purge: custom category not on server

    @Test func testPullPurgesCustomCategoryNotOnServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let stale = Money_Manager.Category(name: "Stale", icon: "trash", color: "#888888")
        stale.isPredefined = false
        context.insert(stale)
        try context.save()

        let handler = CategoryPullHandler()
        try await handler.pull(api: makeAPIClient(categories: []), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.isEmpty)
    }

    // MARK: - Purge guard: category with pending change is kept

    @Test func testPullKeepsCategoryWithPendingChange() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let catId = UUID()
        let cat = Money_Manager.Category(id: catId, name: "PendingCat", icon: "clock", color: "#AAAAAA")
        cat.isPredefined = false
        context.insert(cat)

        let pending = ChangeRecord.makePending(entityType: "category", entityID: catId, action: "update",
                                              endpoint: "/categories/\(catId)", httpMethod: "PATCH", payload: Data())
        context.insert(pending)
        try context.save()

        let handler = CategoryPullHandler()
        try await handler.pull(api: makeAPIClient(categories: []), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.count == 1)
        #expect(local.first?.name == "PendingCat")
    }

    // MARK: - Server-predefined row not purged

    @Test func testPullDoesNotPurgeServerPredefinedRow() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let predefined = Money_Manager.Category(
            name: "Food & Dining", icon: "fork.knife", color: "#FFA500",
            isPredefined: true, isServerPredefined: true
        )
        predefined.key = "food-dining"
        context.insert(predefined)
        try context.save()

        let handler = CategoryPullHandler()
        try await handler.pull(api: makeAPIClient(categories: []), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.count == 1)
    }

    // MARK: - lastServerCount / lastLocalCount populated after pull

    @Test func testPullSetsServerAndLocalCounts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(Money_Manager.Category(name: "A", icon: "a", color: "#111"))
        context.insert(Money_Manager.Category(name: "B", icon: "b", color: "#222"))
        try context.save()

        let remote = [apiCategory(name: "X"), apiCategory(name: "Y"), apiCategory(name: "Z")]
        let handler = CategoryPullHandler()
        try await handler.pull(api: makeAPIClient(categories: remote), changeQueue: makeChangeQueue(), context: context)

        #expect(handler.lastServerCount == 3)
        #expect(handler.lastLocalCount == 2)
    }
}
