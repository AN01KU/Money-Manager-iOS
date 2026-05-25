import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers
@testable import Money_Manager


@MainActor
struct ExportFormatTests {
    
    @Test
    func testCSVFileExtension() {
        #expect(ExportFormat.csv.fileExtension == "csv")
    }
    
    @Test
    func testJSONFileExtension() {
        #expect(ExportFormat.json.fileExtension == "json")
    }
    
    @Test
    func testCSVUTType() {
        #expect(ExportFormat.csv.utType == .commaSeparatedText)
    }
    
    @Test
    func testJSONUTType() {
        #expect(ExportFormat.json.utType == .json)
    }
    
    @Test
    func testExportFormatIdMatchesRawValue() {
        #expect(ExportFormat.csv.id == "CSV")
        #expect(ExportFormat.json.id == "JSON")
    }
    
    @Test
    func testAllExportFormatsHaveCases() {
        #expect(ExportFormat.allCases.count == 2)
    }
}

@MainActor
struct ExportDataTypeTests {
    
    @Test
    func testAllCasesIconsAndIds() {
        let expectedIcons: [ExportDataType: String] = [
            .transactions: "creditcard.fill",
            .recurring: "arrow.clockwise.circle.fill",
            .categories: "folder.fill",
            .all: "archivebox.fill"
        ]

        for dataType in ExportDataType.allCases {
            #expect(dataType.icon == expectedIcons[dataType])
            #expect(dataType.id == dataType.rawValue)
        }
        #expect(ExportDataType.allCases.count == 4)
    }
}

@MainActor
struct ExportDataStructTests {

    @Test
    func testExportDataWithAllFields() {
        let expenseData = ExportData.TransactionData(
            id: "exp-1",
            amount: 100,
            category: "Food",
            date: Date(),
            time: nil,
            transactionDescription: "Test",
            notes: nil,
            recurringExpenseId: nil,
            groupTransactionId: nil
        )

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: [expenseData],
            recurringTransactions: nil,
            categories: nil
        )

        #expect(exportData.transactions?.count == 1)
        #expect(exportData.appVersion == "1.0")
    }
    
    @Test
    func testExportDataCodable() throws {
        let expenseData = ExportData.TransactionData(
            id: "exp-1",
            amount: 100,
            category: "Food",
            date: Date(),
            time: nil,
            transactionDescription: "Test",
            notes: nil,
            recurringExpenseId: nil,
            groupTransactionId: nil
        )
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: [expenseData],
            recurringTransactions: nil,
            categories: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(exportData)

        #expect(jsonData.count > 0)
    }

    @Test
    func testRecurringTransactionDataCodable() throws {
        let recurringData = ExportData.RecurringTransactionData(
            id: "rec-1",
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: RecurringFrequency.monthly.rawValue,
            dayOfMonth: 1,
            daysOfWeek: [1, 3, 5],
            startDate: Date(),
            endDate: nil,
            isActive: true,
            lastAddedDate: nil,
            notes: "Test notes",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(recurringData)
        
        #expect(jsonData.count > 0)
    }
}

@MainActor
struct BackupViewModelTests {
    
    @Test
    func testInitialState() {
        let viewModel = BackupViewModel()
        
        #expect(viewModel.isExporting == false)
        #expect(viewModel.isImporting == false)
        #expect(viewModel.showShareSheet == false)
        #expect(viewModel.exportedFileURL == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showError == false)
        #expect(viewModel.successMessage == nil)
        #expect(viewModel.showSuccess == false)
    }
    
    @Test
    func testDefaultSelections() {
        let viewModel = BackupViewModel()
        
        #expect(viewModel.selectedExportFormat == .csv)
        #expect(viewModel.selectedDataType == .all)
        #expect(viewModel.selectedImportFormat == .json)
    }
    
    @Test
    func testExportDescriptionForCSV() {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        
        #expect(viewModel.exportDescription.contains("CSV"))
    }
    
