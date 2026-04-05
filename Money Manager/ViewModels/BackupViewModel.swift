import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case json = "JSON"
    
    var id: String { rawValue }
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        }
    }
    
    var utType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        }
    }
}

enum ExportDataType: String, CaseIterable, Identifiable {
    case transactions = "Transactions"
    case recurring = "Recurring"
    case budgets = "Budgets"
    case categories = "Categories"
    case all = "All Data"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .transactions: return "creditcard.fill"
        case .recurring: return "arrow.clockwise.circle.fill"
        case .budgets: return "chart.bar.fill"
        case .categories: return "folder.fill"
        case .all: return "archivebox.fill"
        }
    }
}

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    var transactions: [TransactionData]?
    var recurringTransactions: [RecurringTransactionData]?
    var budgets: [MonthlyBudgetData]?
    var categories: [CustomCategoryData]?
    
    struct TransactionData: Codable {
        let id: String
        let type: String
        let amount: Double
        let category: String
        let date: Date
        let time: Date?
        let transactionDescription: String?
        let notes: String?
        let recurringExpenseId: String?
        let groupTransactionId: String?

        init(id: String, type: String = "transaction", amount: Double, category: String, date: Date, time: Date?, transactionDescription: String?, notes: String?, recurringExpenseId: String?, groupTransactionId: String?) {
            self.id = id
            self.type = type
            self.amount = amount
            self.category = category
            self.date = date
            self.time = time
            self.transactionDescription = transactionDescription
            self.notes = notes
            self.recurringExpenseId = recurringExpenseId
            self.groupTransactionId = groupTransactionId
        }
    }
    
    struct RecurringTransactionData: Codable {
        let id: String
        let name: String
        let amount: Double
        let category: String
        let frequency: String
        let dayOfMonth: Int?
        let daysOfWeek: [Int]?
        let startDate: Date
        let endDate: Date?
        let isActive: Bool
        let lastAddedDate: Date?
        let notes: String?
        let createdAt: Date
        let updatedAt: Date
        let type: String

        init(id: String, name: String, amount: Double, category: String, frequency: String, dayOfMonth: Int?, daysOfWeek: [Int]?, startDate: Date, endDate: Date?, isActive: Bool, lastAddedDate: Date?, notes: String?, createdAt: Date, updatedAt: Date, type: String = "expense") {
            self.id = id; self.name = name; self.amount = amount; self.category = category
            self.frequency = frequency; self.dayOfMonth = dayOfMonth; self.daysOfWeek = daysOfWeek
            self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
            self.lastAddedDate = lastAddedDate; self.notes = notes
            self.createdAt = createdAt; self.updatedAt = updatedAt; self.type = type
        }
    }

    struct MonthlyBudgetData: Codable {
        let id: String
        let year: Int
        let month: Int
        let limit: Double
    }
    
    struct CustomCategoryData: Codable {
        let id: String
        let name: String
        let icon: String
        let color: String
        let isHidden: Bool
        let isPredefined: Bool?
        let predefinedKey: String?
    }
}

@MainActor
@Observable class BackupViewModel {
    var isExporting = false
    var isImporting = false
    var showShareSheet = false
    var exportedFileURL: URL?
    var errorMessage: String?
    var showError = false
    var successMessage: String?
    var showSuccess = false
    
    var selectedExportFormat: ExportFormat = .csv
    var selectedDataType: ExportDataType = .all
    var selectedImportFormat: ExportFormat = .json
    
    private let exportService = ExportService()
    private let importService = ImportService()
    
    var exportDescription: String {
        switch selectedExportFormat {
        case .csv:
            return "CSV is ideal for spreadsheets and data analysis. Each data type exports to a separate file."
        case .json:
            switch selectedDataType {
            case .all:
                return "JSON backup includes all your data. Use this for complete backup and restore."
            case .transactions, .recurring, .budgets, .categories:
                return "JSON preserves all data details and is suitable for backup or transfer."
            }
        }
    }
    
    var importDescription: String {
        switch selectedImportFormat {
        case .json:
            return "Import data from a previously exported JSON backup file."
        case .csv:
            return "Import transactions, budgets, or categories from CSV files."
        }
    }
    
    func exportData(
        transactions: [Transaction],
        recurringTransactions: [RecurringTransaction],
        budgets: [MonthlyBudget],
        categories: [CustomCategory],
        groups: [SplitGroupModel] = []
    ) async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let url: URL
            
            switch selectedDataType {
            case .transactions:
                url = try exportService.exportTransactions(format: selectedExportFormat, transactions: transactions, groups: groups)
            case .recurring:
                url = try exportService.exportRecurringTransactions(format: selectedExportFormat, recurringTransactions: recurringTransactions)
            case .budgets:
                url = try exportService.exportBudgets(format: selectedExportFormat, budgets: budgets)
            case .categories:
                url = try exportService.exportCategories(format: selectedExportFormat, categories: categories)
            case .all:
                url = try exportService.exportAll(format: selectedExportFormat, transactions: transactions, recurringTransactions: recurringTransactions, budgets: budgets, categories: categories)
            }
            
            exportedFileURL = url
            showShareSheet = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func importData(from url: URL, context: ModelContext) async {
        isImporting = true
        defer { isImporting = false }
        
        do {
            let result: ImportResult
            
            switch selectedImportFormat {
            case .json:
                result = try importService.importJSON(from: url, context: context)
            case .csv:
                result = try importService.importCSV(from: url, context: context)
            }
            
            successMessage = result.message
            showSuccess = true
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showError = true
        }
    }
}
