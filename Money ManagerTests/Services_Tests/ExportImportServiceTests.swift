import Foundation
import SwiftData
import Testing
@testable import Money_Manager

// MARK: - ExportService Tests

@MainActor
struct ExportServiceTests {
    private let service = ExportService()

    // MARK: CSV escaping

    @Test func escapeCSV_plainString_unchanged() {
        #expect(service.escapeCSV("hello") == "hello")
    }

    @Test func escapeCSV_stringWithComma_quoted() {
        #expect(service.escapeCSV("a,b") == "\"a,b\"")
    }

    @Test func escapeCSV_stringWithQuote_escaped() {
        #expect(service.escapeCSV("say \"hi\"") == "\"say \"\"hi\"\"\"")
    }

    @Test func escapeCSV_stringWithNewline_quoted() {
        #expect(service.escapeCSV("line1\nline2") == "\"line1\nline2\"")
    }

    // MARK: CSV export — categories

    @Test func exportCategoriesCSV_producesCorrectHeaders() throws {
        let cat = Category(name: "Travel", icon: "airplane", color: "#FF0000")
        let url = try service.exportCategories(format: .csv, categories: [cat])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.hasPrefix("ID,Name,Icon,Color,Is Hidden,Is Predefined,Predefined Key"))
    }

    @Test func exportCategoriesCSV_oneRow_correctValues() throws {
        let cat = Category(name: "Health", icon: "heart.fill", color: "#00FF00")
        let url = try service.exportCategories(format: .csv, categories: [cat])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("Health"))
        #expect(content.contains("heart.fill"))
        #expect(content.contains("#00FF00"))
    }

    // MARK: JSON export — exportAll round-trip structure

    @Test func exportAllJSON_containsAllSections() throws {
        let tx = Transaction(amount: 100, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 1, limit: 3000)
        let cat = Category(name: "Fun", icon: "star.fill", color: "#AAAAAA")
        let url = try service.exportAll(format: .json, transactions: [tx], recurringTransactions: [], budgets: [budget], categories: [cat])

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exported = try decoder.decode(ExportData.self, from: data)

        #expect(exported.transactions?.count == 1)
        #expect(exported.budgets?.count == 1)
        #expect(exported.categories?.count == 1)
    }
}

// MARK: - ImportService Tests

@MainActor
struct ImportServiceTests {
    private let service = ImportService()

    // MARK: CSV line parsing

    @Test func parseCSVLine_simple() {
        let result = service.parseCSVLine("a,b,c")
        #expect(result == ["a", "b", "c"])
    }

    @Test func parseCSVLine_quotedFieldWithComma() {
        let result = service.parseCSVLine("\"hello, world\",b")
        #expect(result == ["hello, world", "b"])
    }

    @Test func parseCSVLine_emptyField() {
        let result = service.parseCSVLine("a,,c")
        #expect(result == ["a", "", "c"])
    }

    @Test func parseCSVLine_trailingWhitespace_trimmed() {
        let result = service.parseCSVLine(" a , b ")
        #expect(result == ["a", "b"])
    }

    // MARK: Row parsers

    @Test func parseTransactionCSVRow_missingColumn_returnsNil() {
        let result = service.parseTransactionCSVRow(["only-one"], headers: ["id", "amount"])
        #expect(result == nil)
    }

    @Test func parseTransactionCSVRow_validRow_correctValues() {
        let headers = ["id", "amount", "category", "date", "time", "description", "notes", "recurring transaction id", "group id", "group name"]
        let values  = [UUID().uuidString, "450.0", "Food", "2026-01-15T10:00:00.000Z", "", "Lunch", "", "", "", ""]
        let result = service.parseTransactionCSVRow(values, headers: headers)
        #expect(result != nil)
        #expect(result?.amount == 450.0)
        #expect(result?.category == "Food")
        #expect(result?.transactionDescription == "Lunch")
    }

