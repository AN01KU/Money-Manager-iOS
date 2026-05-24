//
//  CategoryResolver.swift
//  Money Manager
//

import SwiftUI

enum CategoryResolver {
    /// Built once in O(n); subsequent lookups are O(1). serverKey → PredefinedCategory.
    private static let predefinedLookup: [String: PredefinedCategory] = {
        Dictionary(uniqueKeysWithValues: PredefinedCategory.allCases.map { ($0.serverKey, $0) })
    }()

    // MARK: - Lookup helpers

    /// Builds an O(1) lookup dictionary keyed by server key (or local fallback key).
    /// Accepts the full flat category list — server-predefined, user overrides, and custom rows.
    /// User override rows take priority over server-predefined rows for the same key.
    static func makeLookup(from customCategories: [Category]) -> [String: Category] {
        var dict = [String: Category](minimumCapacity: customCategories.count)
        // Insert server-predefined rows first so user overrides can overwrite them below.
        for category in customCategories where category.isServerPredefined && !category.isHidden {
            dict[category.key] = category
        }
        for category in customCategories where !category.isServerPredefined && !category.isHidden {
            let key = category.key.isEmpty ? "local:\(category.id.uuidString)" : category.key
            dict[key] = category
        }
        return dict
    }

    // MARK: - Resolve

    /// O(1) resolve by server key using a pre-built lookup dictionary.
    static func resolve(_ categoryKey: String, lookup: [String: Category]) -> (icon: String, color: Color) {
        if let custom = lookup[categoryKey] {
            return (custom.icon, Color(hex: custom.color))
        }
        if let predefined = predefinedLookup[categoryKey] {
            return (predefined.icon, Color(hex: predefined.paletteHex))
        }
        return (AppIcons.Category.other, .gray)
    }

    /// O(1) resolve returning name, icon, and color.
    static func resolveAll(_ categoryKey: String, lookup: [String: Category]) -> (name: String, icon: String, color: Color) {
        if let custom = lookup[categoryKey] {
            return (custom.name, custom.icon, Color(hex: custom.color))
        }
        if let predefined = predefinedLookup[categoryKey] {
            return (predefined.rawValue, predefined.icon, Color(hex: predefined.paletteHex))
        }
        return (categoryKey, AppIcons.Category.other, .gray)
    }

    /// Convenience O(n) resolve — builds a temporary lookup on each call.
    /// Prefer `makeLookup(from:)` + `resolve(_:lookup:)` in hot paths.
    static func resolve(_ categoryKey: String, customCategories: [Category]) -> (icon: String, color: Color) {
        let lookup = makeLookup(from: customCategories)
        return resolve(categoryKey, lookup: lookup)
    }
}