    @Test
    func testExportDescriptionForJSONAllData() {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .all
        
        #expect(viewModel.exportDescription.contains("JSON"))
        #expect(viewModel.exportDescription.contains("backup"))
    }
    
    @Test
    func testExportDescriptionForJSONNonAllTypes() {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        
        for dataType in [ExportDataType.transactions, .recurring, .categories] {
            viewModel.selectedDataType = dataType
            #expect(viewModel.exportDescription.contains("JSON"))
            #expect(viewModel.exportDescription.contains("backup") || viewModel.exportDescription.contains("suitable"))
        }
    }
    
    @Test
    func testImportDescriptions() {
        let viewModel = BackupViewModel()
        
        viewModel.selectedImportFormat = .json
        #expect(viewModel.importDescription.contains("JSON"))
        
        viewModel.selectedImportFormat = .csv
        #expect(viewModel.importDescription.contains("CSV"))
    }
    
    // MARK: - CSV Escape Tests (delegated to BackupService)

    @Test
    func testEscapeCSVWithComma() {
        #expect(BackupService.escapeCSVField("Hello, World") == "\"Hello, World\"")
    }

    @Test
    func testEscapeCSVWithQuote() {
        #expect(BackupService.escapeCSVField("He said \"Hello\"") == "\"He said \"\"Hello\"\"\"")
    }

    @Test
    func testEscapeCSVWithNewline() {
        #expect(BackupService.escapeCSVField("Line1\nLine2") == "\"Line1\nLine2\"")
    }

    @Test
    func testEscapeCSVWithoutSpecialChars() {
        #expect(BackupService.escapeCSVField("Simple Text") == "Simple Text")
    }

    @Test
    func testEscapeCSVEmptyString() {
        #expect(BackupService.escapeCSVField("") == "")
    }

    // MARK: - CSV Line Parse Tests (delegated to BackupViewModel)

    @Test
    func testParseCSVLineSimple() {
        let vm = BackupViewModel()
        #expect(vm.parseCSVLine("a,b,c") == ["a", "b", "c"])
    }

    @Test
    func testParseCSVLineWithQuotes() {
        let vm = BackupViewModel()
        let result = vm.parseCSVLine("\"a,b\",c")
        #expect(result[0] == "a,b")
        #expect(result[1] == "c")
    }

    @Test
    func testParseCSVLineWithSpaces() {
        let vm = BackupViewModel()
        #expect(vm.parseCSVLine("a , b , c") == ["a", "b", "c"])
    }

    @Test
    func testParseCSVLineEmptyValues() {
        let vm = BackupViewModel()
        #expect(vm.parseCSVLine("a,,c") == ["a", "", "c"])
    }

    // MARK: - Date Parse Tests

    @Test
    func testParseDateISO8601() {
        let vm = BackupViewModel()
        let result = vm.parseDate("2026-03-12T10:30:00Z")
        #expect(Calendar.current.component(.year, from: result.date) == 2026)
    }

    @Test
    func testParseDateWithTime() {
        let vm = BackupViewModel()
        let result = vm.parseDate("2026-03-12T10:30:00Z", "2026-03-12T14:45:00.000Z")
        #expect(result.time != nil)
    }

    @Test
    func testParseDateMediumFormat() {
        let vm = BackupViewModel()
        let result = vm.parseDate("Mar 12, 2026 at 10:30 AM")
        #expect(Calendar.current.component(.year, from: result.date) == 2026)
    }

    @Test
    func testParseDateSlashFormat() {
        let vm = BackupViewModel()
        let result = vm.parseDate("03/12/2026")
        let cal = Calendar.current
        #expect(cal.component(.year, from: result.date) == 2026)
        #expect(cal.component(.month, from: result.date) == 3)
        #expect(cal.component(.day, from: result.date) == 12)
    }