    @Test func parseBudgetCSVRow_missingColumn_returnsNil() {
        let result = service.parseBudgetCSVRow(["only"], headers: ["id", "year"])
        #expect(result == nil)
    }

    @Test func parseBudgetCSVRow_validRow_correctValues() {
        let id = UUID().uuidString
        let headers = ["id", "year", "month", "limit"]
        let values  = [id, "2026", "3", "5000.0"]
        let result = service.parseBudgetCSVRow(values, headers: headers)
        #expect(result?.year == 2026)
        #expect(result?.month == 3)
        #expect(result?.limit == 5000.0)
    }

    @Test func parseCategoryCSVRow_missingColumn_returnsNil() {
        let result = service.parseCategoryCSVRow(["only"], headers: ["id", "name"])
        #expect(result == nil)
    }

    @Test func parseCategoryCSVRow_validRow_correctValues() {
        let headers = ["id", "name", "icon", "color", "is hidden", "is predefined", "predefined key"]
        let values  = [UUID().uuidString, "Travel", "airplane", "#123456", "false", "false", ""]
        let result = service.parseCategoryCSVRow(values, headers: headers)
        #expect(result?.name == "Travel")
        #expect(result?.icon == "airplane")
        #expect(result?.isHidden == false)
    }

    // MARK: JSON import round-trip

    @Test func importJSON_roundTrip_transactions() throws {
        // Export via TransactionCodec (new path)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tx = Transaction(amount: 300, category: "Transport", date: date, transactionDescription: "Cab")
        let codec = TransactionCodec()
        let jsonData = try codec.encodeJSON([tx])
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_tx_roundtrip.json")
        try jsonData.write(to: tmpURL)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        // TransactionCodec JSON is a plain array — import via codec decode, not ImportService
        let decoded = try codec.decodeJSON(jsonData)
        #expect(decoded.count == 1)
        #expect(decoded[0].amount == 300)
        #expect(decoded[0].category == "Transport")
        #expect(decoded[0].transactionDescription == "Cab")
    }

    @Test func importJSON_roundTrip_categories() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let cat = Category(name: "Health", icon: "heart.fill", color: "#FF0000")
        let exportService = ExportService()
        let url = try exportService.exportCategories(format: .json, categories: [cat])

