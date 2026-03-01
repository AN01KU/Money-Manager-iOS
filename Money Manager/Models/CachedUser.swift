//
//  CachedUser.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 21/02/26.
//

import Foundation
import SwiftData

@Model
final class CachedUser {
    @Attribute(.unique) var id: UUID
    var email: String
    var username: String
    var createdAt: String
    
    init(id: UUID, email: String, username: String, createdAt: String) {
        self.id = id
        self.email = email
        self.username = username
        self.createdAt = createdAt
    }
    
    convenience init(from apiUser: APIUser) {
        self.init(id: apiUser.id, email: apiUser.email, username: apiUser.username, createdAt: apiUser.createdAt)
    }
    
    func toAPIUser() -> APIUser {
        APIUser(id: id, email: email, username: username, createdAt: createdAt)
    }
}
