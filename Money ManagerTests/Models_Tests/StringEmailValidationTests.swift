import Foundation
import Testing
@testable import Money_Manager

struct StringEmailValidationTests {

    // MARK: - Valid addresses

    @Test func testSimpleEmailIsValid() {
        #expect("user@example.com".isValidEmail == true)
    }

    @Test func testEmailWithPlusTagIsValid() {
        #expect("user+tag@example.com".isValidEmail == true)
    }

    @Test func testEmailWithSubdomainIsValid() {
        #expect("user@mail.example.co.uk".isValidEmail == true)
    }

    @Test func testEmailWithDotsInLocalPartIsValid() {
        #expect("first.last@example.com".isValidEmail == true)
    }

    @Test func testEmailWithHyphenInDomainIsValid() {
        #expect("user@my-domain.com".isValidEmail == true)
    }

    @Test func testEmailWithNumbersIsValid() {
        #expect("user123@example456.com".isValidEmail == true)
    }

    // MARK: - Invalid addresses

    @Test func testEmptyStringIsInvalid() {
        #expect("".isValidEmail == false)
    }

    @Test func testMissingAtSignIsInvalid() {
        #expect("userexample.com".isValidEmail == false)
    }

    @Test func testMissingDomainIsInvalid() {
        #expect("user@".isValidEmail == false)
    }

    @Test func testMissingTLDIsInvalid() {
        #expect("user@example".isValidEmail == false)
    }

    @Test func testOnlyAtSignIsInvalid() {
        #expect("@".isValidEmail == false)
    }

    @Test func testSpaceInEmailIsInvalid() {
        #expect("user @example.com".isValidEmail == false)
    }

    @Test func testTLDTooShortIsInvalid() {
        #expect("user@example.c".isValidEmail == false)
    }

    @Test func testDoubleAtSignIsInvalid() {
        #expect("user@@example.com".isValidEmail == false)
    }
}
