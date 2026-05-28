import Foundation

/// EntityCodec for RecurringTransaction. CSV and JSON round-trips.
struct RecurringTransactionCodec: EntityCodec {
    typealias Model = RecurringTransaction

    nonisolated let entityName = "recurring transactions"

    nonisolated let csvHeader = [
        "ID", "Name", "Amount", "Category ID", "Frequency",
        "Day of Month", "Days of Week", "Start Date", "End Date",
        "Is Active", "Last Added Date", "Notes", "Type",
        "Created At", "Updated At"
    ]

    nonisolated func csvRow(_ model: RecurringTransaction) -> [String] {
        [
            model.id.uuidString,
            model.name,
            String(model.amount),
            model.categoryId.uuidString,
            model.frequency.rawValue,
            model.dayOfMonth.map { String($0) } ?? "",
            model.daysOfWeek.map { $0.map { String($0) }.joined(separator: ";") } ?? "",
            BackupService.iso8601.string(from: model.startDate),
            model.endDate.map { BackupService.iso8601.string(from: $0) } ?? "",
            String(model.isActive),
            model.lastAddedDate.map { BackupService.iso8601.string(from: $0) } ?? "",
            model.notes ?? "",
            model.type.rawValue,
            BackupService.iso8601.string(from: model.createdAt),
            BackupService.iso8601.string(from: model.updatedAt)
        ]
    }

    nonisolated func parseCSVRow(_ values: [String]) throws -> RecurringTransaction {
        guard values.count == csvHeader.count else {
            throw EntityCodecError.malformedRow("expected \(csvHeader.count) columns, got \(values.count)")
        }

        guard let id = UUID(uuidString: values[0]) else {
            throw EntityCodecError.missingField("id")
        }
        let name = values[1]
        let amount = Double(values[2]) ?? 0
        guard let categoryId = UUID(uuidString: values[3]) else {
            throw EntityCodecError.missingField("categoryId")
        }
        let frequency = RecurringFrequency(rawValue: values[4]) ?? .monthly
        let dayOfMonth: Int? = values[5].isEmpty ? nil : Int(values[5])
        let daysOfWeek: [Int]? = values[6].isEmpty ? nil : values[6].split(separator: ";").compactMap { Int($0) }
        guard let startDate = BackupService.parseDate(values[7]) else {
            throw EntityCodecError.missingField("startDate")
        }
        let endDate: Date? = values[8].isEmpty ? nil : BackupService.parseDate(values[8])
        let isActive = values[9] == "true"
        let lastAddedDate: Date? = values[10].isEmpty ? nil : BackupService.parseDate(values[10])
        let notes: String? = values[11].isEmpty ? nil : values[11]
        let type = TransactionKind(rawValue: values[12]) ?? .expense

        return RecurringTransaction(
            id: id,
            name: name,
            amount: amount,
            categoryId: categoryId,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            lastAddedDate: lastAddedDate,
            notes: notes,
            type: type
        )
    }

    // MARK: - JSON

    nonisolated func encodeJSON(_ models: [RecurringTransaction]) throws -> Data {
        let records = models.map { RecurringTransactionRecord($0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(records)
    }

    nonisolated func decodeJSON(_ data: Data) throws -> [RecurringTransaction] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([RecurringTransactionRecord].self, from: data)
        return records.map { $0.toRecurringTransaction() }
    }
}

// MARK: - RecurringTransactionRecord

private struct RecurringTransactionRecord: Codable {
    let id: UUID
    let name: String
    let amount: Double
    let categoryId: UUID
    let frequency: String
    let dayOfMonth: Int?
    let daysOfWeek: [Int]?
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let lastAddedDate: Date?
    let notes: String?
    let type: String
    let createdAt: Date
    let updatedAt: Date

    nonisolated init(_ model: RecurringTransaction) {
        id = model.id
        name = model.name
        amount = model.amount
        categoryId = model.categoryId
        frequency = model.frequency.rawValue
        dayOfMonth = model.dayOfMonth
        daysOfWeek = model.daysOfWeek
        startDate = model.startDate
        endDate = model.endDate
        isActive = model.isActive
        lastAddedDate = model.lastAddedDate
        notes = model.notes
        type = model.type.rawValue
        createdAt = model.createdAt
        updatedAt = model.updatedAt
    }

    nonisolated func toRecurringTransaction() -> RecurringTransaction {
        RecurringTransaction(
            id: id,
            name: name,
            amount: amount,
            categoryId: categoryId,
            frequency: RecurringFrequency(rawValue: frequency) ?? .monthly,
            dayOfMonth: dayOfMonth,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            lastAddedDate: lastAddedDate,
            notes: notes,
            type: TransactionKind(rawValue: type) ?? .expense
        )
    }
}
