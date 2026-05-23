import Foundation

/// EntityCodec for MonthlyBudget. CSV and JSON round-trips.
struct BudgetCodec: EntityCodec {
    typealias Model = MonthlyBudget

    nonisolated let entityName = "budgets"

    nonisolated let csvHeader = ["ID", "Year", "Month", "Limit"]

    nonisolated func csvRow(_ model: MonthlyBudget) -> [String] {
        [
            model.id.uuidString,
            String(model.year),
            String(model.month),
            String(model.limit)
        ]
    }

    nonisolated func parseCSVRow(_ values: [String]) throws -> MonthlyBudget {
        guard values.count == csvHeader.count else {
            throw EntityCodecError.malformedRow("expected \(csvHeader.count) columns, got \(values.count)")
        }
        guard let id = UUID(uuidString: values[0]) else {
            throw EntityCodecError.missingField("id")
        }
        guard let year = Int(values[1]) else {
            throw EntityCodecError.missingField("year")
        }
        guard let month = Int(values[2]) else {
            throw EntityCodecError.missingField("month")
        }
        guard let limit = Double(values[3]) else {
            throw EntityCodecError.missingField("limit")
        }
        return MonthlyBudget(id: id, year: year, month: month, limit: limit)
    }

    // MARK: - JSON

    nonisolated func encodeJSON(_ models: [MonthlyBudget]) throws -> Data {
        let records = models.map { BudgetRecord($0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(records)
    }

    nonisolated func decodeJSON(_ data: Data) throws -> [MonthlyBudget] {
        let decoder = JSONDecoder()
        let records = try decoder.decode([BudgetRecord].self, from: data)
        return records.map { $0.toMonthlyBudget() }
    }
}

// MARK: - BudgetRecord

private struct BudgetRecord: Codable {
    let id: UUID
    let year: Int
    let month: Int
    let limit: Double

    nonisolated init(_ b: MonthlyBudget) {
        id = b.id
        year = b.year
        month = b.month
        limit = b.limit
    }

    nonisolated func toMonthlyBudget() -> MonthlyBudget {
        MonthlyBudget(id: id, year: year, month: month, limit: limit)
    }
}
