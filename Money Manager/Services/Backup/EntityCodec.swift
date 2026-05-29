import Foundation

/// A codec that owns CSV and JSON round-trips for one backupable entity.
///
/// Conformers must satisfy both directions: `parseCSVRow(csvRow(m)) == m`
/// and `decodeJSON(encodeJSON([m])) == [m]`. Entities that cannot fully
/// round-trip should not be included in the backup.
///
/// All methods are `nonisolated` so codecs can be called from any context
/// (including Task.detached for off-main import/export).
protocol EntityCodec<Model> {
    associatedtype Model

    /// Section header written to and parsed from multi-entity CSV files (e.g. `"transactions"`).
    nonisolated var entityName: String { get }

    // MARK: CSV

    nonisolated var csvHeader: [String] { get }
    nonisolated func csvRow(_ model: Model) -> [String]
    nonisolated func parseCSVRow(_ values: [String]) throws -> Model

    // MARK: JSON

    nonisolated func encodeJSON(_ models: [Model]) throws -> Data
    nonisolated func decodeJSON(_ data: Data) throws -> [Model]
}

// MARK: - Errors

enum EntityCodecError: Error {
    case malformedRow(String)
    case missingField(String)
}
