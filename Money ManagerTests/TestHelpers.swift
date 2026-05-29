import SwiftData
@testable import Money_Manager

/// Returns an in-memory ModelContainer with the full app schema.
/// Use this in every test that needs a ModelContext — do NOT construct
/// partial schemas, as SwiftData requires all related models to be
/// registered together or the container will fail to load.
func makeTestContainer() throws -> ModelContainer {
    let schema = Schema(SchemaV3.models)
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: config)
}

/// Returns a FetchDescriptor for ChangeRecord filtered by statusRaw string.
/// Use this in tests instead of inline #Predicate { $0.statusRaw == ChangeStatus.x.rawValue }
/// because the #Predicate macro rejects enum member access even on String properties.
func makeDescriptor(statusRaw: String) -> FetchDescriptor<ChangeRecord> {
    FetchDescriptor<ChangeRecord>(predicate: #Predicate { $0.statusRaw == statusRaw })
}
