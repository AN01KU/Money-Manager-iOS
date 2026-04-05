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
            .budgets: "chart.bar.fill",
            .categories: "folder.fill",
            .all: "archivebox.fill"
        ]
        
        for dataType in ExportDataType.allCases {
            #expect(dataType.icon == expectedIcons[dataType])
            #expect(dataType.id == dataType.rawValue)
        }
        #expect(ExportDataType.allCases.count == 5)
    }
}

@MainActor
struct ExportDataStructTests {
    
    @Test
    func testTransactionDataInitialization() {
        let expenseData = ExportData.TransactionData(
            id: "test-id",
            amount: 100.50,
            category: "Food",
            date: Date(),
            time: nil,
            transactionDescription: "Lunch",
            notes: nil,
            recurringExpenseId: nil,
            groupTransactionId: nil
        )
        
        #expect(expenseData.id == "test-id")
        #expect(expenseData.amount == 100.50)
        #expect(expenseData.category == "Food")
        #expect(expenseData.transactionDescription == "Lunch")
    }
    
    @Test
    func testRecurringTransactionDataInitialization() {
        let recurringData = ExportData.RecurringTransactionData(
            id: "rec-1",
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
        
        #expect(recurringData.id == "rec-1")
        #expect(recurringData.name == "Netflix")
        #expect(recurringData.frequency == "monthly")
        #expect(recurringData.isActive == true)
    }
    
    @Test
    func testMonthlyBudgetDataInitialization() {
        let budgetData = ExportData.MonthlyBudgetData(
            id: "budget-1",
            year: 2026,
            month: 3,
            limit: 5000
        )
        
        #expect(budgetData.year == 2026)
        #expect(budgetData.month == 3)
        #expect(budgetData.limit == 5000)
    }
    
    @Test
    func testCustomCategoryDataInitialization() {
        let categoryData = ExportData.CustomCategoryData(
            id: "cat-1",
            name: "Groceries",
            icon: "cart.fill",
            color: "#FF0000",
            isHidden: false,
            isPredefined: nil,
            predefinedKey: nil
        )
        
        #expect(categoryData.name == "Groceries")
        #expect(categoryData.icon == "cart.fill")
        #expect(categoryData.color == "#FF0000")
        #expect(categoryData.isHidden == false)
    }
    
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
        
        let budgetData = ExportData.MonthlyBudgetData(
            id: "bud-1",
            year: 2026,
            month: 1,
            limit: 5000
        )
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: [expenseData],
            recurringTransactions: nil,
            budgets: [budgetData],
            categories: nil
        )
        
        #expect(exportData.transactions?.count == 1)
        #expect(exportData.budgets?.count == 1)
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
            budgets: nil,
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
        
