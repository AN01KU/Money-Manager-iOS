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
    
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, icon: String, color: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.isHidden = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
