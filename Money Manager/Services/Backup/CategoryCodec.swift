import Foundation

/// EntityCodec for Category. CSV and JSON round-trips.
struct CategoryCodec: EntityCodec {
    typealias Model = Category

    nonisolated let entityName = "categories"

    nonisolated let csvHeader = [
        "ID", "Key", "Name", "Icon", "Color",
        "Is Hidden", "Is Predefined", "Predefined Key",
        "Is Server Predefined", "Created At", "Updated At"
    ]

    nonisolated func csvRow(_ model: Category) -> [String] {
        [
            model.id.uuidString,
            model.key,
            model.name,
            model.icon,
            model.color,
            String(model.isHidden),
            String(model.isPredefined),
            model.predefinedKey ?? "",
            String(model.isServerPredefined),
            BackupService.iso8601.string(from: model.createdAt),
            BackupService.iso8601.string(from: model.updatedAt)
        ]
    }

    nonisolated func parseCSVRow(_ values: [String]) throws -> Category {
        guard values.count == csvHeader.count else {
            throw EntityCodecError.malformedRow("expected \(csvHeader.count) columns, got \(values.count)")
        }
        guard let id = UUID(uuidString: values[0]) else {
            throw EntityCodecError.missingField("id")
        }
        let key = values[1]
        let name = values[2]
        let icon = values[3]
        let color = values[4]
        let isHidden = values[5] == "true"
        let isPredefined = values[6] == "true"
        let predefinedKey: String? = values[7].isEmpty ? nil : values[7]
        let isServerPredefined = values[8] == "true"
        guard let createdAt = BackupService.parseDate(values[9]) else {
            throw EntityCodecError.missingField("createdAt")
        }
        guard let updatedAt = BackupService.parseDate(values[10]) else {
            throw EntityCodecError.missingField("updatedAt")
        }

        let cat = Category(
            id: id,
            key: key,
            name: name,
            icon: icon,
            color: color,
            isPredefined: isPredefined,
            predefinedKey: predefinedKey,
            isServerPredefined: isServerPredefined
        )
        cat.isHidden = isHidden
        cat.createdAt = createdAt
        cat.updatedAt = updatedAt
        return cat
    }

    // MARK: - JSON

    nonisolated func encodeJSON(_ models: [Category]) throws -> Data {
        let records = models.map { CategoryRecord($0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(records)
    }

    nonisolated func decodeJSON(_ data: Data) throws -> [Category] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let records = try decoder.decode([CategoryRecord].self, from: data)
        return records.map { $0.toCategory() }
    }
}

// MARK: - CategoryRecord

private struct CategoryRecord: Codable {
    let id: UUID
    let key: String
    let name: String
    let icon: String
    let color: String
    let isHidden: Bool
    let isPredefined: Bool
    let predefinedKey: String?
    let isServerPredefined: Bool
    let createdAt: Date
    let updatedAt: Date

    nonisolated init(_ c: Category) {
        id = c.id
        key = c.key
        name = c.name
        icon = c.icon
        color = c.color
        isHidden = c.isHidden
        isPredefined = c.isPredefined
        predefinedKey = c.predefinedKey
        isServerPredefined = c.isServerPredefined
        createdAt = c.createdAt
        updatedAt = c.updatedAt
    }

    nonisolated func toCategory() -> Category {
        let cat = Category(
            id: id,
            key: key,
            name: name,
            icon: icon,
            color: color,
            isPredefined: isPredefined,
            predefinedKey: predefinedKey,
            isServerPredefined: isServerPredefined
        )
        cat.isHidden = isHidden
        cat.createdAt = createdAt
        cat.updatedAt = updatedAt
        return cat
    }
}
