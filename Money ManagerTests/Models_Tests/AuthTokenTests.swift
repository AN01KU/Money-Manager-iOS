//
//  AuthTokenTests.swift
//  Money ManagerTests
//
//  Created by Ankush Ganesh on 22/02/26.
//

import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct AuthTokenTests {
    
    @Test
    func testAuthTokenInitialization() {
        let token = AuthToken(token: "test-token-123")
        
        #expect(token.token == "test-token-123")
        #expect(token.createdAt != nil)
    }
    
    @Test
    func testAuthTokenStoresTokenCorrectly() {
        let tokenString = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let authToken = AuthToken(token: tokenString)
        
        #expect(authToken.token == tokenString)
    }
}
