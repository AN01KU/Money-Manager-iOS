import Foundation
import Testing
@testable import Money_Manager

// MARK: - CSV Section Parsing

struct BackupServiceCSVSectionTests {

    @Test func parseCSVSections_singleSection_returnsRows() {
        let csv = "# transactions\nID,Amount\nabc,100\ndef,200\n"
        let result = BackupService.parseCSVSections(csv)
        #expect(result["transactions"]?.count == 2)
        #expect(result["transactions"]?[0] == ["abc", "100"])
        #expect(result["transactions"]?[1] == ["def", "200"])
    }

    @Test func parseCSVSections_multiSection_dispatchesCorrectly() {
        let csv = "# transactions\nID,Amount\nabc,100\n# budgets\nID,Year\nxyz,2026\n"
        let result = BackupService.parseCSVSections(csv)
        #expect(result["transactions"]?.count == 1)
        #expect(result["budgets"]?.count == 1)
    }

    @Test func parseCSVSections_legacySingleSection_wrappedAsTransactions() {
        // No `# ` section header — legacy format auto-wrapped in "# transactions".
        let csv = "ID,Amount,Category,Date\nabc,100,Food,2026-01-01T00:00:00.000Z\n"
        let result = BackupService.parseCSVSections(csv)
        #expect(result["transactions"]?.count == 1)
    }

    @Test func parseCSVSections_emptySection_skipped() {
        let csv = "# transactions\nID,Amount\n# budgets\nID,Year\nxyz,2026\n"
        let result = BackupService.parseCSVSections(csv)
        // transactions has only a header row (no data rows), should be absent or empty
        let txRows = result["transactions"] ?? []
        #expect(txRows.isEmpty)
        #expect(result["budgets"]?.count == 1)
    }

    @Test func parseCSVSections_sectionNamesAreLowercased() {
        let csv = "# TRANSACTIONS\nID,Amount\nabc,100\n"
        let result = BackupService.parseCSVSections(csv)
        #expect(result["transactions"] != nil)
        #expect(result["TRANSACTIONS"] == nil)
    }
}

// MARK: - CSV Line Parsing

struct BackupServiceCSVLineTests {

    @Test func parseCSVLine_plainFields_splitOnComma() {
        let fields = BackupService.parseCSVLine("a,b,c")
        #expect(fields == ["a", "b", "c"])
    }

    @Test func parseCSVLine_quotedFieldWithComma_treatedAsSingleField() {
        let fields = BackupService.parseCSVLine("a,\"b,c\",d")
        #expect(fields == ["a", "b,c", "d"])
    }

    @Test func parseCSVLine_escapedQuoteInsideField_unescaped() {
        let fields = BackupService.parseCSVLine("\"say \"\"hi\"\"\"")
        #expect(fields == ["say \"hi\""])
    }

    @Test func parseCSVLine_emptyField_includedAsEmpty() {
        let fields = BackupService.parseCSVLine("a,,c")
        #expect(fields == ["a", "", "c"])
    }

    @Test func parseCSVLine_singleField_returned() {
        let fields = BackupService.parseCSVLine("hello")
        #expect(fields == ["hello"])
    }
}

// MARK: - CSV Escaping

struct BackupServiceCSVEscapeTests {

    @Test func escapeCSVField_plain_unchanged() {
        #expect(BackupService.escapeCSVField("hello") == "hello")
    }

    @Test func escapeCSVField_withComma_quoted() {
        #expect(BackupService.escapeCSVField("a,b") == "\"a,b\"")
    }

    @Test func escapeCSVField_withQuote_escaped() {
        #expect(BackupService.escapeCSVField("say \"hi\"") == "\"say \"\"hi\"\"\"")
    }

    @Test func escapeCSVField_withNewline_quoted() {
        #expect(BackupService.escapeCSVField("line1\nline2") == "\"line1\nline2\"")
    }

    @Test func escapeCSVRow_multipleFields_joinedWithCommas() {
        let row = BackupService.escapeCSVRow(["a", "b,c", "d"])
        #expect(row == "a,\"b,c\",d")
    }
}

// MARK: - Date Parsing

struct BackupServiceDateTests {

    @Test func parseDate_iso8601WithFractionalSeconds_succeeds() {
        let result = BackupService.parseDate("2026-01-15T10:30:00.000Z")
        #expect(result != nil)
    }

    @Test func parseDate_invalidString_returnsNil() {
        let result = BackupService.parseDate("not-a-date")
        #expect(result == nil)
    }

    @Test func parseDate_roundTrip_iso8601() {
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        let string = BackupService.iso8601.string(from: original)
        let parsed = BackupService.parseDate(string)
        #expect(parsed != nil)
        // Allow 1s tolerance for fractional seconds rounding.
        #expect(abs((parsed?.timeIntervalSince1970 ?? 0) - original.timeIntervalSince1970) < 1)
    }
}

// MARK: - BackupService.csvSection

struct BackupServiceCSVSectionBuilderTests {

    // Minimal stub codec for testing section building
    private struct IntCodec: EntityCodec {
        typealias Model = Int
        nonisolated let entityName = "ints"
        nonisolated let csvHeader = ["Value"]
        nonisolated func csvRow(_ model: Int) -> [String] { [String(model)] }
        nonisolated func parseCSVRow(_ values: [String]) throws -> Int {
            guard let v = values.first, let n = Int(v) else { throw EntityCodecError.malformedRow("bad int") }
            return n
        }
        nonisolated func encodeJSON(_ models: [Int]) throws -> Data { try JSONEncoder().encode(models) }
        nonisolated func decodeJSON(_ data: Data) throws -> [Int] { try JSONDecoder().decode([Int].self, from: data) }
    }

    @Test func csvSection_producesCorrectSectionHeader() {
        let codec = IntCodec()
        let section = BackupService.csvSection(codec, models: [1, 2])
        #expect(section.hasPrefix("# ints\n"))
    }

    @Test func csvSection_producesHeaderRow() {
        let codec = IntCodec()
        let section = BackupService.csvSection(codec, models: [1])
        let lines = section.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines[1] == "Value")
    }

    @Test func csvSection_producesDataRows() {
        let codec = IntCodec()
        let section = BackupService.csvSection(codec, models: [42, 99])
        let lines = section.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.count == 4) // # ints, Value, 42, 99
        #expect(lines[2] == "42")
        #expect(lines[3] == "99")
    }

    @Test func csvSection_roundTrip_parseSectionYieldsOriginalRows() throws {
        let codec = IntCodec()
        let section = BackupService.csvSection(codec, models: [1, 2, 3])
        let parsed = BackupService.parseCSVSections(section)
        let rows = try parsed["ints"]?.map { try codec.parseCSVRow($0) } ?? []
        #expect(rows == [1, 2, 3])
    }
}

// MARK: - EntityCodecError

struct EntityCodecErrorTests {

    @Test func malformedRowError_hasDescription() {
        let error = EntityCodecError.malformedRow("bad data")
        if case .malformedRow(let msg) = error {
            #expect(msg == "bad data")
        } else {
            Issue.record("Expected malformedRow")
        }
    }

    @Test func missingFieldError_hasDescription() {
        let error = EntityCodecError.missingField("id")
        if case .missingField(let field) = error {
            #expect(field == "id")
        } else {
            Issue.record("Expected missingField")
        }
    }
}
