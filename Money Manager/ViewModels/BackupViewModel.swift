import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine

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
    case expenses = "Expenses"
    case budgets = "Budgets"
    case categories = "Categories"
    case all = "All Data"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .expenses: return "creditcard.fill"
        case .budgets: return "chart.bar.fill"
        case .categories: return "folder.fill"
        case .all: return "archivebox.fill"
        }
    }
}

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    var expenses: [ExpenseData]?
    var budgets: [MonthlyBudgetData]?
    var categories: [CustomCategoryData]?
    
    struct ExpenseData: Codable {
        let id: String
        let amount: Double
        let category: String
        let date: Date
        let time: Date?
        let expenseDescription: String?
        let notes: String?
        let isRecurring: Bool
        let frequency: String?
        let dayOfMonth: Int?
        let daysOfWeek: [Int]?
        let recurringEndDate: Date?
        let isActive: Bool
        let groupId: String?
        let groupName: String?
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
    }
}

@MainActor
class BackupViewModel: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var showShareSheet = false
    @Published var exportedFileURL: URL?
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var successMessage: String?
    @Published var showSuccess = false
    
    @Published var selectedExportFormat: ExportFormat = .csv
    @Published var selectedDataType: ExportDataType = .all
    @Published var selectedImportFormat: ExportFormat = .json
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var exportDescription: String {
        switch selectedExportFormat {
        case .csv:
            return "CSV is ideal for spreadsheets and data analysis. Each data type exports to a separate file."
        case .json:
            switch selectedDataType {
            case .all:
                return "JSON backup includes all your data. Use this for complete backup and restore."
            case .expenses, .budgets, .categories:
                return "JSON preserves all data details and is suitable for backup or transfer."
            }
        }
    }
    
    var importDescription: String {
        switch selectedImportFormat {
        case .json:
            return "Import data from a previously exported JSON backup file."
        case .csv:
            return "Import expenses, budgets, or categories from CSV files."
        }
    }
    
    func exportData(
        expenses: [Expense],
        budgets: [MonthlyBudget],
        categories: [CustomCategory]
    ) async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let url: URL
            
            switch selectedDataType {
            case .expenses:
                url = try await exportExpenses(format: selectedExportFormat, expenses: expenses)
            case .budgets:
                url = try await exportBudgets(format: selectedExportFormat, budgets: budgets)
            case .categories:
                url = try await exportCategories(format: selectedExportFormat, categories: categories)
            case .all:
                url = try await exportAll(format: selectedExportFormat, expenses: expenses, budgets: budgets, categories: categories)
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
            switch selectedImportFormat {
            case .json:
                try await importJSON(from: url, context: context)
            case .csv:
                try await importCSV(from: url, context: context)
            }
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Export Methods
    
    private func exportExpenses(format: ExportFormat, expenses: [Expense]) async throws -> URL {
        let activeExpenses = expenses.filter { !$0.isDeleted }
        
        switch format {
        case .csv:
            return try exportExpensesToCSV(expenses: activeExpenses)
        case .json:
            return try exportExpensesToJSON(expenses: activeExpenses)
        }
    }
    
    private func exportBudgets(format: ExportFormat, budgets: [MonthlyBudget]) async throws -> URL {
        switch format {
        case .csv:
            return try exportBudgetsToCSV(budgets: budgets)
        case .json:
            return try exportBudgetsToJSON(budgets: budgets)
        }
    }
    
    private func exportCategories(format: ExportFormat, categories: [CustomCategory]) async throws -> URL {
        switch format {
        case .csv:
            return try exportCategoriesToCSV(categories: categories)
        case .json:
            return try exportCategoriesToJSON(categories: categories)
        }
    }
    
    private func exportAll(format: ExportFormat, expenses: [Expense], budgets: [MonthlyBudget], categories: [CustomCategory]) async throws -> URL {
        let activeExpenses = expenses.filter { !$0.isDeleted }
        
        switch format {
        case .csv:
            return try exportExpensesToCSV(expenses: activeExpenses)
        case .json:
            return try exportAllToJSON(expenses: activeExpenses, budgets: budgets, categories: categories)
        }
    }
    
    // MARK: - CSV Export
    
    private func exportExpensesToCSV(expenses: [Expense]) throws -> URL {
        var csv = "ID,Amount,Category,Date,Time,Description,Notes,Is Recurring,Frequency,Day of Month,Days of Week,Recurring End Date,Is Active,Group ID,Group Name\n"
        
        for expense in expenses {
            let id = expense.id.uuidString
            let amount = String(expense.amount)
            let category = escapeCSV(expense.category)
            let date = dateFormatter.string(from: expense.date)
            let time = expense.time.map { dateFormatter.string(from: $0) } ?? ""
            let description = escapeCSV(expense.expenseDescription ?? "")
            let notes = escapeCSV(expense.notes ?? "")
            let isRecurring = String(expense.isRecurring)
            let frequency = expense.frequency ?? ""
            let dayOfMonth = expense.dayOfMonth.map { String($0) } ?? ""
            let daysOfWeek = expense.daysOfWeek.map { $0.map { String($0) }.joined(separator: ";") } ?? ""
            let recurringEndDate = expense.recurringEndDate.map { dateFormatter.string(from: $0) } ?? ""
            let isActive = String(expense.isActive)
            let groupId = expense.groupId?.uuidString ?? ""
            let groupName = escapeCSV(expense.groupName ?? "")
            
            let row = [id, amount, category, date, time, description, notes, isRecurring, frequency, dayOfMonth, daysOfWeek, recurringEndDate, isActive, groupId, groupName].joined(separator: ",")
            csv += row + "\n"
        }
        
        let fileName = "expenses_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }
    
    private func exportBudgetsToCSV(budgets: [MonthlyBudget]) throws -> URL {
        var csv = "ID,Year,Month,Limit\n"
        
        for budget in budgets {
            let row = [
                budget.id.uuidString,
                String(budget.year),
                String(budget.month),
                String(budget.limit)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        let fileName = "budgets_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }
    
    private func exportCategoriesToCSV(categories: [CustomCategory]) throws -> URL {
        var csv = "ID,Name,Icon,Color,Is Hidden\n"
        
        for category in categories {
            let row = [
                category.id.uuidString,
                escapeCSV(category.name),
                category.icon,
                category.color,
                String(category.isHidden)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        let fileName = "categories_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }
    
    // MARK: - JSON Export
    
    private func exportExpensesToJSON(expenses: [Expense]) throws -> URL {
        let expenseData = expenses.map { expense in
            ExportData.ExpenseData(
                id: expense.id.uuidString,
                amount: expense.amount,
                category: expense.category,
                date: expense.date,
                time: expense.time,
                expenseDescription: expense.expenseDescription,
                notes: expense.notes,
                isRecurring: expense.isRecurring,
                frequency: expense.frequency,
                dayOfMonth: expense.dayOfMonth,
                daysOfWeek: expense.daysOfWeek,
                recurringEndDate: expense.recurringEndDate,
                isActive: expense.isActive,
                groupId: expense.groupId?.uuidString,
                groupName: expense.groupName
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: expenseData,
            budgets: nil,
            categories: nil
        )
        
        return try saveToJSON(exportData, fileName: "expenses_\(dateString()).json")
    }
    
    private func exportBudgetsToJSON(budgets: [MonthlyBudget]) throws -> URL {
        let budgetData = budgets.map { budget in
            ExportData.MonthlyBudgetData(
                id: budget.id.uuidString,
                year: budget.year,
                month: budget.month,
                limit: budget.limit
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: nil,
            budgets: budgetData,
            categories: nil
        )
        
        return try saveToJSON(exportData, fileName: "budgets_\(dateString()).json")
    }
    
    private func exportCategoriesToJSON(categories: [CustomCategory]) throws -> URL {
        let categoryData = categories.map { category in
            ExportData.CustomCategoryData(
                id: category.id.uuidString,
                name: category.name,
                icon: category.icon,
                color: category.color,
                isHidden: category.isHidden
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: nil,
            budgets: nil,
            categories: categoryData
        )
        
        return try saveToJSON(exportData, fileName: "categories_\(dateString()).json")
    }
    
    private func exportAllToJSON(expenses: [Expense], budgets: [MonthlyBudget], categories: [CustomCategory]) throws -> URL {
        let expenseData = expenses.map { expense in
            ExportData.ExpenseData(
                id: expense.id.uuidString,
                amount: expense.amount,
                category: expense.category,
                date: expense.date,
                time: expense.time,
                expenseDescription: expense.expenseDescription,
                notes: expense.notes,
                isRecurring: expense.isRecurring,
                frequency: expense.frequency,
                dayOfMonth: expense.dayOfMonth,
                daysOfWeek: expense.daysOfWeek,
                recurringEndDate: expense.recurringEndDate,
                isActive: expense.isActive,
                groupId: expense.groupId?.uuidString,
                groupName: expense.groupName
            )
        }
        
        let budgetData = budgets.map { budget in
            ExportData.MonthlyBudgetData(
                id: budget.id.uuidString,
                year: budget.year,
                month: budget.month,
                limit: budget.limit
            )
        }
        
        let categoryData = categories.map { category in
            ExportData.CustomCategoryData(
                id: category.id.uuidString,
                name: category.name,
                icon: category.icon,
                color: category.color,
                isHidden: category.isHidden
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: expenseData,
            budgets: budgetData,
            categories: categoryData
        )
        
        return try saveToJSON(exportData, fileName: "money_manager_backup_\(dateString()).json")
    }
    
    // MARK: - Import Methods
    
    private func importJSON(from url: URL, context: ModelContext) async throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: data)
        
        try await processImportedData(exportData, context: context)
    }
    
    private func importCSV(from url: URL, context: ModelContext) async throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else { return }
        
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine)
        
        var expenses: [ExportData.ExpenseData] = []
        var budgets: [ExportData.MonthlyBudgetData] = []
        var categories: [ExportData.CustomCategoryData] = []
        
        let firstHeader = headers.first?.lowercased() ?? ""
        
        if firstHeader == "id" && headers.contains("amount") && headers.contains("category") {
            for i in 1..<lines.count {
                let values = parseCSVLine(lines[i])
                if let expense = parseExpenseCSVRow(values, headers: headers) {
                    expenses.append(expense)
                }
            }
        } else if firstHeader == "id" && headers.contains("limit") && headers.contains("year") {
            for i in 1..<lines.count {
                let values = parseCSVLine(lines[i])
                if let budget = parseBudgetCSVRow(values, headers: headers) {
                    budgets.append(budget)
                }
            }
        } else if firstHeader == "id" && headers.contains("name") && headers.contains("icon") {
            for i in 1..<lines.count {
                let values = parseCSVLine(lines[i])
                if let category = parseCategoryCSVRow(values, headers: headers) {
                    categories.append(category)
                }
            }
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: expenses.isEmpty ? nil : expenses,
            budgets: budgets.isEmpty ? nil : budgets,
            categories: categories.isEmpty ? nil : categories
        )
        
        try await processImportedData(exportData, context: context)
    }
    
    private func processImportedData(_ exportData: ExportData, context: ModelContext) async throws {
        var expensesImported = 0
        var budgetsImported = 0
        var categoriesImported = 0
        
        if let expenses = exportData.expenses {
            for expenseData in expenses {
                let expense = Expense(
                    id: UUID(uuidString: expenseData.id) ?? UUID(),
                    amount: expenseData.amount,
                    category: expenseData.category,
                    date: expenseData.date,
                    time: expenseData.time,
                    expenseDescription: expenseData.expenseDescription,
                    notes: expenseData.notes,
                    isRecurring: expenseData.isRecurring,
                    frequency: expenseData.frequency,
                    dayOfMonth: expenseData.dayOfMonth,
                    daysOfWeek: expenseData.daysOfWeek,
                    recurringEndDate: expenseData.recurringEndDate,
                    groupId: expenseData.groupId.flatMap { UUID(uuidString: $0) },
                    groupName: expenseData.groupName
                )
                context.insert(expense)
                expensesImported += 1
            }
        }
        
        if let budgets = exportData.budgets {
            for budgetData in budgets {
                let budget = MonthlyBudget(
                    id: UUID(uuidString: budgetData.id) ?? UUID(),
                    year: budgetData.year,
                    month: budgetData.month,
                    limit: budgetData.limit
                )
                context.insert(budget)
                budgetsImported += 1
            }
        }
        
        if let categories = exportData.categories {
            for categoryData in categories {
                let category = CustomCategory(
                    id: UUID(uuidString: categoryData.id) ?? UUID(),
                    name: categoryData.name,
                    icon: categoryData.icon,
                    color: categoryData.color
                )
                category.isHidden = categoryData.isHidden
                context.insert(category)
                categoriesImported += 1
            }
        }
        
        try context.save()
        
        var message = ""
        if expensesImported > 0 { message += "\(expensesImported) expenses" }
        if budgetsImported > 0 { message += message.isEmpty ? "\(budgetsImported) budgets" : ", \(budgetsImported) budgets" }
        if categoriesImported > 0 { message += message.isEmpty ? "\(categoriesImported) categories" : ", \(categoriesImported) categories" }
        
        if message.isEmpty {
            message = "No data found to import"
        }
        
        successMessage = "Imported: \(message)"
        showSuccess = true
    }
    
    // MARK: - CSV Parsing
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        
        return result
    }
    
    private func parseExpenseCSVRow(_ values: [String], headers: [String]) -> ExportData.ExpenseData? {
        guard values.count == headers.count else { return nil }
        
        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        
        let dateStr = dict["date"] ?? ""
        let timeStr = dict["time"] ?? ""
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let date = isoFormatter.date(from: dateStr) ?? dateFormatter.date(from: dateStr) ?? Date()
        let time = timeStr.isEmpty ? nil : (isoFormatter.date(from: timeStr) ?? dateFormatter.date(from: timeStr))
        
        let recurringEndDateStr = dict["recurring end date"] ?? ""
        let recurringEndDate = recurringEndDateStr.isEmpty ? nil : (isoFormatter.date(from: recurringEndDateStr) ?? dateFormatter.date(from: recurringEndDateStr))
        
        let daysOfWeekStr = dict["days of week"] ?? ""
        let daysOfWeek = daysOfWeekStr.isEmpty ? nil : daysOfWeekStr.components(separatedBy: ";").compactMap { Int($0) }
        
        return ExportData.ExpenseData(
            id: dict["id"] ?? UUID().uuidString,
            amount: Double(dict["amount"] ?? "0") ?? 0,
            category: dict["category"] ?? "Other",
            date: date,
            time: time,
            expenseDescription: dict["description"]?.isEmpty == false ? dict["description"] : nil,
            notes: dict["notes"]?.isEmpty == false ? dict["notes"] : nil,
            isRecurring: dict["is recurring"]?.lowercased() == "true",
            frequency: dict["frequency"]?.isEmpty == false ? dict["frequency"] : nil,
            dayOfMonth: dict["day of month"]?.isEmpty == false ? Int(dict["day of month"] ?? "") : nil,
            daysOfWeek: daysOfWeek,
            recurringEndDate: recurringEndDate,
            isActive: dict["is active"]?.lowercased() != "false",
            groupId: dict["group id"]?.isEmpty == false ? dict["group id"] : nil,
            groupName: dict["group name"]?.isEmpty == false ? dict["group name"] : nil
        )
    }
    
    private func parseBudgetCSVRow(_ values: [String], headers: [String]) -> ExportData.MonthlyBudgetData? {
        guard values.count == headers.count else { return nil }
        
        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        
        return ExportData.MonthlyBudgetData(
            id: dict["id"] ?? UUID().uuidString,
            year: Int(dict["year"] ?? "2026") ?? 2026,
            month: Int(dict["month"] ?? "1") ?? 1,
            limit: Double(dict["limit"] ?? "0") ?? 0
        )
    }
    
    private func parseCategoryCSVRow(_ values: [String], headers: [String]) -> ExportData.CustomCategoryData? {
        guard values.count == headers.count else { return nil }
        
        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        
        return ExportData.CustomCategoryData(
            id: dict["id"] ?? UUID().uuidString,
            name: dict["name"] ?? "Custom",
            icon: dict["icon"] ?? "folder.fill",
            color: dict["color"] ?? "#808080",
            isHidden: dict["is hidden"]?.lowercased() == "true"
        )
    }
    
    // MARK: - Helpers
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
    
    private func saveToTempFile(_ content: String, fileName: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func saveToJSON(_ data: ExportData, fileName: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try jsonData.write(to: fileURL)
        return fileURL
    }
}