    @Test
    func testParseDateEmptyString() {
        let vm = BackupViewModel()
        let result = vm.parseDate("")
        #expect(result.date.timeIntervalSince1970 > 0)
    }

    // MARK: - Transaction CSV Row Parse Tests

    @Test
    func testParseTransactionCSVRow() {
        let vm = BackupViewModel()
        let headers = ["id", "amount", "category", "date", "time", "description", "notes", "recurring expense id", "group id", "group name"]
        let values = ["uuid-123", "100.50", "Food", "2026-03-12T10:30:00Z", "", "Lunch", "", "", "", ""]
        let result = vm.parseTransactionCSVRow(values, headers: headers)
        #expect(result != nil)
        #expect(result?.id == "uuid-123")
        #expect(result?.amount == 100.50)
        #expect(result?.category == "Food")
        #expect(result?.transactionDescription == "Lunch")
    }

    @Test
    func testParseTransactionCSVRowWithMissingValues() {
        let vm = BackupViewModel()
        let result = vm.parseTransactionCSVRow(["uuid-123", "100", "Food"], headers: ["id", "amount", "category", "date"])
        #expect(result == nil)
    }

    // MARK: - Category CSV Row Parse Tests

    @Test
    func testParseCategoryCSVRow() {
        let vm = BackupViewModel()
        let headers = ["id", "name", "icon", "color", "is hidden", "is predefined", "predefined key"]
        let result = vm.parseCategoryCSVRow(["cat-1", "Groceries", "cart.fill", "#FF0000", "false", "true", "food"], headers: headers)
        #expect(result != nil)
        #expect(result?.id == "cat-1")
        #expect(result?.name == "Groceries")
        #expect(result?.icon == "cart.fill")
        #expect(result?.color == "#FF0000")
        #expect(result?.isHidden == false)
        #expect(result?.isPredefined == true)
        #expect(result?.predefinedKey == "food")
    }

    @Test
    func testParseCategoryCSVRowWithDefaults() {
        let vm = BackupViewModel()
        let result = vm.parseCategoryCSVRow(["cat-1", "Test", "star.fill", "#000000"], headers: ["id", "name", "icon", "color"])
        #expect(result != nil)
        #expect(result?.name == "Test")
        #expect(result?.isHidden == false)
        #expect(result?.isPredefined == false)
    }

    @Test
    func testParseCategoryCSVRowMismatchedCount() {
        let vm = BackupViewModel()
        let result = vm.parseCategoryCSVRow(["cat-1", "Test"], headers: ["id", "name", "icon", "color", "is hidden"])
        #expect(result == nil)
    }

    @Test
    func testParseTransactionCSVRowWithAllFields() {
        let vm = BackupViewModel()
        let headers = ["id", "amount", "category", "date", "time", "description", "notes", "recurring expense id", "group transaction id"]
        let values = ["uuid-1", "250.75", "Transport", "2026-03-12T10:30:00Z", "2026-03-12T14:00:00Z", "Uber ride", "To airport", "rec-uuid", "grp-uuid"]
        let result = vm.parseTransactionCSVRow(values, headers: headers)
        #expect(result != nil)
        #expect(result?.amount == 250.75)
        #expect(result?.category == "Transport")
        #expect(result?.transactionDescription == "Uber ride")
        #expect(result?.notes == "To airport")
        #expect(result?.recurringExpenseId == "rec-uuid")
        #expect(result?.groupTransactionId == "grp-uuid")
    }

    @Test
    func testParseTransactionCSVRowWithEmptyOptionalFields() {
        let vm = BackupViewModel()
        let headers = ["id", "amount", "category", "date", "time", "description", "notes", "recurring expense id", "group transaction id"]
        let values = ["uuid-1", "50", "Food", "2026-03-12T10:30:00Z", "", "", "", "", ""]
        let result = vm.parseTransactionCSVRow(values, headers: headers)
        #expect(result != nil)
        #expect(result?.transactionDescription == nil)
        #expect(result?.notes == nil)
        #expect(result?.recurringExpenseId == nil)
        #expect(result?.groupTransactionId == nil)
    }

