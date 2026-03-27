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
    case expenses = "Expenses"
    case recurringExpenses = "Recurring Expenses"
    case budgets = "Budgets"
    case categories = "Categories"
    case all = "All Data"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .expenses: return "creditcard.fill"
        case .recurringExpenses: return "arrow.clockwise.circle.fill"
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
    var recurringExpenses: [RecurringExpenseData]?
    var budgets: [MonthlyBudgetData]?
    var categories: [CustomCategoryData]?
    
    struct ExpenseData: Codable {
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

        init(id: String, type: String = "expense", amount: Double, category: String, date: Date, time: Date?, transactionDescription: String?, notes: String?, recurringExpenseId: String?, groupTransactionId: String?) {
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
    
    struct RecurringExpenseData: Codable {
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    func parseDate(_ dateStr: String, _ timeStr: String? = nil) -> (date: Date, time: Date?) {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let dateFormats = [
            "d MMM yyyy 'at' h:mm a",
            "d MMM yyyy 'at' h:mm:ss a",
            "MMM d, yyyy 'at' h:mm a",
            "MM/dd/yyyy",
            "yyyy-MM-dd"
        ]
        
        var parsedDate: Date?
        var parsedTime: Date?
        
        if !dateStr.isEmpty {
            if let isoDate = isoFormatter.date(from: dateStr) {
                parsedDate = isoDate
            } else {
                for format in dateFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateStr) {
                        parsedDate = date
                        break
                    }
                }
            }
            
            if parsedDate == nil {
                parsedDate = dateFormatter.date(from: dateStr)
            }
            if parsedDate == nil {
                parsedDate = dateOnlyFormatter.date(from: dateStr)
            }
        }
        
        if let timeStr = timeStr, !timeStr.isEmpty {
            if let isoTime = isoFormatter.date(from: timeStr) {
                parsedTime = isoTime
            } else {
                for format in dateFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let time = formatter.date(from: timeStr) {
                        parsedTime = time
                        break
                    }
                }
            }
            
            if parsedTime == nil {
                parsedTime = dateFormatter.date(from: timeStr)
            }
        }
        
        return (parsedDate ?? Date(), parsedTime)
    }
    
    var exportDescription: String {
        switch selectedExportFormat {
        case .csv:
            return "CSV is ideal for spreadsheets and data analysis. Each data type exports to a separate file."
        case .json:
            switch selectedDataType {
            case .all:
                return "JSON backup includes all your data. Use this for complete backup and restore."
            case .expenses, .recurringExpenses, .budgets, .categories:
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
        expenses: [Transaction],
        recurringExpenses: [RecurringExpense],
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
            case .recurringExpenses:
                url = try await exportRecurringExpenses(format: selectedExportFormat, recurringExpenses: recurringExpenses)
            case .budgets:
                url = try await exportBudgets(format: selectedExportFormat, budgets: budgets)
            case .categories:
                url = try await exportCategories(format: selectedExportFormat, categories: categories)
            case .all:
                url = try await exportAll(format: selectedExportFormat, expenses: expenses, recurringExpenses: recurringExpenses, budgets: budgets, categories: categories)
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
    
    private func exportExpenses(format: ExportFormat, expenses: [Transaction]) async throws -> URL {
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
    
    private func exportAll(format: ExportFormat, expenses: [Transaction], recurringExpenses: [RecurringExpense], budgets: [MonthlyBudget], categories: [CustomCategory]) async throws -> URL {
        let activeExpenses = expenses.filter { !$0.isDeleted }
        
        switch format {
        case .csv:
            return try exportAllToCSV(expenses: activeExpenses, recurringExpenses: recurringExpenses, budgets: budgets, categories: categories)
        case .json:
            return try exportAllToJSON(expenses: activeExpenses, recurringExpenses: recurringExpenses, budgets: budgets, categories: categories)
        }
    }
    
    private func exportRecurringExpenses(format: ExportFormat, recurringExpenses: [RecurringExpense]) async throws -> URL {
        switch format {
        case .csv:
            return try exportRecurringExpensesToCSV(recurringExpenses: recurringExpenses)
        case .json:
            return try exportRecurringExpensesToJSON(recurringExpenses: recurringExpenses)
        }
    }
    
    private func exportRecurringExpensesToJSON(recurringExpenses: [RecurringExpense]) throws -> URL {
        let recurringData = recurringExpenses.map { recurring in
            ExportData.RecurringExpenseData(
                id: recurring.id.uuidString,
                name: recurring.name,
                amount: recurring.amount,
                category: recurring.category,
                frequency: recurring.frequency,
                dayOfMonth: recurring.dayOfMonth,
                daysOfWeek: recurring.daysOfWeek,
                startDate: recurring.startDate,
                endDate: recurring.endDate,
                isActive: recurring.isActive,
                lastAddedDate: recurring.lastAddedDate,
                notes: recurring.notes,
                createdAt: recurring.createdAt,
                updatedAt: recurring.updatedAt
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: nil,
            recurringExpenses: recurringData,
            budgets: nil,
            categories: nil
        )
        
        return try saveToJSON(exportData, fileName: "recurring_expenses_\(dateString()).json")
    }
    
    private func exportRecurringExpensesToCSV(recurringExpenses: [RecurringExpense]) throws -> URL {
        var csv = "ID,Name,Amount,Category,Frequency,Day of Month,Days of Week,Start Date,End Date,Is Active,Notes\n"
        
        for recurring in recurringExpenses {
            let id = recurring.id.uuidString
            let name = escapeCSV(recurring.name)
            let amount = String(recurring.amount)
            let category = escapeCSV(recurring.category)
            let frequency = recurring.frequency
            let dayOfMonth = recurring.dayOfMonth.map { String($0) } ?? ""
            let daysOfWeek = recurring.daysOfWeek.map { $0.map { String($0) }.joined(separator: ";") } ?? ""
            let startDate = iso8601Formatter.string(from: recurring.startDate)
            let endDate = recurring.endDate.map { iso8601Formatter.string(from: $0) } ?? ""
            let isActive = String(recurring.isActive)
            let notes = escapeCSV(recurring.notes ?? "")
            
            let row = [id, name, amount, category, frequency, dayOfMonth, daysOfWeek, startDate, endDate, isActive, notes].joined(separator: ",")
            csv += row + "\n"
        }
        
        let fileName = "recurring_expenses_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }
    
    // MARK: - CSV Export
    
    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private func exportAllToCSV(expenses: [Transaction], recurringExpenses: [RecurringExpense], budgets: [MonthlyBudget], categories: [CustomCategory]) throws -> URL {
        var csv = ""
        
        // Expenses section
        csv += "# EXPENSES\n"
        csv += "ID,Amount,Category,Date,Time,Description,Notes,Recurring Expense ID,Group ID,Group Name\n"
        
        for expense in expenses {
            let id = expense.id.uuidString
            let amount = String(expense.amount)
            let category = escapeCSV(expense.category)
            let date = iso8601Formatter.string(from: expense.date)
            let time = expense.time.map { iso8601Formatter.string(from: $0) } ?? ""
            let desc = escapeCSV(expense.transactionDescription ?? "")
            let notes = escapeCSV(expense.notes ?? "")
            let recId = expense.recurringExpenseId?.uuidString ?? ""
            let gid = expense.groupTransactionId?.uuidString ?? ""
            let gname = escapeCSV(nil ?? "")
            
            let row = [id, amount, category, date, time, desc, notes, recId, gid, gname].joined(separator: ",")
            csv += row + "\n"
        }
        
        // Recurring Expenses section
        csv += "\n# RECURRING EXPENSES\n"
        csv += "ID,Name,Amount,Category,Frequency,Day of Month,Days of Week,Start Date,End Date,Is Active,Notes\n"
        
        for recurring in recurringExpenses {
            let id = recurring.id.uuidString
            let name = escapeCSV(recurring.name)
            let amount = String(recurring.amount)
            let category = escapeCSV(recurring.category)
            let frequency = recurring.frequency
            let dayOfMonth = recurring.dayOfMonth.map { String($0) } ?? ""
            let daysOfWeek = recurring.daysOfWeek.map { $0.map { String($0) }.joined(separator: ";") } ?? ""
            let startDate = iso8601Formatter.string(from: recurring.startDate)
            let endDate = recurring.endDate.map { iso8601Formatter.string(from: $0) } ?? ""
            let isActive = String(recurring.isActive)
            let notes = escapeCSV(recurring.notes ?? "")
            
            let row = [id, name, amount, category, frequency, dayOfMonth, daysOfWeek, startDate, endDate, isActive, notes].joined(separator: ",")
            csv += row + "\n"
        }
        
        // Budgets section
        csv += "\n# BUDGETS\n"
        csv += "ID,Year,Month,Limit\n"
        
        for budget in budgets {
            let row = [
                budget.id.uuidString,
                String(budget.year),
                String(budget.month),
                String(budget.limit)
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        // Categories section
        csv += "\n# CATEGORIES\n"
        csv += "ID,Name,Icon,Color,Is Hidden,Is Predefined,Predefined Key\n"
        
        for category in categories {
            let row = [
                category.id.uuidString,
                escapeCSV(category.name),
                category.icon,
                category.color,
                String(category.isHidden),
                String(category.isPredefined),
                category.predefinedKey ?? ""
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        let fileName = "money_manager_backup_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }
    
    private func exportExpensesToCSV(expenses: [Transaction]) throws -> URL {
        var csv = "ID,Amount,Category,Date,Time,Description,Notes,Recurring Expense ID,Group ID,Group Name\n"
        
        for expense in expenses {
            let id = expense.id.uuidString
            let amount = String(expense.amount)
            let category = escapeCSV(expense.category)
            let date = iso8601Formatter.string(from: expense.date)
            let time = expense.time.map { iso8601Formatter.string(from: $0) } ?? ""
            let description = escapeCSV(expense.transactionDescription ?? "")
            let notes = escapeCSV(expense.notes ?? "")
            let recurringExpenseId = expense.recurringExpenseId?.uuidString ?? ""
            let groupId = expense.groupTransactionId?.uuidString ?? ""
            let groupName = escapeCSV(nil ?? "")
            
            let row = [id, amount, category, date, time, description, notes, recurringExpenseId, groupId, groupName].joined(separator: ",")
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
        var csv = "ID,Name,Icon,Color,Is Hidden,Is Predefined,Predefined Key\n"
        
        for category in categories {
            let row = [
                category.id.uuidString,
                escapeCSV(category.name),
                category.icon,
                category.color,
                String(category.isHidden),
                String(category.isPredefined),
                category.predefinedKey ?? ""
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        let fileName = "categories_\(dateString()).csv"
        return try saveToTempFile(csv, fileName: fileName)
    }
    
    // MARK: - JSON Export
    
    private func exportExpensesToJSON(expenses: [Transaction]) throws -> URL {
        let expenseData = expenses.map { expense in
            ExportData.ExpenseData(
                id: expense.id.uuidString,
                type: expense.type,
                amount: expense.amount,
                category: expense.category,
                date: expense.date,
                time: expense.time,
                transactionDescription: expense.transactionDescription,
                notes: expense.notes,
                recurringExpenseId: expense.recurringExpenseId?.uuidString,
                groupTransactionId: expense.groupTransactionId?.uuidString
            )
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: expenseData,
            recurringExpenses: nil,
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
            recurringExpenses: nil,
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
                isHidden: category.isHidden,
                isPredefined: category.isPredefined,
                predefinedKey: category.predefinedKey
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: nil,
            recurringExpenses: nil,
            budgets: nil,
            categories: categoryData
        )
        
        return try saveToJSON(exportData, fileName: "categories_\(dateString()).json")
    }
    
    private func exportAllToJSON(expenses: [Transaction], recurringExpenses: [RecurringExpense], budgets: [MonthlyBudget], categories: [CustomCategory]) throws -> URL {
        let expenseData = expenses.map { expense in
            ExportData.ExpenseData(
                id: expense.id.uuidString,
                type: expense.type,
                amount: expense.amount,
                category: expense.category,
                date: expense.date,
                time: expense.time,
                transactionDescription: expense.transactionDescription,
                notes: expense.notes,
                recurringExpenseId: expense.recurringExpenseId?.uuidString,
                groupTransactionId: expense.groupTransactionId?.uuidString
            )
        }

        let recurringExpenseData = recurringExpenses.map { recurring in
            ExportData.RecurringExpenseData(
                id: recurring.id.uuidString,
                name: recurring.name,
                amount: recurring.amount,
                category: recurring.category,
                frequency: recurring.frequency,
                dayOfMonth: recurring.dayOfMonth,
                daysOfWeek: recurring.daysOfWeek,
                startDate: recurring.startDate,
                endDate: recurring.endDate,
                isActive: recurring.isActive,
                lastAddedDate: recurring.lastAddedDate,
                notes: recurring.notes,
                createdAt: recurring.createdAt,
                updatedAt: recurring.updatedAt
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
                isHidden: category.isHidden,
                isPredefined: category.isPredefined,
                predefinedKey: category.predefinedKey
            )
        }
        
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            expenses: expenseData,
            recurringExpenses: recurringExpenseData,
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
        
        // Check if it's the new section-based format
        if content.contains("# EXPENSES") || content.contains("# BUDGETS") || content.contains("# CATEGORIES") {
            try await importSectionBasedCSV(content: content, context: context)
            return
        }
        
        // Legacy single-section format
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else { return }
        
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine)
        
        var expenses: [ExportData.ExpenseData] = []
        var budgets: [ExportData.MonthlyBudgetData] = []
        var categories: [ExportData.CustomCategoryData] = []
        
        let lowercaseHeaders = headers.map { $0.lowercased() }
        let firstHeader = lowercaseHeaders.first ?? ""
        
        if firstHeader == "id" && lowercaseHeaders.contains("amount") && lowercaseHeaders.contains("category") {
            for i in 1..<lines.count {
                let values = parseCSVLine(lines[i])
                if let expense = parseExpenseCSVRow(values, headers: lowercaseHeaders) {
                    expenses.append(expense)
                }
            }
        } else if firstHeader == "id" && lowercaseHeaders.contains("limit") && lowercaseHeaders.contains("year") {
            for i in 1..<lines.count {
                let values = parseCSVLine(lines[i])
                if let budget = parseBudgetCSVRow(values, headers: lowercaseHeaders) {
                    budgets.append(budget)
                }
            }
        } else if firstHeader == "id" && lowercaseHeaders.contains("name") && lowercaseHeaders.contains("icon") {
            for i in 1..<lines.count {
                let values = parseCSVLine(lines[i])
                if let category = parseCategoryCSVRow(values, headers: lowercaseHeaders) {
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
    
    private func importSectionBasedCSV(content: String, context: ModelContext) async throws {
        var expenses: [ExportData.ExpenseData] = []
        var budgets: [ExportData.MonthlyBudgetData] = []
        var categories: [ExportData.CustomCategoryData] = []
        
        let sections = content.components(separatedBy: "\n# ")
        
        for section in sections {
            let lines = section.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { continue }
            
            let sectionHeader = lines[0]
            let headers = parseCSVLine(lines[1]).map { $0.lowercased() }
            
            if sectionHeader.contains("EXPENSES") {
                for i in 2..<lines.count {
                    let values = parseCSVLine(lines[i])
                    if let expense = parseExpenseCSVRow(values, headers: headers) {
                        expenses.append(expense)
                    }
                }
            } else if sectionHeader.contains("BUDGETS") {
                for i in 2..<lines.count {
                    let values = parseCSVLine(lines[i])
                    if let budget = parseBudgetCSVRow(values, headers: headers) {
                        budgets.append(budget)
                    }
                }
            } else if sectionHeader.contains("CATEGORIES") {
                for i in 2..<lines.count {
                    let values = parseCSVLine(lines[i])
                    if let category = parseCategoryCSVRow(values, headers: headers) {
                        categories.append(category)
                    }
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
        var recurringExpensesImported = 0
        var budgetsImported = 0
        var categoriesImported = 0
        
        var recurringExpenseIdMap: [String: UUID] = [:]
        
        if let recurringExpenses = exportData.recurringExpenses {
            for recurringData in recurringExpenses {
                let recurringExpense = RecurringExpense(
                    id: UUID(uuidString: recurringData.id) ?? UUID(),
                    name: recurringData.name,
                    amount: recurringData.amount,
                    category: recurringData.category,
                    frequency: recurringData.frequency,
                    dayOfMonth: recurringData.dayOfMonth,
                    daysOfWeek: recurringData.daysOfWeek,
                    startDate: recurringData.startDate,
                    endDate: recurringData.endDate,
                    isActive: recurringData.isActive,
                    lastAddedDate: recurringData.lastAddedDate,
                    notes: recurringData.notes
                )
                context.insert(recurringExpense)
                recurringExpensesImported += 1
                recurringExpenseIdMap[recurringData.id] = recurringExpense.id
            }
        }
        
        if let expenses = exportData.expenses {
            for expenseData in expenses {
                let recurringExpenseId: UUID?
                if let recIdString = expenseData.recurringExpenseId,
                   let recId = recurringExpenseIdMap[recIdString] {
                    recurringExpenseId = recId
                } else {
                    recurringExpenseId = nil
                }
                
                let expense = Transaction(
                    id: UUID(uuidString: expenseData.id) ?? UUID(),
                    type: expenseData.type,
                    amount: expenseData.amount,
                    category: expenseData.category,
                    date: expenseData.date,
                    time: expenseData.time,
                    transactionDescription: expenseData.transactionDescription,
                    notes: expenseData.notes,
                    recurringExpenseId: recurringExpenseId,
                    groupTransactionId: expenseData.groupTransactionId.flatMap { UUID(uuidString: $0) }
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
                let isPredefined = categoryData.isPredefined ?? false
                let predefinedKey = categoryData.predefinedKey
                
                // For predefined categories, update existing record if found
                if isPredefined, let key = predefinedKey {
                    let keyToFind = key
                    let descriptor = FetchDescriptor<CustomCategory>(
                        predicate: #Predicate { $0.predefinedKey == keyToFind }
                    )
                    if let existing = try? context.fetch(descriptor).first {
                        existing.name = categoryData.name
                        existing.icon = categoryData.icon
                        existing.color = categoryData.color
                        existing.isHidden = categoryData.isHidden
                        existing.updatedAt = Date()
                        categoriesImported += 1
                        continue
                    }
                }
                
                let category = CustomCategory(
                    id: UUID(uuidString: categoryData.id) ?? UUID(),
                    name: categoryData.name,
                    icon: categoryData.icon,
                    color: categoryData.color,
                    isPredefined: isPredefined,
                    predefinedKey: predefinedKey
                )
                category.isHidden = categoryData.isHidden
                context.insert(category)
                categoriesImported += 1
            }
        }
        
        try context.save()
        
        var message = ""
        if recurringExpensesImported > 0 { message += "\(recurringExpensesImported) recurring expenses" }
        if expensesImported > 0 { message += message.isEmpty ? "\(expensesImported) expenses" : ", \(expensesImported) expenses" }
        if budgetsImported > 0 { message += message.isEmpty ? "\(budgetsImported) budgets" : ", \(budgetsImported) budgets" }
        if categoriesImported > 0 { message += message.isEmpty ? "\(categoriesImported) categories" : ", \(categoriesImported) categories" }
        
        if message.isEmpty {
            message = "No data found to import"
        }
        
        successMessage = "Imported: \(message)"
        showSuccess = true
    }
    
    // MARK: - CSV Parsing
    
    func parseCSVLine(_ line: String) -> [String] {
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
    
    func parseExpenseCSVRow(_ values: [String], headers: [String]) -> ExportData.ExpenseData? {
        guard values.count == headers.count else { return nil }
        
        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        
        let dateStr = dict["date"] ?? ""
        let timeStr = dict["time"] ?? ""
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let date = isoFormatter.date(from: dateStr) ?? dateFormatter.date(from: dateStr) ?? Date()
        let time = timeStr.isEmpty ? nil : (isoFormatter.date(from: timeStr) ?? dateFormatter.date(from: timeStr))
        
        return ExportData.ExpenseData(
            id: dict["id"] ?? UUID().uuidString,
            type: dict["type"] ?? "expense",
            amount: Double(dict["amount"] ?? "0") ?? 0,
            category: dict["category"] ?? "Other",
            date: date,
            time: time,
            transactionDescription: dict["description"]?.isEmpty == false ? dict["description"] : nil,
            notes: dict["notes"]?.isEmpty == false ? dict["notes"] : nil,
            recurringExpenseId: dict["recurring expense id"]?.isEmpty == false ? dict["recurring expense id"] : nil,
            groupTransactionId: dict["group transaction id"]?.isEmpty == false ? dict["group transaction id"] : nil
        )
    }
    
    func parseBudgetCSVRow(_ values: [String], headers: [String]) -> ExportData.MonthlyBudgetData? {
        guard values.count == headers.count else { return nil }
        
        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        
        return ExportData.MonthlyBudgetData(
            id: dict["id"] ?? UUID().uuidString,
            year: Int(dict["year"] ?? "2026") ?? 2026,
            month: Int(dict["month"] ?? "1") ?? 1,
            limit: Double(dict["limit"] ?? "0") ?? 0
        )
    }
    
    func parseCategoryCSVRow(_ values: [String], headers: [String]) -> ExportData.CustomCategoryData? {
        guard values.count == headers.count else { return nil }
        
        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        
        return ExportData.CustomCategoryData(
            id: dict["id"] ?? UUID().uuidString,
            name: dict["name"] ?? "Custom",
            icon: dict["icon"] ?? "folder.fill",
            color: dict["color"] ?? "#808080",
            isHidden: dict["is hidden"]?.lowercased() == "true",
            isPredefined: dict["is predefined"]?.lowercased() == "true",
            predefinedKey: dict["predefined key"]?.isEmpty == false ? dict["predefined key"] : nil
        )
    }
    
    // MARK: - Helpers
    
    func escapeCSV(_ string: String) -> String {
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