        for dataType in [ExportDataType.transactions, .recurring, .budgets, .categories] {
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
    
    // MARK: - CSV Escape Tests
    
    @Test
    func testEscapeCSVWithComma() {
        let service = ExportService()
        let result = service.escapeCSV("Hello, World")
        #expect(result == "\"Hello, World\"")
    }
    
    @Test
    func testEscapeCSVWithQuote() {
        let service = ExportService()
        let result = service.escapeCSV("He said \"Hello\"")
        #expect(result == "\"He said \"\"Hello\"\"\"")
    }
    
    @Test
    func testEscapeCSVWithNewline() {
        let service = ExportService()
        let result = service.escapeCSV("Line1\nLine2")
        #expect(result == "\"Line1\nLine2\"")
    }
    
    @Test
    func testEscapeCSVWithoutSpecialChars() {
        let service = ExportService()
        let result = service.escapeCSV("Simple Text")
        #expect(result == "Simple Text")
    }
    
    @Test
    func testEscapeCSVEmptyString() {
        let service = ExportService()
        let result = service.escapeCSV("")
        #expect(result == "")
    }
    
    // MARK: - CSV Line Parse Tests
    
    @Test
    func testParseCSVLineSimple() {
        let service = ImportService()
        let result = service.parseCSVLine("a,b,c")
        #expect(result == ["a", "b", "c"])
    }
    
    @Test
    func testParseCSVLineWithQuotes() {
        let service = ImportService()
        let result = service.parseCSVLine("\"a,b\",c")
        #expect(result[0] == "a,b")
        #expect(result[1] == "c")
    }
    
    @Test
    func testParseCSVLineWithSpaces() {
        let service = ImportService()
        let result = service.parseCSVLine("a , b , c")
        #expect(result == ["a", "b", "c"])
    }
    
    @Test
    func testParseCSVLineEmptyValues() {
        let service = ImportService()
        let result = service.parseCSVLine("a,,c")
        #expect(result == ["a", "", "c"])
    }
    
    // MARK: - Date Parse Tests
    
    @Test
    func testParseDateISO8601() {
        let service = ImportService()
        let result = service.parseDate("2026-03-12T10:30:00Z")
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: result.date) == 2026)
    }

    @Test
    func testParseDateWithTime() {
        let service = ImportService()
        let result = service.parseDate("2026-03-12T10:30:00Z", "2026-03-12T14:45:00.000Z")
        #expect(result.time != nil)
    }
    
    @Test
    func testParseDateMediumFormat() {
        let service = ImportService()
        let result = service.parseDate("Mar 12, 2026 at 10:30 AM")
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: result.date) == 2026)
    }
    
    @Test
    func testParseDateSlashFormat() {
        let service = ImportService()
        let result = service.parseDate("03/12/2026")
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: result.date) == 2026)
        #expect(calendar.component(.month, from: result.date) == 3)
        #expect(calendar.component(.day, from: result.date) == 12)
    }
    
    @Test
    func testParseDateEmptyString() {
        let service = ImportService()
        let result = service.parseDate("")
        #expect(result.date.timeIntervalSince1970 > 0)
    }
    
    // MARK: - Expense CSV Row Parse Tests
    
    @Test
    func testParseTransactionCSVRow() {
        let service = ImportService()
        let headers = ["id", "amount", "category", "date", "time", "description", "notes", "recurring expense id", "group id", "group name"]
        let values = ["uuid-123", "100.50", "Food", "2026-03-12T10:30:00Z", "", "Lunch", "", "", "", ""]
        
        let result = service.parseTransactionCSVRow(values, headers: headers)
        
        #expect(result != nil)
        #expect(result?.id == "uuid-123")
        #expect(result?.amount == 100.50)
        #expect(result?.category == "Food")
        #expect(result?.transactionDescription == "Lunch")
    }
    
    @Test
    func testParseTransactionCSVRowWithMissingValues() {
        let service = ImportService()
        let headers = ["id", "amount", "category", "date"]
        let values = ["uuid-123", "100", "Food"]
        
        let result = service.parseTransactionCSVRow(values, headers: headers)
        #expect(result == nil)
    }
    
    // MARK: - Budget CSV Row Parse Tests
    
    @Test
    func testParseBudgetCSVRow() {
        let service = ImportService()
        let headers = ["id", "year", "month", "limit"]
        let values = ["budget-1", "2026", "3", "5000"]
        
        let result = service.parseBudgetCSVRow(values, headers: headers)
        
        #expect(result != nil)
        #expect(result?.id == "budget-1")
        #expect(result?.year == 2026)
        #expect(result?.month == 3)
        #expect(result?.limit == 5000)
    }
    
    @Test
    func testParseBudgetCSVRowWithDefaults() {
        let service = ImportService()
        let headers = ["id", "year", "month", "limit"]
        let values = ["budget-1"]
        
        let result = service.parseBudgetCSVRow(values, headers: headers)
        #expect(result == nil)
    }
    
    // MARK: - Category CSV Row Parse Tests
    
    @Test
    func testParseCategoryCSVRow() {
        let service = ImportService()
        let headers = ["id", "name", "icon", "color", "is hidden", "is predefined", "predefined key"]
        let values = ["cat-1", "Groceries", "cart.fill", "#FF0000", "false", "true", "food"]
        
        let result = service.parseCategoryCSVRow(values, headers: headers)
        
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
        let service = ImportService()
        let headers = ["id", "name", "icon", "color"]
        let values = ["cat-1", "Test", "star.fill", "#000000"]
        
        let result = service.parseCategoryCSVRow(values, headers: headers)
        
        #expect(result != nil)
        #expect(result?.name == "Test")
        #expect(result?.isHidden == false)
        #expect(result?.isPredefined == false)
    }
    
    @Test
    func testParseCategoryCSVRowMismatchedCount() {
        let service = ImportService()
        let headers = ["id", "name", "icon", "color", "is hidden"]
        let values = ["cat-1", "Test"]
        
        let result = service.parseCategoryCSVRow(values, headers: headers)
        #expect(result == nil)
    }
    
    @Test
    func testParseBudgetCSVRowMismatchedCount() {
        let service = ImportService()
        let headers = ["id", "year", "month", "limit"]
        let values = ["budget-1", "2026"]
        
        let result = service.parseBudgetCSVRow(values, headers: headers)
        #expect(result == nil)
    }
    
    @Test
    func testParseTransactionCSVRowWithAllFields() {
        let service = ImportService()
        let headers = ["id", "amount", "category", "date", "time", "description", "notes", "recurring expense id", "group transaction id"]
        let values = ["uuid-1", "250.75", "Transport", "2026-03-12T10:30:00Z", "2026-03-12T14:00:00Z", "Uber ride", "To airport", "rec-uuid", "grp-uuid"]

        let result = service.parseTransactionCSVRow(values, headers: headers)

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
        let service = ImportService()
        let headers = ["id", "amount", "category", "date", "time", "description", "notes", "recurring expense id", "group transaction id"]
        let values = ["uuid-1", "50", "Food", "2026-03-12T10:30:00Z", "", "", "", "", ""]

        let result = service.parseTransactionCSVRow(values, headers: headers)

        #expect(result != nil)
        #expect(result?.transactionDescription == nil)
        #expect(result?.notes == nil)
        #expect(result?.recurringExpenseId == nil)
        #expect(result?.groupTransactionId == nil)
    }
    
    // MARK: - Date Parsing Edge Cases
    
    @Test
    func testParseDateYYYYMMDDFormat() {
        let service = ImportService()
        let result = service.parseDate("2026-03-15")
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: result.date) == 2026)
        #expect(calendar.component(.month, from: result.date) == 3)
        #expect(calendar.component(.day, from: result.date) == 15)
    }
    
    @Test
    func testParseDateISO8601WithFractionalSeconds() {
        let service = ImportService()
        let result = service.parseDate("2026-03-12T10:30:00.123Z")
        let calendar = Calendar.current
        #expect(calendar.component(.year, from: result.date) == 2026)
    }
    
    @Test
    func testParseDateWithEmptyTimeString() {
        let service = ImportService()
        let result = service.parseDate("2026-03-12T10:30:00Z", "")
        #expect(result.time == nil)
    }
    
    @Test
    func testParseDateWithInvalidDateReturnsCurrentDate() {
        let service = ImportService()
        let before = Date()
        let result = service.parseDate("completely-invalid-date")
        let after = Date()
        #expect(result.date >= before)
        #expect(result.date <= after)
    }
    
    @Test
    func testParseDateTimeWithNonISOFormat() {
        let service = ImportService()
        let result = service.parseDate("03/12/2026", "03/12/2026")
        #expect(result.time != nil)
    }
}

