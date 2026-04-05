//
//  CategoryResolver.swift
//  Money Manager
//

import SwiftUI

enum CategoryResolver {
    /// O(n) predefined lookup built once at app start.
    private static let predefinedLookup: [String: PredefinedCategory] = {
        Dictionary(uniqueKeysWithValues: PredefinedCategory.allCases.map { ($0.rawValue, $0) })
    }()

    // MARK: - Lookup helpers

    /// Builds an O(1) lookup dictionary from a list of custom categories.
    /// Call once per data update and pass the result to `resolve(_:lookup:)`.
    static func makeLookup(from customCategories: [CustomCategory]) -> [String: CustomCategory] {
        var dict = [String: CustomCategory](minimumCapacity: customCategories.count)
        for category in customCategories where !category.isHidden {
            dict[category.name] = category
        }
        return dict
    }

    // MARK: - Resolve

    /// O(1) resolve using a pre-built lookup dictionary.
    static func resolve(_ categoryName: String, lookup: [String: CustomCategory]) -> (icon: String, color: Color) {
        if let custom = lookup[categoryName] {
            return (custom.icon, Color(hex: custom.color))
        }
        if let predefined = predefinedLookup[categoryName] {
            return (predefined.icon, predefined.color)
        }
        return ("ellipsis.circle.fill", .gray)
    }

    /// Convenience O(n) resolve — builds a temporary lookup on each call.
    /// Prefer `makeLookup(from:)` + `resolve(_:lookup:)` in hot paths.
    static func resolve(_ categoryName: String, customCategories: [CustomCategory]) -> (icon: String, color: Color) {
        let lookup = makeLookup(from: customCategories)
        return resolve(categoryName, lookup: lookup)
    }
}
