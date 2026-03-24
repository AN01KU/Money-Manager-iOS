//
//  AuthToken.swift
//  Money Manager
//

import Foundation
import SwiftData

@Model
final class AuthToken {
    var token: String
    var createdAt: Date

    init(token: String) {
        self.token = token
        self.createdAt = Date()
    }
}
