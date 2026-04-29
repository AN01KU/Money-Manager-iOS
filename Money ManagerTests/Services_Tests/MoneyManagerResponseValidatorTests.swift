import Foundation
import Testing
@testable import Money_Manager

struct MoneyManagerResponseValidatorTests {

    private let validator = MoneyManagerResponseValidator()

    private func makeResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.example.com/test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    // MARK: - Success codes pass through

    @Test func testValidatorPassesFor200() throws {
        let response = makeResponse(statusCode: 200)
        #expect(throws: Never.self) {
            try validator.validate(response, data: Data(), for: URLRequest(url: URL(string: "https://api.example.com")!))
        }
    }

    @Test func testValidatorPassesFor201() throws {
        let response = makeResponse(statusCode: 201)
        #expect(throws: Never.self) {
            try validator.validate(response, data: Data(), for: URLRequest(url: URL(string: "https://api.example.com")!))
        }
    }

    @Test func testValidatorPassesFor204() throws {
        let response = makeResponse(statusCode: 204)
        #expect(throws: Never.self) {
            try validator.validate(response, data: Data(), for: URLRequest(url: URL(string: "https://api.example.com")!))
        }
    }

    // MARK: - Error codes throw

    @Test func testValidatorThrowsFor401() throws {
        let response = makeResponse(statusCode: 401)
        #expect(throws: (any Error).self) {
            try validator.validate(response, data: Data(), for: URLRequest(url: URL(string: "https://api.example.com")!))
        }
    }

    @Test func testValidatorThrowsFor404() throws {
        let response = makeResponse(statusCode: 404)
        var threwError = false
        do {
            try validator.validate(response, data: Data(), for: URLRequest(url: URL(string: "https://api.example.com")!))
        } catch let error as APIError {
            threwError = true
            if case .notFound = error {} else {
                Issue.record("Expected .notFound, got \(error)")
            }
        }
        #expect(threwError)
    }

    @Test func testValidatorThrowsFor500() throws {
        let response = makeResponse(statusCode: 500)
        var threwError = false
        do {
            try validator.validate(response, data: Data(), for: URLRequest(url: URL(string: "https://api.example.com")!))
        } catch let error as APIError {
            threwError = true
            if case .serverError = error {} else {
                Issue.record("Expected .serverError, got \(error)")
            }
        }
        #expect(threwError)
    }

    @Test func testValidatorThrowsFor400() throws {
        let response = makeResponse(statusCode: 400)
        #expect(throws: (any Error).self) {
            try validator.validate(response, data: Data(), for: URLRequest(url: URL(string: "https://api.example.com")!))
        }
    }
}
