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
    /// Call once per data update and pass the result to `resolve(_:lookup:)`.
    static func makeLookup(from customCategories: [CustomCategory]) -> [String: CustomCategory] {
        var dict = [String: CustomCategory](minimumCapacity: customCategories.count)
        for category in customCategories where !category.isHidden {
            let key = category.key.isEmpty ? "local:\(category.id.uuidString)" : category.key
            dict[key] = category
        }
        return dict
    }

    // MARK: - Resolve

    /// O(1) resolve by server key using a pre-built lookup dictionary.
    static func resolve(_ categoryKey: String, lookup: [String: CustomCategory]) -> (icon: String, color: Color) {
        if let custom = lookup[categoryKey] {
            return (custom.icon, Color(hex: custom.color))
        }
        if let predefined = predefinedLookup[categoryKey] {
            return (predefined.icon, predefined.color)
        }
        return (AppIcons.Category.other, .gray)
    }

    /// O(1) resolve returning name, icon, and color.
    static func resolveAll(_ categoryKey: String, lookup: [String: CustomCategory]) -> (name: String, icon: String, color: Color) {
        if let custom = lookup[categoryKey] {
            return (custom.name, custom.icon, Color(hex: custom.color))
        }
        if let predefined = predefinedLookup[categoryKey] {
            return (predefined.rawValue, predefined.icon, predefined.color)
        }
        return (categoryKey, AppIcons.Category.other, .gray)
    }

    /// Convenience O(n) resolve — builds a temporary lookup on each call.
    /// Prefer `makeLookup(from:)` + `resolve(_:lookup:)` in hot paths.
    static func resolve(_ categoryKey: String, customCategories: [CustomCategory]) -> (icon: String, color: Color) {
        let lookup = makeLookup(from: customCategories)
        return resolve(categoryKey, lookup: lookup)
    }
}
