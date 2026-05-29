import Foundation
import Testing
@testable import Money_Manager

// MARK: - Helpers

@MainActor
private func makeTransaction(
    id: UUID = UUID(),
    type: TransactionKind = .expense,
    amount: Double = 42.50,
    categoryId: UUID = UUID(),
    date: Date = Date(timeIntervalSince1970: 1_700_000_000),
    time: Date? = nil,
    description: String? = nil,
    notes: String? = nil,
    recurringExpenseId: UUID? = nil,
    groupTransactionId: UUID? = nil,
    groupName: String? = nil,
    groupId: UUID? = nil,
    settlementId: UUID? = nil
) -> Transaction {
    let tx = Transaction(
        id: id,
        type: type,
        amount: amount,
        categoryId: categoryId,
        date: date,
        time: time,
        transactionDescription: description,
        notes: notes,
        recurringExpenseId: recurringExpenseId,
        groupTransactionId: groupTransactionId,
        settlementId: settlementId
    )
    tx.groupName = groupName
    tx.groupId = groupId
    return tx
}

// MARK: - CSV Round-Trip

@MainActor
struct TransactionCodecCSVTests {
    private let codec = TransactionCodec()

    @Test func csvRow_hasCorrectColumnCount() {
        let tx = makeTransaction()
        let row = codec.csvRow(tx)
        #expect(row.count == codec.csvHeader.count)
    }

    @Test func parseCSVRow_roundTrip_basicTransaction() throws {
        let cid = UUID()
        let original = makeTransaction(
            amount: 12.99,
            categoryId: cid,
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.id == original.id)
        #expect(parsed.type == original.type)
        #expect(parsed.amount == original.amount)
        #expect(parsed.categoryId == cid)
        #expect(abs(parsed.date.timeIntervalSince1970 - original.date.timeIntervalSince1970) < 1)
    }

    @Test func parseCSVRow_roundTrip_allOptionalFields() throws {
        let gid = UUID()
        let gtid = UUID()
        let rid = UUID()
        let sid = UUID()
        let cid = UUID()
        let original = makeTransaction(
            type: .income,
            amount: 500,
            categoryId: cid,
            description: "Salary",
            notes: "Monthly",
            recurringExpenseId: rid,
            groupTransactionId: gtid,
            groupName: "Family",
            groupId: gid,
            settlementId: sid
        )
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.type == .income)
        #expect(parsed.transactionDescription == "Salary")
        #expect(parsed.notes == "Monthly")
        #expect(parsed.recurringExpenseId == rid)
        #expect(parsed.groupTransactionId == gtid)
        #expect(parsed.groupName == "Family")
        #expect(parsed.groupId == gid)
        #expect(parsed.settlementId == sid)
        #expect(parsed.categoryId == cid)
    }

    @Test func parseCSVRow_nilOptionalFields_parseAsNil() throws {
        let original = makeTransaction()
        let row = codec.csvRow(original)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.time == nil)
        #expect(parsed.transactionDescription == nil)
        #expect(parsed.notes == nil)
        #expect(parsed.recurringExpenseId == nil)
        #expect(parsed.groupTransactionId == nil)
        #expect(parsed.groupName == nil)
        #expect(parsed.groupId == nil)
        #expect(parsed.settlementId == nil)
    }

    @Test func parseCSVRow_wrongColumnCount_throwsMalformedRow() {
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(["too", "few"])
        }
    }

    @Test func parseCSVRow_missingId_throwsMissingField() throws {
        var row = codec.csvRow(makeTransaction())
        row[0] = "not-a-uuid"
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(row)
        }
    }

    @Test func parseCSVRow_missingDate_throwsMissingField() throws {
        var row = codec.csvRow(makeTransaction())
        row[4] = "not-a-date"
        #expect(throws: EntityCodecError.self) {
            try codec.parseCSVRow(row)
        }
    }

    @Test func csvRow_groupNameReadsDirectlyFromModel() {
        let tx = makeTransaction(groupName: "Trip Expenses")
        let row = codec.csvRow(tx)
        #expect(row[10] == "Trip Expenses")
    }

    @Test func csvRow_incomeType_encodedAsIncome() {
        let tx = makeTransaction(type: .income)
        let row = codec.csvRow(tx)
        #expect(row[1] == "income")
    }
}

// MARK: - JSON Round-Trip

@MainActor
struct TransactionCodecJSONTests {
    private let codec = TransactionCodec()

    @Test func encodeDecodeJSON_roundTrip_basicTransaction() throws {
        let cid = UUID()
        let original = makeTransaction(amount: 99.99, categoryId: cid)
        let data = try codec.encodeJSON([original])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.count == 1)
        #expect(decoded[0].id == original.id)
        #expect(decoded[0].amount == original.amount)
        #expect(decoded[0].categoryId == cid)
    }

    @Test func encodeDecodeJSON_roundTrip_multipleTransactions() throws {
        let transactions = [
            makeTransaction(amount: 10),
            makeTransaction(amount: 20),
            makeTransaction(amount: 30)
        ]
        let data = try codec.encodeJSON(transactions)
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.count == 3)
        let amounts = decoded.map(\.amount).sorted()
        #expect(amounts == [10, 20, 30])
    }

    @Test func encodeDecodeJSON_roundTrip_groupNamePreserved() throws {
        let original = makeTransaction(groupName: "Weekend Trip", groupId: UUID())
        let data = try codec.encodeJSON([original])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.first?.groupName == "Weekend Trip")
        #expect(decoded.first?.groupId == original.groupId)
    }

    @Test func encodeDecodeJSON_emptyArray_roundTrips() throws {
        let data = try codec.encodeJSON([])
        let decoded = try codec.decodeJSON(data)
        #expect(decoded.isEmpty)
    }
}

// MARK: - BackupService integration

@MainActor
struct TransactionCodecSectionIntegrationTests {
    private let codec = TransactionCodec()

    @Test func csvSection_entityName_isTransactions() {
        let section = BackupService.csvSection(codec, models: [])
        #expect(section.hasPrefix("# transactions\n"))
    }

    @Test func csvSection_roundTrip_parseSectionYieldsOriginalIds() throws {
        let ids = [UUID(), UUID(), UUID()]
        let transactions = ids.map { makeTransaction(id: $0) }
        let section = BackupService.csvSection(codec, models: transactions)
        let parsed = BackupService.parseCSVSections(section)
        let rows = try parsed["transactions"]?.map { try codec.parseCSVRow($0) } ?? []
        #expect(rows.map(\.id) == ids)
    }
}
