import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers
@testable import Money_Manager

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

struct ExportDataTypeTests {
    
    @Test
    func testExpensesIcon() {
        #expect(!ExportDataType.expenses.icon.isEmpty)
    }
    
    @Test
    func testRecurringExpensesIcon() {
        #expect(!ExportDataType.recurringExpenses.icon.isEmpty)
    }
    
    @Test
    func testBudgetsIcon() {
        #expect(!ExportDataType.budgets.icon.isEmpty)
    }
    
    @Test
    func testCategoriesIcon() {
        #expect(!ExportDataType.categories.icon.isEmpty)
    }
    
    @Test
    func testAllDataIcon() {
        #expect(!ExportDataType.all.icon.isEmpty)
    }
    
    @Test
    func testExportDataTypeIdMatchesRawValue() {
        #expect(ExportDataType.expenses.id == "Expenses")
        #expect(ExportDataType.recurringExpenses.id == "Recurring Expenses")
        #expect(ExportDataType.budgets.id == "Budgets")
        #expect(ExportDataType.categories.id == "Categories")
        #expect(ExportDataType.all.id == "All Data")
    }
    
    @Test
    func testAllExportDataTypesHaveCases() {
        #expect(ExportDataType.allCases.count == 5)
    }
}

struct ExportDataStructTests {
    
    @Test
    func testExpenseDataInitialization() {
        let expenseData = ExportData.ExpenseData(
            id: "test-id",
            amount: 100.50,
            category: "Food",
            date: Date(),
            time: nil,
            expenseDescription: "Lunch",
            notes: nil,
            recurringExpenseId: nil,
            groupId: nil,
            groupName: nil
        )
        
        #expect(expenseData.id == "test-id")
        #expect(expenseData.amount == 100.50)
        #expect(expenseData.category == "Food")
        #expect(expenseData.expenseDescription == "Lunch")
    }
    
    @Test
    func testRecurringExpenseDataInitialization() {
        let recurringData = ExportData.RecurringExpenseData(
            id: "rec-1",
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
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
        let expenseData = ExportData.ExpenseData(
            id: "exp-1",
            amount: 100,
            category: "Food",
            date: Date(),
            time: nil,
            expenseDescription: "Test",
            notes: nil,
            recurringExpenseId: nil,
            groupId: nil,
            groupName: nil
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
            expenses: [expenseData],
            recurringExpenses: nil,
            budgets: [budgetData],
            categories: nil
        )
        
        #expect(exportData.expenses?.count == 1)
        #expect(exportData.budgets?.count == 1)
        #expect(exportData.appVersion == "1.0")
    }
    
    @Test
    func testExportDataCodable() throws {
        let expenseData = ExportData.ExpenseData(
            id: "exp-1",
            amount: 100,
            category: "Food",
            date: Date(),
            time: nil,
            expenseDescription: "Test",
            notes: nil,
            recurringExpenseId: nil,
            groupId: nil,
            groupName: nil
        )
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: "1.0",
            expenses: [expenseData],
            recurringExpenses: nil,
            budgets: nil,
            categories: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(exportData)
        
        #expect(jsonData.count > 0)
    }
    
    @Test
    func testRecurringExpenseDataCodable() throws {
        let recurringData = ExportData.RecurringExpenseData(
            id: "rec-1",
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: "monthly",
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
    func testExportDescriptionForJSONExpenses() {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .expenses
        
        #expect(viewModel.exportDescription.contains("JSON"))
    }
    
    @Test
    func testExportDescriptionForJSONRecurringExpenses() {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .recurringExpenses
        
        #expect(viewModel.exportDescription.contains("JSON"))
    }
    
    @Test
    func testExportDescriptionForJSONBudgets() {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .budgets
        
        #expect(viewModel.exportDescription.contains("JSON"))
    }
    
    @Test
    func testExportDescriptionForJSONCategories() {
        let viewModel = BackupViewModel()
        viewModel.selectedExportFormat = .json
        viewModel.selectedDataType = .categories
        
        #expect(viewModel.exportDescription.contains("JSON"))
    }
    
    @Test
    func testImportDescriptionForJSON() {
        let viewModel = BackupViewModel()
        viewModel.selectedImportFormat = .json
        
        #expect(viewModel.importDescription.contains("JSON"))
    }
    
    @Test
    func testImportDescriptionForCSV() {
        let viewModel = BackupViewModel()
        viewModel.selectedImportFormat = .csv
        
        #expect(viewModel.importDescription.contains("CSV"))
    }
}
