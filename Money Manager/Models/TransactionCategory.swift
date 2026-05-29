//
//  TransactionCategory.swift
//  Money Manager
//
//  A display-only value type representing a category as shown to the user.
//  Built-in (predefined) categories come from the PredefinedCategory enum.
//  User overrides and fully custom categories are stored as Category rows.
//

import SwiftUI

struct TransactionCategory: Identifiable {
    /// Stable identifier — server key for predefined and synced custom rows,
    /// or the backing row's UUID string for unsynced custom rows.
    let id: String
    /// The stable server key used in API payloads (e.g. "food-dining" or "Ankush-cc-<uuid>").
    let key: String
    let name: String
    let icon: String
    let colorHex: String
    let isHidden: Bool
    let isPredefined: Bool
    let isDeletable: Bool

    /// The backing Category row, present only when the user has
    /// created an override (for predefined) or a fully custom category.
    let overrideRow: Category?

    var color: Color { Color(hex: colorHex) }

    // MARK: - Factory

    /// Builds the full list the UI needs: predefined defaults (possibly
    /// with user overrides applied), followed by fully custom categories.
    ///
    /// - `categories` is the full flat list from SwiftData — server-predefined rows
    ///   (`isServerPredefined == true`), user override rows (`isPredefined == true`),
    ///   and fully custom rows are all passed in together and split internally.
    static func merge(overrides categories: [Category]) -> [TransactionCategory] {
        var serverPredefined = [Category]()
        var overrideByKey = [String: Category]()
        var customRows = [Category]()

        for row in categories {
            if row.isServerPredefined {
                serverPredefined.append(row)
            } else if let predKey = row.predefinedKey,
                      let normalized = PredefinedCategory.normalizeKey(predKey) {
                overrideByKey[normalized] = row
            } else if !row.isPredefined {
                customRows.append(row)
            }
        }

        // Use server-predefined rows as the source of truth.
        // Fall back to the PredefinedCategory enum when the store is empty (offline/first launch).
        let predefinedSource: [TransactionCategory]
        if !serverPredefined.isEmpty {
            predefinedSource = serverPredefined.map { base -> TransactionCategory in
                let ov = overrideByKey[base.key]
                return TransactionCategory(
                    id: base.key,
                    key: base.key,
                    name: ov?.name ?? base.name,
                    icon: ov?.icon ?? base.icon,
                    colorHex: ov?.color ?? base.color,
                    isHidden: ov?.isHidden ?? base.isHidden,
                    isPredefined: true,
                    isDeletable: base.key != PredefinedCategory.other.serverKey,
                    overrideRow: ov
                )
            }
        } else {
            // Offline fallback — enum drives the list
            predefinedSource = PredefinedCategory.allCases.map { predefined -> TransactionCategory in
                let ov = overrideByKey[predefined.serverKey]
                return TransactionCategory(
                    id: predefined.serverKey,
                    key: predefined.serverKey,
                    name: ov?.name ?? predefined.rawValue,
                    icon: ov?.icon ?? predefined.icon,
                    colorHex: ov?.color ?? predefined.paletteHex,
                    isHidden: ov?.isHidden ?? false,
                    isPredefined: true,
                    isDeletable: predefined != .other,
                    overrideRow: ov
                )
            }
        }

        let customSource = customRows.map { row -> TransactionCategory in
            let resolvedKey = row.key.isEmpty ? row.id.uuidString : row.key
            return TransactionCategory(
                id: resolvedKey,
                key: resolvedKey,
                name: row.name,
                icon: row.icon,
                colorHex: row.color,
                isHidden: row.isHidden,
                isPredefined: false,
                isDeletable: true,
                overrideRow: row
            )
        }

        let all = predefinedSource + customSource
        return all.sorted {
            if $0.key == PredefinedCategory.other.serverKey { return false }
            if $1.key == PredefinedCategory.other.serverKey { return true }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
