import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct AuthTokenTests {

    @Test
    func test_authToken_init_storesToken() {
        let token = AuthToken(token: "test-token-123")

        #expect(token.token == "test-token-123")
    }

    @Test
    func test_authToken_init_setsCreatedAtToNow() {
        let before = Date()
        let token = AuthToken(token: "any")
        let after = Date()

        #expect(token.createdAt >= before)
        #expect(token.createdAt <= after)
    }

    @Test
    func test_authToken_storesJWTString() {
        let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature"
        let token = AuthToken(token: jwt)

        #expect(token.token == jwt)
    }

    @Test
    func test_authToken_emptyStringIsStoredAsIs() {
        // Edge case: empty token string should be stored exactly as passed
        let token = AuthToken(token: "")

        #expect(token.token == "")
    }
}
