import Foundation
import SwiftData

struct ImportResult {
    let message: String
}

@MainActor
struct ImportService {

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

    // MARK: - Public API

    func importJSON(from url: URL, context: ModelContext) throws -> ImportResult {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: data)
        return try processImportedData(exportData, context: context)
    }

    func importCSV(from url: URL, context: ModelContext) throws -> ImportResult {
        let content = try String(contentsOf: url, encoding: .utf8)

        if content.contains("# TRANSACTIONS") || content.contains("# BUDGETS") || content.contains("# CATEGORIES") {
            return try importSectionBasedCSV(content: content, context: context)
        }

        // Legacy single-section format
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count > 1 else { return ImportResult(message: "No data found to import") }

        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine)

        var transactions: [ExportData.TransactionData] = []
        var budgets: [ExportData.MonthlyBudgetData] = []
        var categories: [ExportData.CustomCategoryData] = []

        let lowercaseHeaders = headers.map { $0.lowercased() }
        let firstHeader = lowercaseHeaders.first ?? ""

        if firstHeader == "id" && lowercaseHeaders.contains("amount") && lowercaseHeaders.contains("category") {
            for i in 1..<lines.count {
                let values = parseCSVLine(lines[i])
                if let transaction = parseTransactionCSVRow(values, headers: lowercaseHeaders) {
                    transactions.append(transaction)
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
            transactions: transactions.isEmpty ? nil : transactions,
            budgets: budgets.isEmpty ? nil : budgets,
            categories: categories.isEmpty ? nil : categories
        )

        return try processImportedData(exportData, context: context)
    }

    // MARK: - Section-Based CSV

    private func importSectionBasedCSV(content: String, context: ModelContext) throws -> ImportResult {
        var transactions: [ExportData.TransactionData] = []
        var budgets: [ExportData.MonthlyBudgetData] = []
        var categories: [ExportData.CustomCategoryData] = []

        let sections = content.components(separatedBy: "\n# ")

        for section in sections {
            let lines = section.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { continue }

            let sectionHeader = lines[0]
            let headers = parseCSVLine(lines[1]).map { $0.lowercased() }

            if sectionHeader.contains("TRANSACTIONS") {
                for i in 2..<lines.count {
                    let values = parseCSVLine(lines[i])
                    if let transaction = parseTransactionCSVRow(values, headers: headers) {
                        transactions.append(transaction)
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
            transactions: transactions.isEmpty ? nil : transactions,
            budgets: budgets.isEmpty ? nil : budgets,
            categories: categories.isEmpty ? nil : categories
        )

        return try processImportedData(exportData, context: context)
    }

    // MARK: - Process Imported Data

    private func processImportedData(_ exportData: ExportData, context: ModelContext) throws -> ImportResult {
        var transactionsImported = 0
        var recurringImported = 0
        var budgetsImported = 0
        var categoriesImported = 0

        var recurringIdMap: [String: UUID] = [:]

        if let recurringTransactions = exportData.recurringTransactions {
            for recurringData in recurringTransactions {
                let recurringTransaction = RecurringTransaction(
                    id: UUID(uuidString: recurringData.id) ?? UUID(),
                    name: recurringData.name,
                    amount: recurringData.amount,
                    category: recurringData.category,
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
                    category: transactionData.category,
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
        if recurringImported > 0 { message += "\(recurringImported) recurring transactions" }
        if transactionsImported > 0 { message += message.isEmpty ? "\(transactionsImported) transactions" : ", \(transactionsImported) transactions" }
        if budgetsImported > 0 { message += message.isEmpty ? "\(budgetsImported) budgets" : ", \(budgetsImported) budgets" }
        if categoriesImported > 0 { message += message.isEmpty ? "\(categoriesImported) categories" : ", \(categoriesImported) categories" }

        if message.isEmpty {
            message = "No data found to import"
        }

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

        let dateStr = dict["date"] ?? ""
        let timeStr = dict["time"] ?? ""

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let date = isoFormatter.date(from: dateStr) ?? dateFormatter.date(from: dateStr) ?? Date()
        let time = timeStr.isEmpty ? nil : (isoFormatter.date(from: timeStr) ?? dateFormatter.date(from: timeStr))

        return ExportData.TransactionData(
            id: dict["id"] ?? UUID().uuidString,
            type: dict["type"] ?? "transaction",
            amount: Double(dict["amount"] ?? "0") ?? 0,
            category: dict["category"] ?? "Other",
            date: date,
            time: time,
            transactionDescription: nonEmpty(dict["description"]),
            notes: nonEmpty(dict["notes"]),
            recurringExpenseId: nonEmpty(dict["recurring expense id"]),
            groupTransactionId: nonEmpty(dict["group transaction id"])
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
            predefinedKey: nonEmpty(dict["predefined key"])
        )
    }

    // MARK: - Helpers

    private func nonEmpty(_ value: String?) -> String? {
        value?.isEmpty == false ? value : nil
    }

    // MARK: - Date Parsing

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
}