    // MARK: - Date Parsing Edge Cases

    @Test
    func testParseDateYYYYMMDDFormat() {
        let vm = BackupViewModel()
        let result = vm.parseDate("2026-03-15")
        let cal = Calendar.current
        #expect(cal.component(.year, from: result.date) == 2026)
        #expect(cal.component(.month, from: result.date) == 3)
        #expect(cal.component(.day, from: result.date) == 15)
    }

    @Test
    func testParseDateISO8601WithFractionalSeconds() {
        let vm = BackupViewModel()
        let result = vm.parseDate("2026-03-12T10:30:00.123Z")
        #expect(Calendar.current.component(.year, from: result.date) == 2026)
    }

    @Test
    func testParseDateWithEmptyTimeString() {
        let vm = BackupViewModel()
        let result = vm.parseDate("2026-03-12T10:30:00Z", "")
        #expect(result.time == nil)
    }

    @Test
    func testParseDateWithInvalidDateReturnsCurrentDate() {
        let vm = BackupViewModel()
        let before = Date()
        let result = vm.parseDate("completely-invalid-date")
        let after = Date()
        #expect(result.date >= before)
        #expect(result.date <= after)
    }

    @Test
    func testParseDateTimeWithNonISOFormat() {
        let vm = BackupViewModel()
        let result = vm.parseDate("03/12/2026", "03/12/2026")
        #expect(result.time != nil)
    }
}

// MARK: - Export/Import Integration Tests

@MainActor
struct BackupViewModelExportTests {
    
    private func createTestContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    // MARK: - Export Expenses Tests
    
    @Test
    func testExportTransactionsAsCSV() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .transactions

        let expense = Transaction(
            amount: 100.50,
            category: "Food & Dining",
            date: Date(),
            transactionDescription: "Lunch"
        )

        await viewModel.exportData(
            transactions: [expense],
            recurringTransactions: [],
            categories: []
        )

