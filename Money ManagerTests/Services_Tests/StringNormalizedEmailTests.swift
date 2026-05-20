import Foundation
import Testing
@testable import Money_Manager

@MainActor
struct StringNormalizedEmailTests {

    @Test func testLowercasesUppercaseEmail() {
        #expect("USER@EXAMPLE.COM".normalizedEmail == "user@example.com")
    }

    @Test func testLowercaseEmailUnchanged() {
        #expect("user@example.com".normalizedEmail == "user@example.com")
    }

    @Test func testMixedCaseEmail() {
        #expect("User.Name@Example.COM".normalizedEmail == "user.name@example.com")
    }

    @Test func testTrimsLeadingAndTrailingWhitespace() {
        #expect("  user@example.com  ".normalizedEmail == "user@example.com")
    }

    @Test func testTrimsAndLowercases() {
        #expect("  USER@EXAMPLE.COM  ".normalizedEmail == "user@example.com")
    }

    @Test func testEmptyStringRemainsEmpty() {
        #expect("".normalizedEmail == "")
    }

    // MARK: - Request struct integration

    @Test func testAPISignupRequestNormalizesEmail() {
        let req = APISignupRequest(email: "ANKUSH@GMAIL.COM", username: "ankush", password: "pw", inviteCode: "abc")
        #expect(req.email == "ankush@gmail.com")
    }

    @Test func testAPILoginRequestNormalizesEmail() {
        let req = APILoginRequest(email: "  Ankush@Gmail.Com  ", password: "pw")
        #expect(req.email == "ankush@gmail.com")
    }

    @Test func testAPIUpdateMeRequestNormalizesEmail() {
        let req = APIUpdateMeRequest(email: "ANKUSH@GMAIL.COM")
        #expect(req.email == "ankush@gmail.com")
    }

    @Test func testAPIUpdateMeRequestNilEmailRemainsNil() {
        let req = APIUpdateMeRequest(email: nil)
        #expect(req.email == nil)
    }

    @Test func testAPIAddMemberRequestNormalizesEmail() {
        let req = APIAddMemberRequest(email: "  MEMBER@EXAMPLE.COM  ")
        #expect(req.email == "member@example.com")
    }
}
