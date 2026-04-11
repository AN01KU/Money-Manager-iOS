//
//  TransactionCategory.swift
//  Money Manager
//
//  A display-only value type representing a category as shown to the user.
//  Built-in (predefined) categories come from the PredefinedCategory enum.
//  User overrides and fully custom categories are stored as CustomCategory rows.
//

import SwiftUI

struct TransactionCategory: Identifiable {
    let id: String          // "predefined:foodDining" or "custom:<uuid>"
    let name: String
    let icon: String
    let colorHex: String
    let isHidden: Bool
    let isPredefined: Bool
    let isDeletable: Bool

    /// The backing CustomCategory row, present only when the user has
    /// created an override (for predefined) or a fully custom category.
    let overrideRow: CustomCategory?

    var color: Color { Color(hex: colorHex) }

    // MARK: - Factory

    /// Builds the full list the UI needs: predefined defaults (possibly
    /// with user overrides applied), followed by fully custom categories.
    static func merge(overrides: [CustomCategory]) -> [TransactionCategory] {
        var overrideByKey = [String: CustomCategory]()
        var customRows = [CustomCategory]()

        for row in overrides {
            if let key = row.predefinedKey {
                overrideByKey[key] = row
            } else {
                customRows.append(row)
            }
        }

        var result = PredefinedCategory.allCases.map { predefined -> TransactionCategory in
            let ov = overrideByKey[predefined.key]
            return TransactionCategory(
                id: "predefined:\(predefined.key)",
                name: ov?.name ?? predefined.rawValue,
                icon: ov?.icon ?? predefined.icon,
                colorHex: ov?.color ?? predefined.defaultColorHex,
                isHidden: ov?.isHidden ?? false,
                isPredefined: true,
                isDeletable: predefined != .other,
                overrideRow: ov
            )
        }

        result += customRows.map { row in
            TransactionCategory(
                id: "custom:\(row.id.uuidString)",
                name: row.name,
                icon: row.icon,
                colorHex: row.color,
                isHidden: row.isHidden,
                isPredefined: false,
                isDeletable: true,
                overrideRow: row
            )
        }

        return result
    }
}
