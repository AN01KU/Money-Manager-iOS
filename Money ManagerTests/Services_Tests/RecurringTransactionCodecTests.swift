import Foundation
import Testing
@testable import Money_Manager

// MARK: - Helpers

private func makeRecurring(
    id: UUID = UUID(),
    name: String = "Netflix",
    amount: Double = 649,
    category: String = "Entertainment",
    frequency: RecurringFrequency = .monthly,
    dayOfMonth: Int? = 1,
    daysOfWeek: [Int]? = nil,
    startDate: Date = Date(timeIntervalSince1970: 1_700_000_000),
    endDate: Date? = nil,
    isActive: Bool = true,
    lastAddedDate: Date? = nil,
    notes: String? = nil,
    categoryId: UUID? = nil,
    type: TransactionKind = .expense
) -> RecurringTransaction {
    RecurringTransaction(
        id: id,
        name: name,
        amount: amount,
        category: category,
        frequency: frequency,
        dayOfMonth: dayOfMonth,
        daysOfWeek: daysOfWeek,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        lastAddedDate: lastAddedDate,
        notes: notes,
        categoryId: categoryId,
        type: type
    )
}

// MARK: - CSV Round-Trip

@MainActor
struct RecurringTransactionCodecCSVTests {
    private let codec = RecurringTransactionCodec()

    @Test func csvRow_hasCorrectColumnCount() {
        let model = makeRecurring()
        let row = codec.csvRow(model)
        #expect(row.count == codec.csvHeader.count)
    }

    @Test func parseCSVRow_roundTrip_basicFields() throws {
        let original = makeRecurring(
            name: "Gym",
            amount: 500,
            category: "Health",
            frequency: .monthly,
            dayOfMonth: 15,
            startDate: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.id == original.id)
        #expect(parsed.name == original.name)
        #expect(parsed.amount == original.amount)
        #expect(parsed.category == original.category)
        #expect(parsed.frequency == original.frequency)
        #expect(parsed.dayOfMonth == original.dayOfMonth)
        #expect(abs(parsed.startDate.timeIntervalSince1970 - original.startDate.timeIntervalSince1970) < 1)
        #expect(parsed.isActive == original.isActive)
    }

    @Test func parseCSVRow_roundTrip_allOptionalFields() throws {
        let cid = UUID()
        let endDate = Date(timeIntervalSince1970: 1_800_000_000)
        let lastAdded = Date(timeIntervalSince1970: 1_750_000_000)
        let original = makeRecurring(
            frequency: .weekly,
            dayOfMonth: nil,
            daysOfWeek: [1, 3, 5],
            endDate: endDate,
            lastAddedDate: lastAdded,
            notes: "MWF schedule",
            categoryId: cid,
            type: .income
        )
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.daysOfWeek == [1, 3, 5])
        #expect(parsed.dayOfMonth == nil)
        #expect(parsed.endDate != nil)
        #expect(parsed.lastAddedDate != nil)
        #expect(parsed.notes == "MWF schedule")
        #expect(parsed.categoryId == cid)
        #expect(parsed.type == .income)
    }

    @Test func parseCSVRow_nilOptionalFields_parseAsNil() throws {
        let original = makeRecurring(
            dayOfMonth: nil,
            daysOfWeek: nil,
            endDate: nil,
            lastAddedDate: nil,
            notes: nil,
            categoryId: nil
        )
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.dayOfMonth == nil)
        #expect(parsed.daysOfWeek == nil)
        #expect(parsed.endDate == nil)
        #expect(parsed.lastAddedDate == nil)
        #expect(parsed.notes == nil)
        #expect(parsed.categoryId == nil)
    }

    @Test func parseCSVRow_wrongColumnCount_throwsMalformedRow() {
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(["too", "few"])
        }
    }

    @Test func parseCSVRow_missingId_throwsMissingField() throws {
        var row = codec.csvRow(makeRecurring())
        row[0] = "not-a-uuid"
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(row)
        }
    }

    @Test func parseCSVRow_missingStartDate_throwsMissingField() throws {
        var row = codec.csvRow(makeRecurring())
        row[7] = "not-a-date"
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(row)
        }
    }

    @Test func csvRow_daysOfWeek_joinedBySemicolon() {
        let model = makeRecurring(daysOfWeek: [2, 4, 6])
        let row = codec.csvRow(model)
        #expect(row[6] == "2;4;6")
    }

    @Test func csvRow_incomeType_encodedAsIncome() {
        let model = makeRecurring(type: .income)
        let row = codec.csvRow(model)
        // type is at index 12
        #expect(row[12] == "income")
    }

    @Test func csvRow_nameContainingComma_handledByEscaping() throws {
        let model = makeRecurring(name: "Food, Drink")
        let row = codec.csvRow(model)
        #expect(row[1] == "Food, Drink")
        // Round-trip via section
        let section = BackupService.csvSection(codec, models: [model])
        let parsed = BackupService.parseCSVSections(section)
        let rows = try parsed["recurring transactions"]?.map { try codec.parseCSVRow($0) } ?? []
        #expect(rows.first?.name == "Food, Drink")
    }
}

