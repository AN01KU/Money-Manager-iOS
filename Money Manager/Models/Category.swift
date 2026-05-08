//
//  Category.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID

    /// The stable server key used in API payloads (e.g. "food-dining" or "Ankush-cc-<uuid>").
    var key: String
    var name: String
    var icon: String
    var color: String
    var isHidden: Bool

    /// If true, this is a built-in default category (seeded from PredefinedCategory).
    var isPredefined: Bool
    /// The kebab-case server key (e.g. "food-dining") linking to PredefinedCategory.
    /// Legacy rows may contain the camelCase form (e.g. "foodDining"); use
    /// `PredefinedCategory.normalizeKey(_:)` when reading.
    var predefinedKey: String?
    /// True for rows seeded from GET /predefined-categories (global, not user-owned).
    /// False for user override rows and fully custom categories.
    var isServerPredefined: Bool

    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), key: String = "", name: String, icon: String, color: String, isPredefined: Bool = false, predefinedKey: String? = nil, isServerPredefined: Bool = false) {
        self.id = id
        self.key = key
        self.name = name
        self.icon = icon
        self.color = color
        self.isHidden = false
        self.isPredefined = isPredefined
        self.predefinedKey = predefinedKey
        self.isServerPredefined = isServerPredefined
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// "Other" category can never be deleted.
    var isDeletable: Bool {
        key != "other"
    }

    /// Builds a user-override row for a predefined `TransactionCategory`.
    /// Use this whenever you need to persist a change to a predefined category
    /// (hide, edit name/icon/color) and no override row exists yet.
    @MainActor static func makeOverride(for category: TransactionCategory) -> Category {
        let serverKey: String
        let name: String
        let icon: String
        let color: String

        if let predefined = category.predefinedCase {
            serverKey = predefined.serverKey
            name = predefined.rawValue
            icon = predefined.icon
            color = predefined.defaultColorHex
        } else {
            // Server-predefined row not in the local enum — extract key from id.
            serverKey = String(category.id.dropFirst("predefined:".count))
            name = category.name
            icon = category.icon
            color = category.colorHex
        }

        return Category(
            key: serverKey,
            name: name,
            icon: icon,
            color: color,
            isPredefined: true,
            predefinedKey: serverKey
        )
    }
}