// MARK: - Export/Import Integration Tests

@MainActor
struct BackupViewModelExportTests {
    
    private func createTestContext() -> ModelContext {
        ModelContext(makeTestContainer())
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
            budgets: [],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        #expect(viewModel.showShareSheet == true)
        #expect(viewModel.isExporting == false)
        #expect(viewModel.showError == false)
        
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("ID,Amount,Category"))
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
            budgets: [],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        #expect(viewModel.showShareSheet == true)
        
        if let url = viewModel.exportedFileURL {
            let data = try! Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try! decoder.decode(ExportData.self, from: data)
            #expect(decoded.transactions?.count == 1)
            #expect(decoded.transactions?.first?.amount == 200.0)
            #expect(decoded.transactions?.first?.category == "Transport")
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
            budgets: [],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            // Header + 1 active expense only
            #expect(lines.count == 2)
        }
    }
    
    // MARK: - Export Budgets Tests
    
    @Test
    func testExportBudgetsAsCSV() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .budgets
        
        let budget = MonthlyBudget(year: 2026, month: 3, limit: 5000)
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            budgets: [budget],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("ID,Year,Month,Limit"))
            #expect(content.contains("2026"))
            #expect(content.contains("5000"))
        }
    }
    
    @Test
    func testExportBudgetsAsJSON() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .budgets
        
        let budget = MonthlyBudget(year: 2026, month: 3, limit: 5000)
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            budgets: [budget],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let data = try! Data(contentsOf: url)
            #expect(data.count > 0)
        }
    }
    
    // MARK: - Export Categories Tests
    
    @Test
    func testExportCategoriesAsCSV() async {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .csv
        viewModel.selectedDataType = .categories
        
        let category = CustomCategory(
            name: "Groceries",
            icon: "cart.fill",
            color: "#FF0000"
        )
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            budgets: [],
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
        
        let category = CustomCategory(
            name: "Groceries",
            icon: "cart.fill",
            color: "#FF0000"
        )
        
        await viewModel.exportData(
            transactions: [],
            recurringTransactions: [],
            budgets: [],
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
            budgets: [],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
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
            budgets: [],
            categories: []
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let data = try! Data(contentsOf: url)
            #expect(data.count > 0)
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
        let budget = MonthlyBudget(year: 2026, month: 3, limit: 5000)
        let category = CustomCategory(name: "Custom", icon: "star.fill", color: "#0000FF")
        
        await viewModel.exportData(
            transactions: [expense],
            recurringTransactions: [recurring],
            budgets: [budget],
            categories: [category]
        )
        
        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("# TRANSACTIONS"))
            #expect(content.contains("# RECURRING EXPENSES"))
            #expect(content.contains("# BUDGETS"))
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
        let budget = MonthlyBudget(year: 2026, month: 3, limit: 5000)
        let category = CustomCategory(name: "Custom", icon: "star.fill", color: "#0000FF")
        
        await viewModel.exportData(
            transactions: [expense],
            recurringTransactions: [recurring],
            budgets: [budget],
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
            budgets: [],
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
            budgets: [],
            categories: []
        )

        #expect(viewModel.exportedFileURL != nil)
        if let url = viewModel.exportedFileURL {
            let content = try! String(contentsOf: url, encoding: .utf8)
            // Commas and quotes in description should be escaped
            #expect(content.contains("\"Flight, to NYC\""))
        }
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
            budgets: [],
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
    
    private func createTestContext() -> ModelContext {
        ModelContext(makeTestContainer())
    }
    
    // MARK: - JSON Import Tests
    
    @Test
    func testImportTransactionsFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
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
            budgets: nil,
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
    func testImportBudgetsFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            recurringTransactions: nil,
            budgets: [
                ExportData.MonthlyBudgetData(id: UUID().uuidString, year: 2026, month: 3, limit: 5000),
                ExportData.MonthlyBudgetData(id: UUID().uuidString, year: 2026, month: 4, limit: 6000)
            ],
            categories: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_budgets.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.successMessage?.contains("2 budgets") == true)
        
        let descriptor = FetchDescriptor<MonthlyBudget>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 2)
    }
    
    @Test
    func testImportCategoriesFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            recurringTransactions: nil,
            budgets: nil,
            categories: [
                ExportData.CustomCategoryData(
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
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported.first?.name == "Groceries")
    }
    
    @Test
    func testImportRecurringTransactionsFromJSON() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
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
            budgets: nil,
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
        let context = createTestContext()
        
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
            budgets: [
                ExportData.MonthlyBudgetData(id: UUID().uuidString, year: 2026, month: 3, limit: 5000)
            ],
            categories: [
                ExportData.CustomCategoryData(
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
        #expect(viewModel.successMessage?.contains("budgets") == true)
        #expect(viewModel.successMessage?.contains("categories") == true)
    }
    
    @Test
    func testImportEmptyDataShowsNoDataMessage() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            transactions: nil,
            recurringTransactions: nil,
            budgets: nil,
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
    func testImportInvalidJSONShowsError() async {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
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
        let context = createTestContext()
        
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
    func testImportBudgetsFromCSV() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        let csv = """
        id,year,month,limit
        \(UUID().uuidString),2026,3,5000
        \(UUID().uuidString),2026,4,6000
        """
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_budgets.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .csv
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.showSuccess == true)
        
        let descriptor = FetchDescriptor<MonthlyBudget>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 2)
    }
    
    @Test
    func testImportCategoriesFromCSV() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
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
        
        let descriptor = FetchDescriptor<CustomCategory>()
        let imported = try context.fetch(descriptor)
        #expect(imported.count == 1)
        #expect(imported.first?.name == "Groceries")
    }
    
    @Test
    func testImportSectionBasedCSV() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        let csv = """
        # TRANSACTIONS
        id,amount,category,date,time,description,notes,recurring expense id,group transaction id
        \(UUID().uuidString),100,Food,2026-03-12T10:30:00.000Z,,Lunch,,,
        
        # BUDGETS
        id,year,month,limit
        \(UUID().uuidString),2026,3,5000
        
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
        let budDescriptor = FetchDescriptor<MonthlyBudget>()
        let catDescriptor = FetchDescriptor<CustomCategory>()
        
        #expect(try context.fetch(expDescriptor).count == 1)
        #expect(try context.fetch(budDescriptor).count == 1)
        #expect(try context.fetch(catDescriptor).count == 1)
    }
    
    @Test
    func testImportCSVWithEmptyFileDoesNotCrash() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        let csv = "id,amount,category,date\n"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import_empty.csv")
        try csv.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        viewModel.selectedImportFormat = .csv
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.isImporting == false)
    }
    
    @Test
    func testImportResetsImportingFlag() async {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_nonexistent.json")
        
        viewModel.selectedImportFormat = .json
        await viewModel.importData(from: tempURL, context: context)
        
        #expect(viewModel.isImporting == false)
    }
    
    @Test
    func testImportPredefinedCategoryUpdatesExisting() async throws {
        let viewModel = BackupViewModel()
        let context = createTestContext()
        
        // Insert existing predefined category
        let existing = CustomCategory(
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
            budgets: nil,
            categories: [
                ExportData.CustomCategoryData(
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
        
        let descriptor = FetchDescriptor<CustomCategory>()
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
        let context = createTestContext()
        
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
            budgets: nil,
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
        let context = createTestContext()
        
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
            budgets: nil,
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
