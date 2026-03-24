//
//  CategoryResolver.swift
//  Money Manager
//

import SwiftUI

enum CategoryResolver {
    /// Resolves the display icon and color for a category name.
    /// Prefers a non-hidden custom category match, then falls back to a predefined category, then a default.
    static func resolve(_ categoryName: String, customCategories: [CustomCategory]) -> (icon: String, color: Color) {
        if let custom = customCategories.first(where: { $0.name == categoryName && !$0.isHidden }) {
            return (custom.icon, Color(hex: custom.color))
        }
        if let predefined = PredefinedCategory.allCases.first(where: { $0.rawValue == categoryName }) {
            return (predefined.icon, predefined.color)
        }
        return ("ellipsis.circle.fill", .gray)
    }
}
