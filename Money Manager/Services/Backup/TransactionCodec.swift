import Foundation

/// EntityCodec for Transaction. Reads groupName directly from the model field,
/// fixing the gname=nil bug that existed when lookups were done against a groups array.
struct TransactionCodec: EntityCodec {
    typealias Model = Transaction

    nonisolated let entityName = "transactions"

    nonisolated let csvHeader = [
        "ID", "Type", "Amount", "Category", "Date", "Time",
        "Description", "Notes", "Recurring Expense ID",
        "Group Transaction ID", "Group Name", "Group ID",
        "Settlement ID", "Category ID"
    ]

    nonisolated func csvRow(_ model: Transaction) -> [String] {
        [
            model.id.uuidString,
            model.type.rawValue,
            String(model.amount),
            model.category,
            BackupService.iso8601.string(from: model.date),
            model.time.map { BackupService.iso8601.string(from: $0) } ?? "",
            model.transactionDescription ?? "",
            model.notes ?? "",
            model.recurringExpenseId?.uuidString ?? "",
            model.groupTransactionId?.uuidString ?? "",
            model.groupName ?? "",
            model.groupId?.uuidString ?? "",
            model.settlementId?.uuidString ?? "",
            model.categoryId?.uuidString ?? ""
        ]
    }

    nonisolated func parseCSVRow(_ values: [String]) throws -> Transaction {
        guard values.count == csvHeader.count else {
            throw EntityCodecError.malformedRow("expected \(csvHeader.count) columns, got \(values.count)")
        }

        guard let id = UUID(uuidString: values[0]) else {
            throw EntityCodecError.missingField("id")
        }
        let type = TransactionKind(rawValue: values[1]) ?? .expense
        let amount = Double(values[2]) ?? 0
        let category = values[3]
        guard let date = BackupService.parseDate(values[4]) else {
            throw EntityCodecError.missingField("date")
        }
        let time: Date? = values[5].isEmpty ? nil : BackupService.parseDate(values[5])
        let description: String? = values[6].isEmpty ? nil : values[6]
        let notes: String? = values[7].isEmpty ? nil : values[7]
        let recurringExpenseId = UUID(uuidString: values[8])
        let groupTransactionId = UUID(uuidString: values[9])
        let groupName: String? = values[10].isEmpty ? nil : values[10]
        let groupId = UUID(uuidString: values[11])
        let settlementId = UUID(uuidString: values[12])
        let categoryId = UUID(uuidString: values[13])

        let tx = Transaction(
            id: id,
            type: type,
            amount: amount,
            category: category,
            date: date,
            time: time,
            transactionDescription: description,
            notes: notes,
            recurringExpenseId: recurringExpenseId,
            groupTransactionId: groupTransactionId,
            settlementId: settlementId,
            categoryId: categoryId
        )
        tx.groupName = groupName
        tx.groupId = groupId
        return tx
    }

    // MARK: - JSON

    nonisolated func encodeJSON(_ models: [Transaction]) throws -> Data {
        let records = models.map { TransactionRecord($0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(records)
    }

    nonisolated func decodeJSON(_ data: Data) throws -> [Transaction] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([TransactionRecord].self, from: data)
        return records.map { $0.toTransaction() }
    }
}

// MARK: - TransactionRecord

/// Codable snapshot of a Transaction for JSON backup.
private struct TransactionRecord: Codable {
    let id: UUID
    let type: String
    let amount: Double
    let category: String
    let date: Date
    let time: Date?
    let transactionDescription: String?
    let notes: String?
    let recurringExpenseId: UUID?
    let groupTransactionId: UUID?
    let groupName: String?
    let groupId: UUID?
    let settlementId: UUID?
    let categoryId: UUID?

    nonisolated init(_ tx: Transaction) {
        id = tx.id
        type = tx.type.rawValue
        amount = tx.amount
        category = tx.category
        date = tx.date
        time = tx.time
        transactionDescription = tx.transactionDescription
        notes = tx.notes
        recurringExpenseId = tx.recurringExpenseId
        groupTransactionId = tx.groupTransactionId
        groupName = tx.groupName
        groupId = tx.groupId
        settlementId = tx.settlementId
        categoryId = tx.categoryId
    }

    nonisolated func toTransaction() -> Transaction {
        let tx = Transaction(
            id: id,
            type: TransactionKind(rawValue: type) ?? .expense,
            amount: amount,
            category: category,
            date: date,
            time: time,
            transactionDescription: transactionDescription,
            notes: notes,
            recurringExpenseId: recurringExpenseId,
            groupTransactionId: groupTransactionId,
            settlementId: settlementId,
            categoryId: categoryId
        )
        tx.groupName = groupName
        tx.groupId = groupId
        return tx
    }
}
