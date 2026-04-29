import Foundation
import Testing
@testable import Money_Manager

struct APIErrorDescriptionTests {

    // MARK: - errorDescription

    @Test func testInvalidURLDescription() {
        #expect(APIError.invalidURL.errorDescription == "Invalid URL")
    }

    @Test func testInvalidResponseDescription() {
        #expect(APIError.invalidResponse.errorDescription == "Invalid response from server")
    }

    @Test func testUnauthorizedDescription() {
        #expect(APIError.unauthorized.errorDescription == "Session expired. Please log in again.")
    }

    @Test func testNotFoundDescription() {
        #expect(APIError.notFound.errorDescription == "Resource not found")
    }

    @Test func testConflictDescription() {
        #expect(APIError.conflict.errorDescription == "Conflict detected. Data will be synced.")
    }

    @Test func testServerErrorDescription() {
        #expect(APIError.serverError.errorDescription == "Server error. Please try again later.")
    }

    @Test func testUnknownDescription() {
        #expect(APIError.unknown.errorDescription == "An unknown error occurred")
    }

    @Test func testHttpErrorWithMessageUsesMessage() {
        let error = APIError.httpError(statusCode: 422, message: "Validation failed")
        #expect(error.errorDescription == "Validation failed")
    }

    @Test func testHttpErrorWithNilMessageFallsBackToStatusCode() {
        let error = APIError.httpError(statusCode: 422, message: nil)
        #expect(error.errorDescription == "HTTP Error: 422")
    }

    @Test func testSyncSessionInvalidDescriptionIncludesReason() {
        let error = APIError.syncSessionInvalid(reason: "SYNC_SESSION_MISMATCH")
        #expect(error.errorDescription?.contains("SYNC_SESSION_MISMATCH") == true)
    }

    @Test func testMissingTestDataDescriptionIncludesContext() {
        let error = APIError.missingTestData("expected user fixture")
        #expect(error.errorDescription?.contains("expected user fixture") == true)
    }

    @Test func testDecodingErrorDescriptionIncludesUnderlyingMessage() {
        struct FakeError: Error, LocalizedError {
            var errorDescription: String? { "unexpected null" }
        }
        let error = APIError.decodingError(FakeError())
        #expect(error.errorDescription?.contains("unexpected null") == true)
    }

    @Test func testEncodingErrorDescriptionIncludesUnderlyingMessage() {
        struct FakeError: Error, LocalizedError {
            var errorDescription: String? { "cannot encode NaN" }
        }
        let error = APIError.encodingError(FakeError())
        #expect(error.errorDescription?.contains("cannot encode NaN") == true)
    }

    @Test func testNetworkErrorDescriptionIncludesUnderlyingMessage() {
        struct FakeError: Error, LocalizedError {
            var errorDescription: String? { "connection lost" }
        }
        let error = APIError.networkError(FakeError())
        #expect(error.errorDescription?.contains("connection lost") == true)
    }

    // MARK: - Equatable: error-wrapped cases treat any error as equal

    @Test func testDecodingErrorsAreEqual() {
        struct A: Error {}
        struct B: Error {}
        #expect(APIError.decodingError(A()) == APIError.decodingError(B()))
    }

    @Test func testEncodingErrorsAreEqual() {
        struct A: Error {}
        struct B: Error {}
        #expect(APIError.encodingError(A()) == APIError.encodingError(B()))
    }

    @Test func testNetworkErrorsAreEqual() {
        struct A: Error {}
        struct B: Error {}
        #expect(APIError.networkError(A()) == APIError.networkError(B()))
    }

    @Test func testDifferentCasesAreNotEqual() {
        #expect(APIError.invalidURL != APIError.notFound)
        #expect(APIError.unauthorized != APIError.serverError)
    }

    // MARK: - init(from:data:) — remaining branches

    private func response(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    private func body(_ dict: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: dict)
    }

    @Test func test401WithErrorMessageUsesHttpError() {
        let data = body(["error": "token expired"])
        let error = APIError(from: response(status: 401), data: data)
        #expect(error == .httpError(statusCode: 401, message: "token expired"))
    }

    @Test func test404ReturnsNotFound() {
        let error = APIError(from: response(status: 404), data: nil)
        #expect(error == .notFound)
    }

    @Test func test500ReturnsServerError() {
        let error = APIError(from: response(status: 500), data: nil)
        #expect(error == .serverError)
    }

    @Test func test503ReturnsServerError() {
        let error = APIError(from: response(status: 503), data: nil)
        #expect(error == .serverError)
    }

    @Test func testOtherStatusCodeReturnsHttpError() {
        let error = APIError(from: response(status: 422), data: nil)
        #expect(error == .httpError(statusCode: 422, message: nil))
    }

    @Test func testOtherStatusCodeWithMessageBodyUsesMessage() {
        let data = body(["message": "rate limited"])
        let error = APIError(from: response(status: 429), data: data)
        #expect(error == .httpError(statusCode: 429, message: "rate limited"))
    }
}
