import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct TransactionCategoryTests {

    // MARK: - merge(overrides:) — id construction

    @Test
    func mergePredefinedFromEnumProducesIdEqualToServerKey() {
        // No server-predefined rows → enum fallback path.
        let merged = TransactionCategory.merge(overrides: [])
        let food = try? #require(merged.first { $0.key == PredefinedCategory.foodDining.serverKey })

        #expect(food?.id == PredefinedCategory.foodDining.serverKey)
    }

    @Test
    func mergeServerPredefinedProducesIdEqualToServerKey() {
        let serverRow = Category(
            key: "food-dining",
            name: "Food & Dining",
            icon: "fork.knife",
            color: "#FF6B6B",
            isPredefined: true,
            predefinedKey: "food-dining",
            isServerPredefined: true
        )

        let merged = TransactionCategory.merge(overrides: [serverRow])
        let food = try? #require(merged.first { $0.key == "food-dining" })

        #expect(food?.id == "food-dining")
    }

    @Test
    func mergeCustomWithServerKeyProducesIdEqualToServerKey() {
        let custom = Category(
            key: "ankush-cc-1234",
            name: "Subscriptions",
            icon: "creditcard",
            color: "#123456"
        )

        let merged = TransactionCategory.merge(overrides: [custom])
        let row = try? #require(merged.first { !$0.isPredefined })

        #expect(row?.id == "ankush-cc-1234")
    }

    @Test
    func mergeCustomWithoutKeyFallsBackToUuidStringWithoutPrefix() {
        let id = UUID()
        let custom = Category(
            id: id,
            key: "",
            name: "Local Only",
            icon: "questionmark",
            color: "#FFFFFF"
        )

        let merged = TransactionCategory.merge(overrides: [custom])
        let row = try? #require(merged.first { !$0.isPredefined })

        #expect(row?.id == id.uuidString)
    }

    @Test
    func mergeProducesNoPrefixedIdsAcrossAllSources() {
        let serverRow = Category(
            key: "transportation",
            name: "Transport",
            icon: "car",
            color: "#000000",
            isPredefined: true,
            predefinedKey: "transportation",
            isServerPredefined: true
        )
        let override = Category(
            key: "transportation",
            name: "Transport (mine)",
            icon: "car.fill",
            color: "#111111",
            isPredefined: true,
            predefinedKey: "transportation"
        )
        let custom = Category(
            key: "ankush-cc-9999",
            name: "Coffee",
            icon: "cup.and.saucer",
            color: "#222222"
        )
        let unsyncedCustom = Category(
            key: "",
            name: "Drafts",
            icon: "pencil",
            color: "#333333"
        )

        let merged = TransactionCategory.merge(overrides: [serverRow, override, custom, unsyncedCustom])

        for entry in merged {
            #expect(!entry.id.hasPrefix("predefined:"), "id \(entry.id) must not have predefined: prefix")
            #expect(!entry.id.hasPrefix("custom:"), "id \(entry.id) must not have custom: prefix")
            #expect(!entry.id.hasPrefix("local:"), "id \(entry.id) must not have local: prefix")
        }
    }
}
