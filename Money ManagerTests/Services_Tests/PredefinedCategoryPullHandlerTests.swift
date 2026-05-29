import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Unit tests for `PredefinedCategoryPullHandler` — verifies insert, LWW, color migration,
/// admin-delete purge, and count tracking independently of `SyncService`.
@MainActor
struct PredefinedCategoryPullHandlerTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer { try makeTestContainer() }

    private func makeChangeQueue() -> MockChangeQueueManager { MockChangeQueueManager.shared }

    private func makeAPIClient(predefined: [APIPredefinedCategory]) -> MockAPIClient {
        let mock = MockAPIClient()
        mock.getHandler = { _ in APIListResponse(data: predefined) }
        return mock
    }

    private func apiPredefined(
        id: UUID = UUID(),
        key: String = "food-dining",
        name: String = "Food & Dining",
        icon: String = "fork.knife",
        color: String = "#ABCDEF",
        isHidden: Bool = false,
        updatedAt: Date? = Date()
    ) -> APIPredefinedCategory {
        APIPredefinedCategory(
            id: id, key: key, name: name, icon: icon, color: color,
            isHidden: isHidden, createdAt: nil, updatedAt: updatedAt
        )
    }

    // MARK: - Insert new predefined row from server

    @Test func testPullInsertsNewPredefinedCategoryFromServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = PredefinedCategoryPullHandler()
        let remote = apiPredefined(key: "transport", name: "Transport", icon: "car", color: "#FF0000")

        try await handler.pull(api: makeAPIClient(predefined: [remote]), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.count == 1)
        #expect(local.first?.name == "Transport")
        #expect(local.first?.isServerPredefined == true)
        #expect(local.first?.isPredefined == true)
    }

    // MARK: - Insert uses palette color when key is known

    @Test func testPullUsespaletteColorForKnownKey() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = PredefinedCategoryPullHandler()
        let predefined = PredefinedCategory.foodDining
        let remote = apiPredefined(key: predefined.serverKey, color: "#FFFFFF")

        try await handler.pull(api: makeAPIClient(predefined: [remote]), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.first?.color == predefined.paletteHex)
    }

    // MARK: - Insert uses server color when key is unknown

    @Test func testPullUsesServerColorForUnknownKey() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let handler = PredefinedCategoryPullHandler()
        let serverColor = "#ABCDEF"
        let remote = apiPredefined(key: "future-unknown-key", color: serverColor)

        try await handler.pull(api: makeAPIClient(predefined: [remote]), changeQueue: makeChangeQueue(), context: context)

        let local = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(local.first?.color == serverColor)
    }

    // MARK: - LWW: server wins when newer

    @Test func testPullAppliesServerUpdateWhenNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let predefined = PredefinedCategory.transport
        let old = Date(timeIntervalSinceNow: -3600)
        let newer = Date(timeIntervalSinceNow: -10)

        let existing = Money_Manager.Category(
            key: predefined.serverKey, name: "OldName", icon: "car",
            color: "#000", isPredefined: true, isServerPredefined: true
        )
        existing.updatedAt = old
        context.insert(existing)
        try context.save()

        let remote = apiPredefined(key: predefined.serverKey, name: "NewName", updatedAt: newer)
        try await PredefinedCategoryPullHandler().pull(
            api: makeAPIClient(predefined: [remote]), changeQueue: makeChangeQueue(), context: context
        )

        let all = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(all.count == 1)
        #expect(all.first?.name == "NewName")
    }

    // MARK: - LWW: local wins when newer (but color always migrated)

    @Test func testPullKeepsLocalNameWhenLocalIsNewer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let predefined = PredefinedCategory.transport
        let newer = Date(timeIntervalSinceNow: -10)
        let older = Date(timeIntervalSinceNow: -3600)

        let existing = Money_Manager.Category(
            key: predefined.serverKey, name: "LocalName", icon: "car",
            color: "#000", isPredefined: true, isServerPredefined: true
        )
        existing.updatedAt = newer
        context.insert(existing)
        try context.save()

        let remote = apiPredefined(key: predefined.serverKey, name: "ServerName", updatedAt: older)
        try await PredefinedCategoryPullHandler().pull(
            api: makeAPIClient(predefined: [remote]), changeQueue: makeChangeQueue(), context: context
        )

        let all = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(all.count == 1)
        #expect(all.first?.name == "LocalName")
        // Color always migrated to palette hex even when LWW keeps local
        #expect(all.first?.color == predefined.paletteHex)
    }

    // MARK: - Admin-delete purge: row not returned by server is deleted

    @Test func testPullPurgesPredefinedRowNotOnServer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let stale = Money_Manager.Category(
            key: "old-key", name: "Old Category", icon: "trash",
            color: "#888", isPredefined: true, isServerPredefined: true
        )
        context.insert(stale)
        try context.save()

        try await PredefinedCategoryPullHandler().pull(
            api: makeAPIClient(predefined: []), changeQueue: makeChangeQueue(), context: context
        )

        let all = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(all.isEmpty)
    }

    // MARK: - Non-predefined user rows are never purged

    @Test func testPullDoesNotPurgeCustomUserCategories() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let custom = Money_Manager.Category(name: "My Custom", icon: "star", color: "#FF0000")
        custom.isPredefined = false
        context.insert(custom)
        try context.save()

        try await PredefinedCategoryPullHandler().pull(
            api: makeAPIClient(predefined: []), changeQueue: makeChangeQueue(), context: context
        )

        let all = try context.fetch(FetchDescriptor<Money_Manager.Category>())
        #expect(all.count == 1)
        #expect(all.first?.name == "My Custom")
    }

    // MARK: - lastServerCount / lastLocalCount populated after pull

    @Test func testPullSetsServerAndLocalCounts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let existing = Money_Manager.Category(
            key: "food-dining", name: "Food", icon: "fork.knife",
            color: "#FFF", isPredefined: true, isServerPredefined: true
        )
        context.insert(existing)
        try context.save()

        let remote = [apiPredefined(key: "food-dining"), apiPredefined(key: "transport")]
        let handler = PredefinedCategoryPullHandler()
        try await handler.pull(api: makeAPIClient(predefined: remote), changeQueue: makeChangeQueue(), context: context)

        #expect(handler.lastServerCount == 2)
        #expect(handler.lastLocalCount == 1)
    }
}
