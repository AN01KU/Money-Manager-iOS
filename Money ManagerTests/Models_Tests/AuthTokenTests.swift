import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct AuthTokenTests {

    @Test
    func testAuthTokenInitStoresToken() {
        let token = AuthToken(token: "test-token-123")

        #expect(token.token == "test-token-123")
    }

    @Test
    func testAuthTokenInitSetsCreatedAtToNow() {
        let before = Date()
        let token = AuthToken(token: "any")
        let after = Date()

        #expect(token.createdAt >= before)
        #expect(token.createdAt <= after)
    }

    @Test
    func testAuthTokenStoresJWTString() {
        let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature"
        let token = AuthToken(token: jwt)

        #expect(token.token == jwt)
    }

    @Test
    func testAuthTokenEmptyStringIsStoredAsIs() {
        let token = AuthToken(token: "")

        #expect(token.token == "")
    }
}