        #expect(viewModel.exportedFileURL != nil)
        #expect(viewModel.showShareSheet == true)
        #expect(viewModel.isExporting == false)
        #expect(viewModel.showError == false)

        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            // TransactionCodec section-based format
            #expect(content.contains("# transactions"))
            #expect(content.contains("ID,Type,Amount,Category"))
            #expect(content.contains("100.5"))
            #expect(content.contains("Food & Dining"))
        }
    }

    @Test
    func testExportTransactionsAsJSON() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .transactions

        let expense = Transaction(
            amount: 200.0,
            category: "Transport",
            date: Date(),
            transactionDescription: "Uber"
        )

        await viewModel.exportData(
            transactions: [expense],
            recurringTransactions: [],
            categories: []
        )

        #expect(viewModel.exportedFileURL != nil)
        #expect(viewModel.showShareSheet == true)

        if let url = viewModel.exportedFileURL {
            // TransactionCodec encodes as JSON array of TransactionRecord
            let data = try! Data(contentsOf: url)
            let json = try! JSONSerialization.jsonObject(with: data) as! [[String: Any]]
            #expect(json.count == 1)
            #expect(json[0]["amount"] as? Double == 200.0)
            #expect(json[0]["category"] as? String == "Transport")
        }
    }

    @Test
    func testExportTransactionsFiltersDeletedTransactions() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .transactions

        let active = Transaction(amount: 100, category: "Food", date: Date())
        let deleted = Transaction(amount: 200, category: "Food", date: Date())
        deleted.isSoftDeleted = true

        await viewModel.exportData(
            transactions: [active, deleted],
            recurringTransactions: [],
            categories: []
        )

        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            // Section marker + header + 1 active row
            #expect(lines.count == 3)
        }
    }
    
    // MARK: - Export Categories Tests
    
    @Test
    func testExportCategoriesAsCSV() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .categories
        
        let category = Category(
            name: "Groceries",
            icon: "cart.fill",
            color: "#FF0000"
        )
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            categories: [category]
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("ID,Name,Icon,Color"))
            #expect(content.contains("Groceries"))
            #expect(content.contains("cart.fill"))
        }
    }
    
    @Test
    func testExportCategoriesAsJSON() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .categories
        
        let category = Category(
            name: "Groceries",
            icon: "cart.fill",
            color: "#FF0000"
        )
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            categories: [category]
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let data = try! Data(contentsOf: url)
            #expect(data.count > 0)
        }
    }
    
    // MARK: - Export Recurring Expenses Tests
    
    @Test
    func testExportRecurringTransactionsAsCSV() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .recurring
        
        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            dayOfMonth: 1,
            startDate: Date(),
            isActive: true
        )
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [recurring],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            // RecurringTransactionCodec section-based format
            #expect(content.contains("# recurring transactions"))
            #expect(content.contains("ID,Name,Amount,Category"))
            #expect(content.contains("Netflix"))
            #expect(content.contains("649"))
        }
    }

    @Test
    func testExportRecurringTransactionsAsJSON() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .recurring

        let recurring = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            dayOfMonth: 1,
            startDate: Date(),
            isActive: true
        )

        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [recurring],
            categories: []
        )

        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            // RecurringTransactionCodec encodes as plain JSON array
            let data = try! Data(contentsOf: url)
            let json = try! JSONSerialization.jsonObject(with: data) as! [[String: Any]]
            #expect(json.count == 1)
            #expect(json[0]["name"] as? String == "Netflix")
            #expect(json[0]["amount"] as? Double == 649)
        }
    }
    
    // MARK: - Export All Tests
    
    @Test
    func testExportAllAsCSV() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .all

        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let recurring = RecurringTransaction(name: "Gym", amount: 500, category: "Health", frequency: .monthly, startDate: Date(), isActive: true)
        let category = Category(name: "Custom", icon: "star.fill", color: "#0000FF")

        await viewModel.exportData(
            transactions: [expense],
            recurringTransactions: [recurring],
            categories: [category]
        )

        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("# TRANSACTIONS"))
            #expect(content.contains("# RECURRING EXPENSES"))
            #expect(content.contains("# CATEGORIES"))
        }
    }
    
    @Test
    func testExportAllAsJSON() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .all

        let expense = Transaction(amount: 100, category: "Food", date: Date())
        let recurring = RecurringTransaction(name: "Gym", amount: 500, category: "Health", frequency: .monthly, startDate: Date(), isActive: true)
        let category = Category(name: "Custom", icon: "star.fill", color: "#0000FF")

        await viewModel.exportData(
            transactions: [expense],
            recurringTransactions: [recurring],
            categories: [category]
        )

        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let data = try! Data(contentsOf: url)
            #expect(data.count > 0)
        }
    }
    
    @Test
    func testExportResetsExportingFlag() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .transactions
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            categories: []
        )
        
        #expect(viewModel.isExporting == false)
    }
    
    // MARK: - Export with Optional Fields
    
    @Test
    func testExportTransactionWithOptionalFields() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .transactions
        
        let expense = Transaction(
            amount: 500,
            category: "Travel",
            date: Date(),
            time: Date(),
            transactionDescription: "Flight, to NYC",
            notes: "Business \"trip\"",
            recurringExpenseId: UUID(),
            groupTransactionId: UUID()
        )

        await viewModel.exportData(
            transactions: [expense],
            recurringTransactions: [],
            categories: []
        )

        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            // Commas and quotes in description should be escaped
            #expect(content.contains("\"Flight, to NYC\""))
        }
    }
    
    // MARK: - Predefined Category Exclusion (issue #119)

    @Test
    func testExportCategoriesAsJSONExcludesPredefined() async throws {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .categories

        let predefined = Category(
            name: "Food & Dining",
            icon: "fork.knife",
            color: "#FF6B6B",
            isPredefined: true,
            predefinedKey: "food"
        )
        let custom = Category(name: "My Custom", icon: "star.fill", color: "#0000FF")

        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            categories: [predefined, custom]
        )

        let url = try #require(viewModel.exportedFileURL)
        let data = try Data(contentsOf: url)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        let names = json.compactMap { $0["name"] as? String }
        #expect(names == ["My Custom"])
    }

    @Test
    func testExportCategoriesAsCSVExcludesPredefined() async throws {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .categories

        let predefined = Category(
            name: "PredefFood",
            icon: "fork.knife",
            color: "#FF6B6B",
            isPredefined: true,
            predefinedKey: "food"
        )
        let custom = Category(name: "MyCustomCat", icon: "star.fill", color: "#0000FF")

        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            categories: [predefined, custom]
        )

        let url = try #require(viewModel.exportedFileURL)
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("MyCustomCat"))
        #expect(!content.contains("PredefFood"))
    }

    @Test
    func testExportAllAsJSONExcludesPredefinedCategories() async throws {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .all

        let predefined = Category(
            name: "PredefFood",
            icon: "fork.knife",
            color: "#FF6B6B",
            isPredefined: true,
            predefinedKey: "food"
        )
        let custom = Category(name: "MyCustomCat", icon: "star.fill", color: "#0000FF")

        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            categories: [predefined, custom]
        )

        let url = try #require(viewModel.exportedFileURL)
        let data = try Data(contentsOf: url)
        let dict = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cats = try #require(dict["categories"] as? [[String: Any]])
        let names = cats.compactMap { $0["name"] as? String }
        #expect(names == ["MyCustomCat"])
    }

    @Test
    func testExportAllAsCSVExcludesPredefinedCategories() async throws {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .all

        let predefined = Category(
            name: "PredefFood",
            icon: "fork.knife",
            color: "#FF6B6B",
            isPredefined: true,
            predefinedKey: "food"
        )
        let custom = Category(name: "MyCustomCat", icon: "star.fill", color: "#0000FF")

        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            categories: [predefined, custom]
        )

        let url = try #require(viewModel.exportedFileURL)
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("MyCustomCat"))
        #expect(!content.contains("PredefFood"))
    }

    @Test
    func testExportRecurringWithDaysOfWeek() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .recurring
        
        let recurring = RecurringTransaction(
            name: "Gym",
            amount: 500,
            category: "Health",
            frequency: .weekly,
            daysOfWeek: [1, 3, 5],
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 365),
            isActive: true,
            notes: "MWF schedule"
        )
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [recurring],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("1;3;5"))
        }
    }
}

