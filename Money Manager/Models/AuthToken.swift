//
//  AuthToken.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 22/02/26.
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
