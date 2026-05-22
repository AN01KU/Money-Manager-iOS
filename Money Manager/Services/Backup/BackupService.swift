import Foundation

// MARK: - BackupImportResult

struct BackupImportResult {
    let entitiesImported: [String: Int]

    nonisolated var summary: String {
        entitiesImported
            .filter { $0.value > 0 }
            .map { "\($0.value) \($0.key)" }
            .joined(separator: ", ")
    }
}

// MARK: - BackupService

/// Drives export and import through a registry of EntityCodecs.
///
/// CSV files use section-based format: each entity occupies a `# entityName` section.
/// JSON files use a top-level dictionary keyed by entityName.
///
/// Legacy single-section CSV files (pre-BackupService format) are wrapped into
/// a synthetic `# transactions` section before parsing. Deprecate this shim after one release.
struct BackupService {

    // One shared formatter — per-row instantiation deleted.
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    // Fallback formatters for reading older backup files.
    static let legacyDateFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "MMM d, yyyy 'at' h:mm a",
            "MMM d, yyyy",
        ]
        return formats.map { fmt in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = fmt
            return f
        }
    }()

    // MARK: - CSV

    /// Build one CSV section string for a concrete codec + typed array.
    ///
    /// This is the primary building block callers use to assemble a multi-entity
    /// CSV file: concatenate sections, then pass to `saveCSV(_:filename:)`.
    nonisolated static func csvSection<C: EntityCodec>(_ codec: C, models: [C.Model]) -> String {
        var s = "# \(codec.entityName)\n"
        s += codec.csvHeader.joined(separator: ",") + "\n"
        for model in models {
            s += escapeCSVRow(codec.csvRow(model)) + "\n"
        }
        return s
    }

    /// Write a CSV string to a temp file and return its URL.
    nonisolated static func saveCSV(_ content: String, filename: String) throws -> URL {
        try saveToTemp(content: content, filename: filename, ext: "csv")
    }

    // MARK: - JSON

    nonisolated static func saveJSON(_ object: some Encodable, filename: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(object)
        let url = tempURL(filename: filename, ext: "json")
        try data.write(to: url)
        return url
    }

    // MARK: - Import

    /// Parse a section-based CSV file. Returns rows per entityName.
    ///
    /// Single-section legacy files (no `# ` header) are wrapped in a synthetic
    /// `# transactions` section before parsing.
    nonisolated static func importCSV(from url: URL) throws -> [String: [[String]]] {
        let content = try String(contentsOf: url, encoding: .utf8)
        return parseCSVSections(content)
    }

    // MARK: - CSV Parsing

    /// Split section-based CSV content into `[entityName: [[fieldValues]]]`.
    nonisolated static func parseCSVSections(_ content: String) -> [String: [[String]]] {
        var result: [String: [[String]]] = [:]

        // Detect legacy single-section: no `# ` markers at line start.
        let wrapped: String
        if !content.contains("\n# ") && !content.hasPrefix("# ") {
            wrapped = "# transactions\n" + content
        } else {
            wrapped = content
        }

        let rawSections = wrapped.components(separatedBy: "\n# ")

        for (index, section) in rawSections.enumerated() {
            var lines = section.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard !lines.isEmpty else { continue }

            // The first segment still has its leading `# ` because split strips the delimiter.
            var entityLine = lines[0]
            if index == 0 && entityLine.hasPrefix("# ") {
                entityLine = String(entityLine.dropFirst(2))
            }
            let entityName = entityLine.trimmingCharacters(in: .whitespaces).lowercased()
            lines.removeFirst()

            guard !lines.isEmpty else { continue }
            lines.removeFirst() // strip header row

            let rows = lines.compactMap { line -> [String]? in
                let fields = parseCSVLine(line)
                return fields.isEmpty ? nil : fields
            }
            result[entityName] = rows
        }
        return result
    }

    /// RFC 4180-compliant CSV line parser.
    nonisolated static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex

        while i < line.endIndex {
            let ch = line[i]
            if inQuotes {
                if ch == "\"" {
                    let next = line.index(after: i)
                    if next < line.endIndex && line[next] == "\"" {
                        current.append("\"")
                        i = line.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            i = line.index(after: i)
        }
        fields.append(current)
        return fields
    }

    // MARK: - Date Parsing

    nonisolated static func parseDate(_ string: String) -> Date? {
        if let date = iso8601.date(from: string) { return date }
        for formatter in legacyDateFormatters {
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }

    // MARK: - CSV Escaping

    nonisolated static func escapeCSVField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    nonisolated static func escapeCSVRow(_ fields: [String]) -> String {
        fields.map { escapeCSVField($0) }.joined(separator: ",")
    }

    // MARK: - File Helpers

    private nonisolated static func tempURL(filename: String, ext: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(filename).\(ext)")
    }

    private nonisolated static func saveToTemp(content: String, filename: String, ext: String) throws -> URL {
        let url = tempURL(filename: filename, ext: ext)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
