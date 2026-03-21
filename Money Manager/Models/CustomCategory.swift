//
//  CustomCategory.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation
import SwiftData

@Model
final class CustomCategory {
    @Attribute(.unique) var id: UUID
    
    var name: String
    var icon: String
    var color: String
    var isHidden: Bool
    
    /// If true, this is a built-in default category (seeded from PredefinedCategory).
    var isPredefined: Bool
    /// The enum case key (e.g. "foodDining") so we can identify which predefined it maps to.
    var predefinedKey: String?
    
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, icon: String, color: String, isPredefined: Bool = false, predefinedKey: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isHidden = false
        self.isPredefined = isPredefined
        self.predefinedKey = predefinedKey
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// "Other" category can never be deleted.
    var isDeletable: Bool {
        predefinedKey != "other"
    }
}
