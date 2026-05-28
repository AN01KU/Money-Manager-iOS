import SwiftUI

enum CategoryResolver {

    // MARK: - UUID-based lookup (primary)

    /// Builds an O(1) lookup dictionary keyed by Category UUID.
    static func makeLookup(from categories: [Category]) -> [UUID: Category] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    /// O(1) resolve by UUID using a pre-built lookup dictionary.
    static func resolve(_ id: UUID, lookup: [UUID: Category]) -> (icon: String, color: Color) {
        if let category = lookup[id] {
            return (category.icon, Color(hex: category.color))
        }
        if let predefined = predefinedLookupByKey[id.uuidString] {
            return (predefined.icon, Color(hex: predefined.paletteHex))
        }
        return (AppIcons.Category.other, .gray)
    }

    /// O(1) resolve returning name, icon, and color by UUID.
    static func resolveAll(_ id: UUID, lookup: [UUID: Category]) -> (name: String, icon: String, color: Color) {
        if let category = lookup[id] {
            return (category.name, category.icon, Color(hex: category.color))
        }
        return (AppIcons.Category.other, AppIcons.Category.other, .gray)
    }

    // MARK: - Key-based lookup (used in sync code and legacy search)

    /// Builds an O(1) lookup dictionary keyed by server key.
    static func makeLookupByKey(from categories: [Category]) -> [String: Category] {
        var dict = [String: Category](minimumCapacity: categories.count)
        for category in categories where category.isServerPredefined && !category.isHidden {
            dict[category.key] = category
        }
        for category in categories where !category.isServerPredefined && !category.isHidden {
            if !category.key.isEmpty {
                dict[category.key] = category
            }
        }
        return dict
    }

    /// Finds a Category row by server key. Used when resolving API responses to local UUIDs.
    static func findByKey(_ key: String, in categories: [Category]) -> Category? {
        categories.first { $0.key == key }
    }

    /// Returns the category name for a UUID. Convenience for display without a pre-built lookup.
    static func name(for id: UUID, in categories: [Category]) -> String {
        categories.first { $0.id == id }?.name ?? AppIcons.Category.other
    }

    // MARK: - Private

    private static let predefinedLookupByKey: [String: PredefinedCategory] = {
        Dictionary(uniqueKeysWithValues: PredefinedCategory.allCases.map { ($0.serverKey, $0) })
    }()
}
