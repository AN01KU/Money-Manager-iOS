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

    // MARK: CSV export — transactions

    @Test func exportTransactionsCSV_producesCorrectHeaders() throws {
        let tx = Transaction(amount: 100, category: "Food", date: Date(), transactionDescription: "Lunch")
        let url = try service.exportTransactions(format: .csv, transactions: [tx], groups: [])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.hasPrefix("ID,Amount,Category,Date,Time,Description,Notes,Recurring Transaction ID,Group ID,Group Name"))
    }

    @Test func exportTransactionsCSV_oneRow_containsAmount() throws {
        let tx = Transaction(amount: 250, category: "Transport", date: Date())
        let url = try service.exportTransactions(format: .csv, transactions: [tx], groups: [])
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        #expect(lines.count == 2)
        #expect(lines[1].contains("250.0"))
        #expect(lines[1].contains("Transport"))
    }

    @Test func exportTransactionsCSV_softDeletedTransactions_excluded() throws {
        let tx = Transaction(amount: 99, category: "Other", date: Date())
        tx.isSoftDeleted = true
        let url = try service.exportTransactions(format: .csv, transactions: [tx], groups: [])
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        #expect(lines.count == 1) // header only
    }

    @Test func exportTransactionsCSV_descriptionWithComma_escapedCorrectly() throws {
        let tx = Transaction(amount: 50, category: "Food", date: Date(), transactionDescription: "Coffee, Cake")
        let url = try service.exportTransactions(format: .csv, transactions: [tx], groups: [])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("\"Coffee, Cake\""))
    }

    // MARK: CSV export — budgets

    @Test func exportBudgetsCSV_producesCorrectHeaders() throws {
        let budget = MonthlyBudget(year: 2026, month: 3, limit: 5000)
        let url = try service.exportBudgets(format: .csv, budgets: [budget])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.hasPrefix("ID,Year,Month,Limit"))
    }

    @Test func exportBudgetsCSV_oneRow_correctValues() throws {
        let budget = MonthlyBudget(year: 2026, month: 4, limit: 8000)
        let url = try service.exportBudgets(format: .csv, budgets: [budget])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("2026"))
        #expect(content.contains("4"))
        #expect(content.contains("8000.0"))
    }

    // MARK: CSV export — categories

    @Test func exportCategoriesCSV_producesCorrectHeaders() throws {
        let cat = CustomCategory(name: "Travel", icon: "airplane", color: "#FF0000")
        let url = try service.exportCategories(format: .csv, categories: [cat])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.hasPrefix("ID,Name,Icon,Color,Is Hidden,Is Predefined,Predefined Key"))
    }

    @Test func exportCategoriesCSV_oneRow_correctValues() throws {
        let cat = CustomCategory(name: "Health", icon: "heart.fill", color: "#00FF00")
        let url = try service.exportCategories(format: .csv, categories: [cat])
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("Health"))
        #expect(content.contains("heart.fill"))
        #expect(content.contains("#00FF00"))
    }

    // MARK: JSON export — transactions

    @Test func exportTransactionsJSON_decodesBackCorrectly() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tx = Transaction(amount: 500, category: "Food", date: date, transactionDescription: "Dinner")
        let url = try service.exportTransactions(format: .json, transactions: [tx], groups: [])

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exported = try decoder.decode(ExportData.self, from: data)

        #expect(exported.transactions?.count == 1)
        let exportedTx = try #require(exported.transactions?.first)
        #expect(exportedTx.amount == 500)
        #expect(exportedTx.category == "Food")
        #expect(exportedTx.transactionDescription == "Dinner")
    }

    @Test func exportTransactionsJSON_softDeletedTransactions_excluded() throws {
        let tx = Transaction(amount: 99, category: "Other", date: Date())
        tx.isSoftDeleted = true
        let url = try service.exportTransactions(format: .json, transactions: [tx], groups: [])

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exported = try decoder.decode(ExportData.self, from: data)
        #expect(exported.transactions?.isEmpty ?? true)
    }

    // MARK: JSON export — exportAll round-trip structure

    @Test func exportAllJSON_containsAllSections() throws {
        let tx = Transaction(amount: 100, category: "Food", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 1, limit: 3000)
        let cat = CustomCategory(name: "Fun", icon: "star.fill", color: "#AAAAAA")
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
        let container = try makeTestContainer()
        let context = ModelContext(container)

        // Export
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let tx = Transaction(amount: 300, category: "Transport", date: date, transactionDescription: "Cab")
        let exportService = ExportService()
        let url = try exportService.exportTransactions(format: .json, transactions: [tx], groups: [])

        // Import
        let result = try service.importJSON(from: url, context: context)
        #expect(result.message.contains("1 transactions"))

        let descriptor = FetchDescriptor<Transaction>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported[0].amount == 300)
        #expect(imported[0].category == "Transport")
        #expect(imported[0].transactionDescription == "Cab")
    }

    @Test func importJSON_roundTrip_budgets() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let budget = MonthlyBudget(year: 2026, month: 4, limit: 7000)
        let exportService = ExportService()
        let url = try exportService.exportBudgets(format: .json, budgets: [budget])

        let result = try service.importJSON(from: url, context: context)
        #expect(result.message.contains("1 budgets"))

        let descriptor = FetchDescriptor<MonthlyBudget>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported[0].year == 2026)
        #expect(imported[0].month == 4)
        #expect(imported[0].limit == 7000)
    }

    @Test func importJSON_roundTrip_categories() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let cat = CustomCategory(name: "Health", icon: "heart.fill", color: "#FF0000")
        let exportService = ExportService()
        let url = try exportService.exportCategories(format: .json, categories: [cat])

        let result = try service.importJSON(from: url, context: context)
        #expect(result.message.contains("1 categories"))

        let descriptor = FetchDescriptor<CustomCategory>()
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
        let cat = CustomCategory(name: "Fun", icon: "star.fill", color: "#AAAAAA")

        let exportService = ExportService()
        let url = try exportService.exportAll(format: .json, transactions: [tx], recurringTransactions: [], budgets: [budget], categories: [cat])

        let result = try service.importJSON(from: url, context: context)
        #expect(result.message.contains("transactions"))
        #expect(result.message.contains("budgets"))
        #expect(result.message.contains("categories"))
    }

    // MARK: CSV import round-trip

    @Test func importCSV_roundTrip_transactions() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let tx = Transaction(amount: 150, category: "Food", date: Date(), transactionDescription: "Breakfast")
        let exportService = ExportService()
        let url = try exportService.exportTransactions(format: .csv, transactions: [tx], groups: [])

        let result = try service.importCSV(from: url, context: context)
        #expect(result.message.contains("1 transactions"))

        let descriptor = FetchDescriptor<Transaction>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported[0].amount == 150)
        #expect(imported[0].category == "Food")
    }

    @Test func importCSV_roundTrip_budgets() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let budget = MonthlyBudget(year: 2026, month: 6, limit: 4000)
        let exportService = ExportService()
        let url = try exportService.exportBudgets(format: .csv, budgets: [budget])

        let result = try service.importCSV(from: url, context: context)
        #expect(result.message.contains("1 budgets"))
    }

    @Test func importCSV_roundTrip_allSections() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)

        let tx = Transaction(amount: 200, category: "Transport", date: Date())
        let budget = MonthlyBudget(year: 2026, month: 2, limit: 6000)
        let cat = CustomCategory(name: "Work", icon: "briefcase.fill", color: "#0000FF")

        let exportService = ExportService()
        let url = try exportService.exportAll(format: .csv, transactions: [tx], recurringTransactions: [], budgets: [budget], categories: [cat])

        let result = try service.importCSV(from: url, context: context)
        #expect(result.message.contains("transactions"))
        #expect(result.message.contains("budgets"))
        #expect(result.message.contains("categories"))
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