// MARK: - JSON Round-Trip

@MainActor
struct RecurringTransactionCodecJSONTests {
    private let codec = RecurringTransactionCodec()

    @Test func encodeDecodeJSON_roundTrip_basicFields() throws {
        let original = makeRecurring(name: "Gym", amount: 500, category: "Health")
        let data = try codec.encodeJSON([original])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.count == 1)
        #expect(decoded[0].id == original.id)
        #expect(decoded[0].name == original.name)
        #expect(decoded[0].amount == original.amount)
        #expect(decoded[0].category == original.category)
    }

    @Test func encodeDecodeJSON_roundTrip_multipleModels() throws {
        let models = [
            makeRecurring(name: "A", amount: 100),
            makeRecurring(name: "B", amount: 200),
            makeRecurring(name: "C", amount: 300)
        ]
        let data = try codec.encodeJSON(models)
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.count == 3)
        let names = decoded.map(\.name).sorted()
        #expect(names == ["A", "B", "C"])
    }

    @Test func encodeDecodeJSON_roundTrip_emptyArray() throws {
        let data = try codec.encodeJSON([])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.isEmpty)
    }

    @Test func encodeDecodeJSON_roundTrip_allOptionalFields() throws {
        let cid = UUID()
        let original = makeRecurring(
            daysOfWeek: [1, 3],
            endDate: Date(timeIntervalSince1970: 1_800_000_000),
            lastAddedDate: Date(timeIntervalSince1970: 1_750_000_000),
            notes: "Recurring note",
            categoryId: cid,
            type: .income
        )
        let data = try codec.encodeJSON([original])
        let decoded = try codec.decodeJSON(data)
        let d = decoded[0]
        #expect(d.daysOfWeek == [1, 3])
        #expect(d.endDate != nil)
        #expect(d.lastAddedDate != nil)
        #expect(d.notes == "Recurring note")
        #expect(d.categoryId == cid)
        #expect(d.type == .income)
    }
}

// MARK: - BackupService integration

@MainActor
struct RecurringTransactionCodecSectionIntegrationTests {
    private let codec = RecurringTransactionCodec()

    @Test func csvSection_entityName_isRecurringTransactions() {
        let section = BackupService.csvSection(codec, models: [])
        #expect(section.hasPrefix("# recurring transactions\n"))
    }

    @Test func csvSection_roundTrip_parseSectionYieldsOriginalIds() throws {
        let ids = [UUID(), UUID(), UUID()]
        let models = ids.map { makeRecurring(id: $0) }
        let section = BackupService.csvSection(codec, models: models)
        let parsed = BackupService.parseCSVSections(section)
        let rows = try parsed["recurring transactions"]?.map { try codec.parseCSVRow($0) } ?? []
        #expect(rows.map(\.id) == ids)
    }
}