        let result = try service.importJSON(from: url, context: context)
        #expect(result.message.contains("1 categories"))

        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported[0].name == "Health")
        #expect(imported[0].icon == "heart.fill")
    }

    @Test func importJSON_roundTrip_allData() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let tx = Transaction(amount: 100, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 1, limit: 5000)
        let cat = Category(name: "Fun", icon: "star.fill", color: "#AAAAAA")

        let exportService = ExportService()
        let url = try exportService.exportAll(format: .json, transactions: [tx], recurringTransactions: [], budgets: [budget], categories: [cat])

        let result = try service.importJSON(from: url, context: context)
        #expect(result.message.contains("transactions"))
        #expect(result.message.contains("budgets"))
        #expect(result.message.contains("categories"))
    }

    // MARK: CSV import round-trip

    @Test func importCSV_roundTrip_transactions() throws {
        // Transactions now export via TransactionCodec + BackupService.
        // The new CSV is section-based; verify TransactionCodec round-trip.
        let tx = Transaction(amount: 150, category: "Food", date: Date(), transactionDescription: "Breakfast")
        let codec = TransactionCodec()
        let row = codec.csvRow(tx)
        let parsed = try codec.parseCSVRow(row)
        #expect(parsed.amount == 150)
        #expect(parsed.category == "Food")
        #expect(parsed.transactionDescription == "Breakfast")
    }

    @Test func importCSV_roundTrip_allSections() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let tx = Transaction(amount: 200, category: "Transport", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 6000)
        let cat = Category(name: "Work", icon: "briefcase.fill", color: "#0000FF")

        let exportService = ExportService()
        let url = try exportService.exportAll(format: .csv, transactions: [tx], recurringTransactions: [], budgets: [budget], categories: [cat])

        let result = try service.importCSV(from: url, context: context)
        #expect(result.message.contains("transactions"))
        #expect(result.message.contains("budgets"))
        #expect(result.message.contains("categories"))
    }

    // MARK: Predefined category re-use counter

    @Test func importJSON_predefinedCategoryAlreadyExists_doesNotIncrementCounter() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Seed the context with an existing predefined-category row
        let existing = Category(name: "Food & Dining", icon: "fork.knife", color: "#FF0000", isPredefined: true, predefinedKey: "food-dining")
        context.insert(existing)
        try context.save()

        // Build export data containing the same predefined key
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            budgets: nil,
            categories: [
                ExportData.CategoryData(
                    id: existing.id.uuidString,
                    name: "Food & Dining",
                    icon: "fork.knife",
                    color: "#FF0000",
                    isHidden: false,
                    isPredefined: true,
                    predefinedKey: "food-dining"
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("predefined_reuse.json")
        try data.write(to: url)

        let result = try service.importJSON(from: url, context: context)
        // Counter must not include re-used predefined rows
        #expect(!result.message.contains("categories"), "Expected no categories in import message when re-using predefined rows, got: \(result.message)")
    }

    @Test func importJSON_mixedPredefinedAndCustom_counterReflectsOnlyNewInserts() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Seed one predefined row
        let existing = Category(name: "Transport", icon: "car.fill", color: "#0000FF", isPredefined: true, predefinedKey: "transport")
        context.insert(existing)
        try context.save()

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            budgets: nil,
            categories: [
                ExportData.CategoryData(
                    id: existing.id.uuidString,
                    name: "Transport",
                    icon: "car.fill",
                    color: "#0000FF",
                    isHidden: false,
                    isPredefined: true,
                    predefinedKey: "transport"
                ),
                ExportData.CategoryData(
                    id: UUID().uuidString,
                    name: "Hobbies",
                    icon: "paintbrush.fill",
                    color: "#00FF00",
                    isHidden: false,
                    isPredefined: false,
                    predefinedKey: nil
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mixed_categories.json")
        try data.write(to: url)

        let result = try service.importJSON(from: url, context: context)
        // Only the new custom category counts
        #expect(result.message.contains("1 categories"), "Expected '1 categories', got: \(result.message)")
    }

    // MARK: Malformed input

    @Test func importCSV_emptyFile_returnsNoDataMessage() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("empty.csv")
        try "".write(to: url, atomically: true, encoding: .utf8)

        let result = try service.importCSV(from: url, context: context)
        #expect(result.message.contains("No data found"))
    }

    @Test func importCSV_headerOnlyNoRows_returnsNoDataMessage() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("header_only.csv")
        try "ID,Amount,Category,Date,Time,Description,Notes,Recurring Transaction ID,Group ID,Group Name".write(to: url, atomically: true, encoding: .utf8)

        let result = try service.importCSV(from: url, context: context)
        #expect(result.message.contains("No data found"))
    }

    @Test func importJSON_malformedJSON_throws() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bad.json")
        try? "not json at all {{{".write(to: url, atomically: true, encoding: .utf8)

        #expect(throws: (any Error).self) {
            try service.importJSON(from: url, context: context)
        }
    }

    // MARK: Date parsing fallback

    @Test func parseDate_iso8601_parsedCorrectly() {
        let isoString = "2026-03-15T10:30:00.000Z"
        let (date, _) = service.parseDate(isoString)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 15)
    }

    @Test func parseDate_emptyString_returnsNow() {
        let before = Date()
        let (date, _) = service.parseDate("")
        let after = Date()
        #expect(date >= before)
        #expect(date <= after)
    }

    @Test func parseDate_withTimeString_returnsTime() {
        let isoDate = "2026-01-01T00:00:00.000Z"
        let isoTime = "2026-01-01T14:30:00.000Z"
        let (_, time) = service.parseDate(isoDate, isoTime)
        #expect(time != nil)
    }
}
