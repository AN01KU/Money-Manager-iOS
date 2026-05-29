import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportResult {
    let message: String
}

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
    case categories = "Categories"
    case all = "All Data"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .transactions: return "creditcard.fill"
        case .recurring: return "arrow.clockwise.circle.fill"
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
    var categories: [CategoryData]?

    struct TransactionData: Codable {
        let id: String
        let type: String
        let amount: Double
        let categoryId: UUID?
        let date: Date
        let time: Date?
        let transactionDescription: String?
        let notes: String?
        let recurringExpenseId: String?
        let groupTransactionId: String?

        init(id: String, type: String = "transaction", amount: Double, categoryId: UUID?, date: Date, time: Date?, transactionDescription: String?, notes: String?, recurringExpenseId: String?, groupTransactionId: String?) {
            self.id = id
            self.type = type
            self.amount = amount
            self.categoryId = categoryId
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
        let categoryId: UUID?
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

        init(id: String, name: String, amount: Double, categoryId: UUID?, frequency: String, dayOfMonth: Int?, daysOfWeek: [Int]?, startDate: Date, endDate: Date?, isActive: Bool, lastAddedDate: Date?, notes: String?, createdAt: Date, updatedAt: Date, type: String = "expense") {
            self.id = id; self.name = name; self.amount = amount; self.categoryId = categoryId
            self.frequency = frequency; self.dayOfMonth = dayOfMonth; self.daysOfWeek = daysOfWeek
            self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
            self.lastAddedDate = lastAddedDate; self.notes = notes
            self.createdAt = createdAt; self.updatedAt = updatedAt; self.type = type
        }
    }

    struct CategoryData: Codable {
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

    private var transactionCodec = TransactionCodec()
    private var recurringCodec = RecurringTransactionCodec()
    private var categoryCodec = CategoryCodec()

    var exportDescription: String {
        switch selectedExportFormat {
        case .csv:
            return "CSV is ideal for spreadsheets and data analysis. Each data type exports to a separate file."
        case .json:
            switch selectedDataType {
            case .all:
                return "JSON backup includes all your data. Use this for complete backup and restore."
            case .transactions, .recurring, .categories:
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
        categories: [Category],
        groups: [SplitGroupModel] = []
    ) async {
        isExporting = true
        defer { isExporting = false }

        // Predefined categories are server-seeded and excluded from backups (issue #119).
        let categories = categories.filter { !$0.isPredefined }

        do {
            let url: URL
            let stamp = exportDateStamp()

            switch selectedDataType {
            case .transactions:
                let active = transactions.filter { !$0.isSoftDeleted }
                switch selectedExportFormat {
                case .csv:
                    url = try BackupService.saveCSV(
                        BackupService.csvSection(transactionCodec, models: active),
                        filename: "transactions_\(stamp)"
                    )
                case .json:
                    let jsonData = try transactionCodec.encodeJSON(active)
                    let tmpURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("transactions_\(stamp).json")
                    try jsonData.write(to: tmpURL)
                    url = tmpURL
                }
            case .recurring:
                switch selectedExportFormat {
                case .csv:
                    url = try BackupService.saveCSV(
                        BackupService.csvSection(recurringCodec, models: recurringTransactions),
                        filename: "recurring_transactions_\(stamp)"
                    )
                case .json:
                    let jsonData = try recurringCodec.encodeJSON(recurringTransactions)
                    let tmpURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("recurring_transactions_\(stamp).json")
                    try jsonData.write(to: tmpURL)
                    url = tmpURL
                }
            case .categories:
                switch selectedExportFormat {
                case .csv:
                    url = try BackupService.saveCSV(
                        BackupService.csvSection(categoryCodec, models: categories),
                        filename: "categories_\(stamp)"
                    )
                case .json:
                    let jsonData = try categoryCodec.encodeJSON(categories)
                    let tmpURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("categories_\(stamp).json")
                    try jsonData.write(to: tmpURL)
                    url = tmpURL
                }
            case .all:
                let active = transactions.filter { !$0.isSoftDeleted }
                switch selectedExportFormat {
                case .csv:
                    let csv = BackupService.csvSection(transactionCodec, models: active)
                        + BackupService.csvSection(recurringCodec, models: recurringTransactions)
                        + BackupService.csvSection(categoryCodec, models: categories)
                    url = try BackupService.saveCSV(csv, filename: "money_manager_backup_\(stamp)")
                case .json:
                    let dict: [String: Data] = [
                        transactionCodec.entityName: try transactionCodec.encodeJSON(active),
                        recurringCodec.entityName: try recurringCodec.encodeJSON(recurringTransactions),
                        categoryCodec.entityName: try categoryCodec.encodeJSON(categories)
                    ]
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    // Encode each section as raw JSON by re-serializing
                    var jsonObj: [String: Any] = [:]
                    for (key, data) in dict {
                        jsonObj[key] = try JSONSerialization.jsonObject(with: data)
                    }
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted, .sortedKeys])
                    let tmpURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("money_manager_backup_\(stamp).json")
                    try jsonData.write(to: tmpURL)
                    url = tmpURL
                }
            }

            exportedFileURL = url
            showShareSheet = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func exportDateStamp() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd_HHmmss"
        return fmt.string(from: Date())
    }

    func importData(from url: URL, context: ModelContext) async {
        isImporting = true
        defer { isImporting = false }

        do {
            let result: ImportResult

            switch selectedImportFormat {
            case .json:
                result = try importJSON(from: url, context: context)
            case .csv:
                result = try importCSV(from: url, context: context)
            }

            successMessage = result.message
            showSuccess = true
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Import

    private func importJSON(from url: URL, context: ModelContext) throws -> ImportResult {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: data)
        return try processImportedData(exportData, context: context)
    }

    private func importCSV(from url: URL, context: ModelContext) throws -> ImportResult {
        let content = try String(contentsOf: url, encoding: .utf8)

        if content.contains("# TRANSACTIONS") || content.contains("# CATEGORIES") {
            return try importSectionBasedCSV(content: content, context: context)
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return ImportResult(message: "No data found to import") }

        let headers = parseCSVLine(lines[0])
        var transactions: [ExportData.TransactionData] = []
        var categories: [ExportData.CategoryData] = []
        let lowercaseHeaders = headers.map { $0.lowercased() }
        let firstHeader = lowercaseHeaders.first ?? ""

        if firstHeader == "id" && lowercaseHeaders.contains("amount") && lowercaseHeaders.contains("category") {
            for i in 1..<lines.count {
                if let tx = parseTransactionCSVRow(parseCSVLine(lines[i]), headers: lowercaseHeaders) {
                    transactions.append(tx)
                }
            }
        } else if firstHeader == "id" && lowercaseHeaders.contains("name") && lowercaseHeaders.contains("icon") {
            for i in 1..<lines.count {
                if let c = parseCategoryCSVRow(parseCSVLine(lines[i]), headers: lowercaseHeaders) {
                    categories.append(c)
                }
            }
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: transactions.isEmpty ? nil : transactions,
            categories: categories.isEmpty ? nil : categories
        )
        return try processImportedData(exportData, context: context)
    }

    private func importSectionBasedCSV(content: String, context: ModelContext) throws -> ImportResult {
        var transactions: [ExportData.TransactionData] = []
        var categories: [ExportData.CategoryData] = []

        for section in content.components(separatedBy: "\n# ") {
            let lines = section.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { continue }

            let sectionHeader = lines[0]
            let headers = parseCSVLine(lines[1]).map { $0.lowercased() }

            if sectionHeader.contains("TRANSACTIONS") {
                for i in 2..<lines.count {
                    if let tx = parseTransactionCSVRow(parseCSVLine(lines[i]), headers: headers) {
                        transactions.append(tx)
                    }
                }
            } else if sectionHeader.contains("CATEGORIES") {
                for i in 2..<lines.count {
                    if let c = parseCategoryCSVRow(parseCSVLine(lines[i]), headers: headers) {
                        categories.append(c)
                    }
                }
            }
        }

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: transactions.isEmpty ? nil : transactions,
            categories: categories.isEmpty ? nil : categories
        )
        return try processImportedData(exportData, context: context)
    }

    private func processImportedData(_ exportData: ExportData, context: ModelContext) throws -> ImportResult {
        var transactionsImported = 0
        var recurringImported = 0
        var categoriesImported = 0
        var recurringIdMap: [String: UUID] = [:]

        if let recurringTransactions = exportData.recurringTransactions {
            for recurringData in recurringTransactions {
                let recurringTransaction = RecurringTransaction(
                    id: UUID(uuidString: recurringData.id) ?? UUID(),
                    name: recurringData.name,
                    amount: recurringData.amount,
                    categoryId: recurringData.categoryId ?? UUID(),
                    frequency: RecurringFrequency(rawValue: recurringData.frequency) ?? .monthly,
                    dayOfMonth: recurringData.dayOfMonth,
                    daysOfWeek: recurringData.daysOfWeek,
                    startDate: recurringData.startDate,
                    endDate: recurringData.endDate,
                    isActive: recurringData.isActive,
                    lastAddedDate: recurringData.lastAddedDate,
                    notes: recurringData.notes,
                    type: TransactionKind(rawValue: recurringData.type) ?? .expense
                )
                context.insert(recurringTransaction)
                recurringImported += 1
                recurringIdMap[recurringData.id] = recurringTransaction.id
            }
        }

        if let transactions = exportData.transactions {
            for transactionData in transactions {
                let recurringExpenseId: UUID?
                if let recIdString = transactionData.recurringExpenseId,
                   let recId = recurringIdMap[recIdString] {
                    recurringExpenseId = recId
                } else {
                    recurringExpenseId = nil
                }

                let transaction = Transaction(
                    id: UUID(uuidString: transactionData.id) ?? UUID(),
                    type: TransactionKind(rawValue: transactionData.type) ?? .expense,
                    amount: transactionData.amount,
                    categoryId: transactionData.categoryId ?? UUID(),
                    date: transactionData.date,
                    time: transactionData.time,
                    transactionDescription: transactionData.transactionDescription,
                    notes: transactionData.notes,
                    recurringExpenseId: recurringExpenseId,
                    groupTransactionId: transactionData.groupTransactionId.flatMap { UUID(uuidString: $0) }
                )
                context.insert(transaction)
                transactionsImported += 1
            }
        }

        if let categories = exportData.categories {
            for categoryData in categories {
                let isPredefined = categoryData.isPredefined ?? false
                let predefinedKey = categoryData.predefinedKey

                if isPredefined, let key = predefinedKey {
                    let descriptor = FetchDescriptor<Category>(
                        predicate: #Predicate { $0.predefinedKey == key }
                    )
                    if let existing = try? context.fetch(descriptor).first {
                        existing.name = categoryData.name
                        existing.icon = categoryData.icon
                        existing.color = categoryData.color
                        existing.isHidden = categoryData.isHidden
                        existing.updatedAt = Date()
                        continue
                    }
                }

                let category = Category(
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

        var parts: [String] = []
        if recurringImported > 0 { parts.append("\(recurringImported) recurring transactions") }
        if transactionsImported > 0 { parts.append("\(transactionsImported) transactions") }
        if categoriesImported > 0 { parts.append("\(categoriesImported) categories") }

        let message = parts.isEmpty ? "No data found to import" : parts.joined(separator: ", ")
        return ImportResult(message: "Imported: \(message)")
    }

    // MARK: - CSV Parsing Helpers

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

    func parseTransactionCSVRow(_ values: [String], headers: [String]) -> ExportData.TransactionData? {
        guard values.count == headers.count else { return nil }

        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = dict["date"] ?? ""
        let timeStr = dict["time"] ?? ""
        let date = isoFormatter.date(from: dateStr) ?? Date()
        let time = timeStr.isEmpty ? nil : isoFormatter.date(from: timeStr)

        let categoryIdStr = dict["category id"] ?? ""
        return ExportData.TransactionData(
            id: dict["id"] ?? UUID().uuidString,
            type: dict["type"] ?? "transaction",
            amount: Double(dict["amount"] ?? "0") ?? 0,
            categoryId: UUID(uuidString: categoryIdStr),
            date: date,
            time: time,
            transactionDescription: nonEmpty(dict["description"]),
            notes: nonEmpty(dict["notes"]),
            recurringExpenseId: nonEmpty(dict["recurring expense id"]),
            groupTransactionId: nonEmpty(dict["group transaction id"])
        )
    }

    func parseCategoryCSVRow(_ values: [String], headers: [String]) -> ExportData.CategoryData? {
        guard values.count == headers.count else { return nil }
        let dict = Dictionary(uniqueKeysWithValues: zip(headers, values))
        return ExportData.CategoryData(
            id: dict["id"] ?? UUID().uuidString,
            name: dict["name"] ?? "Custom",
            icon: dict["icon"] ?? "folder.fill",
            color: dict["color"] ?? "#808080",
            isHidden: dict["is hidden"]?.lowercased() == "true",
            isPredefined: dict["is predefined"]?.lowercased() == "true",
            predefinedKey: nonEmpty(dict["predefined key"])
        )
    }

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
            parsedDate = isoFormatter.date(from: dateStr)
            if parsedDate == nil {
                for format in dateFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateStr) {
                        parsedDate = date
                        break
                    }
                }
            }
        }

        if let timeStr = timeStr, !timeStr.isEmpty {
            parsedTime = isoFormatter.date(from: timeStr)
            if parsedTime == nil {
                for format in dateFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let time = formatter.date(from: timeStr) {
                        parsedTime = time
                        break
                    }
                }
            }
        }

        return (parsedDate ?? Date(), parsedTime)
    }

    private func nonEmpty(_ value: String?) -> String? {
        value?.isEmpty == false ? value : nil
    }
}
