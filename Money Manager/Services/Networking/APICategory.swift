//
//  APICategory.swift
//  Money Manager
//

import Foundation

struct APICategory: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let key: String
    let name: String
    let icon: String
    let color: String
    let isHidden: Bool?
    let isPredefined: Bool?
    let predefinedKey: String?
    let createdAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case key
        case name
        case icon
        case color
        case isHidden = "is_hidden"
        case isPredefined = "is_predefined"
        case predefinedKey = "predefined_key"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APIPredefinedCategory: Codable, Sendable {
    let id: UUID
    let key: String
    let name: String
    let icon: String
    let color: String
    let isHidden: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case key
        case name
        case icon
        case color
        case isHidden = "is_hidden"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APICreateCategoryRequest: Codable, Sendable {
    let name: String?
    let icon: String?
    let color: String?
    let isHidden: Bool?
    let predefinedKey: String?

    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case color
        case isHidden = "is_hidden"
        case predefinedKey = "predefined_key"
    }
}

struct APIUpdateCategoryRequest: Codable, Sendable {
    let name: String?
    let icon: String?
    let color: String?
    let isHidden: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case color
        case isHidden = "is_hidden"
    }
}