// MARK: - Import Integration Tests

@MainActor
struct BackupViewModelImportTests {
    
    private func createTestContext() throws -> ModelContext {
        ModelContext(try makeTestContainer())
    }

    // MARK: - JSON Import Tests
    
    @Test
    func testImportTransactionsFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: [
                ExportData.TransactionData(
                    id: UUID().uuidString,
                    amount: 100.50,
                    category: "Food",
                    date: Date(),
                    time: nil,
                    transactionDescription: "Lunch",
                    notes: nil,
                    recurringExpenseId: nil,
                    groupTransactionId: nil
                )
            ],
            recurringTransactions: nil,
            categories: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.isImporting == false)
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.successMessage?.contains("1 transactions") == true)
        
        let descriptor = FetchDescriptor<Transaction>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported.first?.amount == 100.50)
        #expect(imported.first?.category == "Food")
    }
    
    @Test
    func testImportCategoriesFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            recurringTransactions: nil,
            categories: [
                ExportData.CategoryData(
                    id: UUID().uuidString,
                    name: "Groceries",
                    icon: "cart.fill",
                    color: "#FF0000",
                    isHidden: false,
                    isPredefined: false,
                    predefinedKey: nil
                )
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_cats.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.successMessage?.contains("1 categories") == true)
        
        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported.first?.name == "Groceries")
    }
    
    @Test
    func testImportRecurringTransactionsFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            recurringTransactions: [
                ExportData.RecurringTransactionData(
                    id: UUID().uuidString,
                    name: "Netflix",
                    amount: 649,
                    category: "Entertainment",
                    frequency: RecurringFrequency.monthly.rawValue,
                    dayOfMonth: 1,
                    daysOfWeek: nil,
                    startDate: Date(),
                    endDate: nil,
                    isActive: true,
                    lastAddedDate: nil,
                    notes: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            ],
            categories: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_recurring.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.successMessage?.contains("1 recurring transactions") == true)
        
        let descriptor = FetchDescriptor<RecurringTransaction>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported.first?.name == "Netflix")
    }
    
    @Test
    func testImportAllDataFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let recId = UUID().uuidString
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: [
                ExportData.TransactionData(
                    id: UUID().uuidString, amount: 100, category: "Food", date: Date(),
                    time: nil, transactionDescription: nil, notes: nil,
                    recurringExpenseId: recId, groupTransactionId: nil
                )
            ],
            recurringTransactions: [
                ExportData.RecurringTransactionData(
                    id: recId, name: "Lunch", amount: 100, category: "Food",
                    frequency: RecurringFrequency.daily.rawValue, dayOfMonth: nil, daysOfWeek: nil,
                    startDate: Date(), endDate: nil, isActive: true,
                    lastAddedDate: nil, notes: nil, createdAt: Date(), updatedAt: Date()
                )
            ],
            categories: [
                ExportData.CategoryData(
                    id: UUID().uuidString, name: "Custom", icon: "star", color: "#000",
                    isHidden: false, isPredefined: false, predefinedKey: nil
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_all.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)

        #expect(viewModel.showSuccess == true)
        #expect(viewModel.successMessage?.contains("recurring transactions") == true)
        #expect(viewModel.successMessage?.contains("transactions") == true)
        #expect(viewModel.successMessage?.contains("categories") == true)
    }
    
    @Test
    func testImportEmptyDataShowsNoDataMessage() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            recurringTransactions: nil,
            categories: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_empty.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.successMessage?.contains("No data found") == true)
    }
    
    @Test
    func testImportInvalidJSONShowsError() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_invalid.json")
        try! "{ invalid json }".write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage?.contains("Import failed") == true)
        #expect(viewModel.isImporting == false)
    }
    
    // MARK: - CSV Import Tests
    
    @Test
    func testImportTransactionsFromCSV() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let csv = """
        id,amount,category,date,time,description,notes,recurring expense id,group id,group name
        \(UUID().uuidString),150.50,Food,2026-03-12T10:30:00.000Z,,Lunch,,,, 
        """
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_expenses.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .csv
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.isImporting == false)
        
        let descriptor = FetchDescriptor<Transaction>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported.first?.amount == 150.50)
    }
    
    @Test
    func testImportCategoriesFromCSV() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let csv = """
        id,name,icon,color,is hidden,is predefined,predefined key
        \(UUID().uuidString),Groceries,cart.fill,#FF0000,false,false,
        """
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_cats.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .csv
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        
        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported.first?.name == "Groceries")
    }
    
    @Test
    func testImportSectionBasedCSV() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let csv = """
        # TRANSACTIONS
        id,amount,category,date,time,description,notes,recurring expense id,group transaction id
        \(UUID().uuidString),100,Food,2026-03-12T10:30:00.000Z,,Lunch,,,

        # CATEGORIES
        id,name,icon,color,is hidden,is predefined,predefined key
        \(UUID().uuidString),Custom,star.fill,#0000FF,false,false,
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_sections.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        viewModel.selectedImportFormat = .csv
        await viewModel.importData(from: tempURL, context: context)

        #expect(viewModel.showSuccess == true)

        let expDescriptor = FetchDescriptor<Transaction>()
        let catDescriptor = FetchDescriptor<Money_Manager.Category>()

        #expect(try context.fetch(expDescriptor).count == 1)
        #expect(try context.fetch(catDescriptor).count == 1)
    }
    
    @Test
    func testImportCSVWithEmptyFileDoesNotCrash() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let csv = "id,amount,category,date\n"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_empty.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .csv
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.isImporting == false)
    }
    
    @Test
    func testImportResetsImportingFlag() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_nonexistent.json")
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.isImporting == false)
    }
    
    @Test
    func testImportPredefinedCategoryUpdatesExisting() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        // Insert existing predefined category
        let existing = Category(
            name: "Food & Dining",
            icon: "fork.knife",
            color: "#FF6B6B",
            isPredefined: true,
            predefinedKey: "food"
        )
        context.insert(existing)
        try context.save()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            recurringTransactions: nil,
            categories: [
                ExportData.CategoryData(
                    id: UUID().uuidString,
                    name: "Food Updated",
                    icon: "fork.knife.circle",
                    color: "#00FF00",
                    isHidden: true,
                    isPredefined: true,
                    predefinedKey: "food"
                )
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_predefined.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        
        let descriptor = FetchDescriptor<Money_Manager.Category>()
        let categories = try context.fetch(descriptor)
        // Should update existing, not create new
        #expect(categories.count == 1)
        #expect(categories.first?.name == "Food Updated")
        #expect(categories.first?.icon == "fork.knife.circle")
        #expect(categories.first?.isHidden == true)
    }
    
    @Test
    func testImportTransactionWithRecurringTransactionIdMapping() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let recId = UUID().uuidString
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: [
                ExportData.TransactionData(
                    id: UUID().uuidString, amount: 649, category: "Entertainment",
                    date: Date(), time: nil, transactionDescription: "Netflix",
                    notes: nil, recurringExpenseId: recId, groupTransactionId: nil
                )
            ],
            recurringTransactions: [
                ExportData.RecurringTransactionData(
                    id: recId, name: "Netflix", amount: 649, category: "Entertainment",
                    frequency: RecurringFrequency.monthly.rawValue, dayOfMonth: 1, daysOfWeek: nil,
                    startDate: Date(), endDate: nil, isActive: true,
                    lastAddedDate: nil, notes: nil, createdAt: Date(), updatedAt: Date()
                )
            ],
            categories: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_mapping.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        let expDescriptor = FetchDescriptor<Transaction>()
        let expenses = try context.fetch(expDescriptor)
        let recDescriptor = FetchDescriptor<RecurringTransaction>()
        let recurrings = try context.fetch(recDescriptor)
        
        #expect(expenses.count == 1)
        #expect(recurrings.count == 1)
        // The expense's recurringExpenseId should be mapped to the new recurring expense's UUID
        #expect(expenses.first?.recurringExpenseId == recurrings.first?.id)
    }
    
    @Test
    func testImportTransactionWithGroupFields() async throws {
        let viewModel = BackupViewModel()
        let context = try createTestContext()
        
        let groupTransactionId = UUID().uuidString
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: [
                ExportData.TransactionData(
                    id: UUID().uuidString, amount: 500, category: "Travel",
                    date: Date(), time: Date(), transactionDescription: "Hotel",
                    notes: "Business", recurringExpenseId: nil,
                    groupTransactionId: groupTransactionId
                )
            ],
            recurringTransactions: nil,
            categories: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_groups.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)

        let descriptor = FetchDescriptor<Transaction>()
        let expenses = try context.fetch(descriptor)

        #expect(expenses.count == 1)
        #expect(expenses.first?.groupTransactionId != nil)
    }
}
