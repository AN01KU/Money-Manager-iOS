//
//  ChangeEnums.swift
//  Money Manager
//

import Foundation

/// Identifies the domain entity involved in a pending sync change.
enum EntityType: String, Codable, Sendable {
    case transaction
    case recurring
    case category
    case budget
    case expense
    case group
}

/// The CRUD action that triggered the sync change.
enum ChangeAction: String, Codable, Sendable {
    case create
    case update
    case delete
}

/// The HTTP method used when replaying the change against the backend.
enum HTTPMethod: String, Codable, Sendable {
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}
