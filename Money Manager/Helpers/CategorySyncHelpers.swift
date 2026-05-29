import Foundation

/// Non-actor-isolated category sync utilities. Operates only on keys/UUIDs,
/// never on Color — safe to call from nonisolated or background contexts.
enum CategorySyncHelpers {

    /// Builds a key→UUID lookup for sync use. Returns a fallback otherUUID for unresolvable keys.
    static func makeKeyToUUID(from categories: [Category]) -> (keyToUUID: [String: UUID], otherUUID: UUID?) {
        var dict = [String: UUID](minimumCapacity: categories.count)
        for cat in categories where !cat.key.isEmpty {
            dict[cat.key] = cat.id
        }
        let otherUUID = categories.first(where: { $0.key == PredefinedCategory.other.serverKey })?.id
        return (dict, otherUUID)
    }

    /// Resolves a category server key to a local UUID. Falls back to `otherUUID` when not found.
    static func resolveKey(_ key: String, keyToUUID: [String: UUID], otherUUID: UUID) -> UUID {
        keyToUUID[key] ?? otherUUID
    }

    /// Returns the server key for a UUID using a pre-built `Category` list.
    static func serverKey(for id: UUID, in categories: [Category]) -> String {
        categories.first(where: { $0.id == id })?.key
            ?? PredefinedCategory.other.serverKey
    }
}
