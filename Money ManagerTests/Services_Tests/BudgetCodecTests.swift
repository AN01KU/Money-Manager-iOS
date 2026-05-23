import Foundation
import Testing
@testable import Money_Manager

// MARK: - Helpers

@MainActor
private func makeBudget(
    id: UUID = UUID(),
    year: Int = 2026,
    month: Int = 5,
    limit: Double = 1500
) -> MonthlyBudget {
    MonthlyBudget(id: id, year: year, month: month, limit: limit)
}

// MARK: - CSV Round-Trip

@MainActor
struct BudgetCodecCSVTests {
    private let codec = BudgetCodec()

    @Test func csvRow_hasCorrectColumnCount() {
        let row = codec.csvRow(makeBudget())
        #expect(row.count == codec.csvHeader.count)
    }

    @Test func parseCSVRow_roundTrip_preservesAllFields() throws {
        let id = UUID()
        let original = makeBudget(id: id, year: 2025, month: 11, limit: 1234.56)
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.id == id)
        #expect(parsed.year == 2025)
        #expect(parsed.month == 11)
        #expect(parsed.limit == 1234.56)
    }

    @Test func parseCSVRow_wrongColumnCount_throwsMalformedRow() {
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(["too", "few"])
        }
    }

    @Test func parseCSVRow_invalidUUID_throwsMissingField() throws {
        var row = codec.csvRow(makeBudget())
        row[0] = "not-a-uuid"
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(row)
        }
    }

    @Test func parseCSVRow_nonNumericYear_throwsMissingField() throws {
        var row = codec.csvRow(makeBudget())
        row[1] = "abc"
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(row)
        }
    }
}

// MARK: - JSON Round-Trip

@MainActor
struct BudgetCodecJSONTests {
    private let codec = BudgetCodec()

    @Test func encodeDecodeJSON_roundTrip_singleBudget() throws {
        let original = makeBudget(year: 2024, month: 3, limit: 750)
        let data = try codec.encodeJSON([original])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.count == 1)
        #expect(decoded[0].id == original.id)
        #expect(decoded[0].year == 2024)
        #expect(decoded[0].month == 3)
        #expect(decoded[0].limit == 750)
    }

    @Test func encodeDecodeJSON_roundTrip_multipleBudgets() throws {
        let budgets = [
            makeBudget(month: 1, limit: 100),
            makeBudget(month: 2, limit: 200),
            makeBudget(month: 3, limit: 300)
        ]
        let data = try codec.encodeJSON(budgets)
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.count == 3)
        let limits = decoded.map(\.limit).sorted()
        #expect(limits == [100, 200, 300])
    }

    @Test func encodeDecodeJSON_emptyArray_roundTrips() throws {
        let data = try codec.encodeJSON([])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.isEmpty)
    }
}

// MARK: - BackupService integration

@MainActor
struct BudgetCodecSectionIntegrationTests {
    private let codec = BudgetCodec()

    @Test func csvSection_entityName_isBudgets() {
        let section = BackupService.csvSection(codec, models: [])
        #expect(section.hasPrefix("# budgets\n"))
    }

    @Test func csvSection_roundTrip_parseSectionYieldsOriginalIds() throws {
        let ids = [UUID(), UUID(), UUID()]
        let budgets = ids.enumerated().map { i, id in
            makeBudget(id: id, month: i + 1, limit: Double(i + 1) * 100)
        }
        let section = BackupService.csvSection(codec, models: budgets)
        let parsed = BackupService.parseCSVSections(section)
        let rows = try parsed["budgets"]?.map { try codec.parseCSVRow($0) } ?? []
        #expect(rows.map(\.id) == ids)
        #expect(rows.map(\.limit) == [100, 200, 300])
    }
}
