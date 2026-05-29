import Foundation
import Testing
@testable import Money_Manager

// MARK: - Helpers

@MainActor
private func makeCategory(
    id: UUID = UUID(),
    key: String = "food-dining",
    name: String = "Food",
    icon: String = "fork.knife",
    color: String = "#FF0000",
    isHidden: Bool = false,
    isPredefined: Bool = false,
    predefinedKey: String? = nil,
    isServerPredefined: Bool = false
) -> Money_Manager.Category {
    let cat = Money_Manager.Category(
        id: id,
        key: key,
        name: name,
        icon: icon,
        color: color,
        isPredefined: isPredefined,
        predefinedKey: predefinedKey,
        isServerPredefined: isServerPredefined
    )
    cat.isHidden = isHidden
    return cat
}

// MARK: - CSV Round-Trip

@MainActor
struct CategoryCodecCSVTests {
    private let codec = CategoryCodec()

    @Test func csvRow_hasCorrectColumnCount() {
        let row = codec.csvRow(makeCategory())
        #expect(row.count == codec.csvHeader.count)
    }

    @Test func parseCSVRow_roundTrip_preservesAllFields() throws {
        let id = UUID()
        let original = makeCategory(
            id: id,
            key: "groceries",
            name: "Groceries",
            icon: "cart.fill",
            color: "#00FF00",
            isHidden: true,
            isPredefined: true,
            predefinedKey: "groceries",
            isServerPredefined: true
        )
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.id == id)
        #expect(parsed.key == "groceries")
        #expect(parsed.name == "Groceries")
        #expect(parsed.icon == "cart.fill")
        #expect(parsed.color == "#00FF00")
        #expect(parsed.isHidden == true)
        #expect(parsed.isPredefined == true)
        #expect(parsed.predefinedKey == "groceries")
        #expect(parsed.isServerPredefined == true)
    }

    @Test func parseCSVRow_nilPredefinedKey_parsesAsNil() throws {
        let original = makeCategory(predefinedKey: nil)
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.predefinedKey == nil)
    }

    @Test func parseCSVRow_wrongColumnCount_throwsMalformedRow() {
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(["too", "few"])
        }
    }

    @Test func parseCSVRow_invalidUUID_throwsMissingField() throws {
        var row = codec.csvRow(makeCategory())
        row[0] = "not-a-uuid"
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(row)
        }
    }

    @Test func csvRow_nameWithComma_handledByEscaping() throws {
        let original = makeCategory(name: "Food, Drink")
        let section = BackupService.csvSection(codec, models: [original])
        let parsed = BackupService.parseCSVSections(section)
        let rows = try parsed["categories"]?.map { try codec.parseCSVRow($0) } ?? []
        #expect(rows.first?.name == "Food, Drink")
    }
}

// MARK: - JSON Round-Trip

@MainActor
struct CategoryCodecJSONTests {
    private let codec = CategoryCodec()

    @Test func encodeDecodeJSON_roundTrip_singleCategory() throws {
        let original = makeCategory(name: "Travel", icon: "airplane", color: "#0000FF")
        let data = try codec.encodeJSON([original])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.count == 1)
        #expect(decoded[0].id == original.id)
        #expect(decoded[0].name == "Travel")
        #expect(decoded[0].icon == "airplane")
        #expect(decoded[0].color == "#0000FF")
    }

    @Test func encodeDecodeJSON_roundTrip_preservesPredefinedFlags() throws {
        let original = makeCategory(
            isHidden: true,
            isPredefined: true,
            predefinedKey: "food-dining",
            isServerPredefined: true
        )
        let data = try codec.encodeJSON([original])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded[0].isHidden == true)
        #expect(decoded[0].isPredefined == true)
        #expect(decoded[0].predefinedKey == "food-dining")
        #expect(decoded[0].isServerPredefined == true)
    }

    @Test func encodeDecodeJSON_emptyArray_roundTrips() throws {
        let data = try codec.encodeJSON([])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.isEmpty)
    }
}

// MARK: - BackupService integration

@MainActor
struct CategoryCodecSectionIntegrationTests {
    private let codec = CategoryCodec()

    @Test func csvSection_entityName_isCategories() {
        let section = BackupService.csvSection(codec, models: [])
        #expect(section.hasPrefix("# categories\n"))
    }

    @Test func csvSection_roundTrip_parseSectionYieldsOriginalIds() throws {
        let ids = [UUID(), UUID(), UUID()]
        let categories = ids.enumerated().map { i, id in
            makeCategory(id: id, name: "Cat\(i)")
        }
        let section = BackupService.csvSection(codec, models: categories)
        let parsed = BackupService.parseCSVSections(section)
        let rows = try parsed["categories"]?.map { try codec.parseCSVRow($0) } ?? []
        #expect(rows.map(\.id) == ids)
        #expect(rows.map(\.name) == ["Cat0", "Cat1", "Cat2"])
    }
}
