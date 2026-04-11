//
//  APIErrorSyncSessionTests.swift
//  Money ManagerTests
//

import Foundation
import Testing
@testable import Money_Manager

struct APIErrorSyncSessionTests {

    // MARK: - Helpers

    private func response(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    private func body(_ dict: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: dict)
    }

    // MARK: - syncSessionInvalid cases

    @Test
    func test409WithMismatchReasonThrowsSyncSessionInvalid() {
        let data = body(["valid": false, "reason": "SYNC_SESSION_MISMATCH"])
        let error = APIError(from: response(status: 409), data: data)

        #expect(error == .syncSessionInvalid(reason: "SYNC_SESSION_MISMATCH"))
    }

    @Test
    func test409WithExpiredReasonThrowsSyncSessionInvalid() {
        let data = body(["valid": false, "reason": "SYNC_SESSION_EXPIRED"])
        let error = APIError(from: response(status: 409), data: data)

        #expect(error == .syncSessionInvalid(reason: "SYNC_SESSION_EXPIRED"))
    }

    @Test
    func test409WithNotFoundReasonThrowsSyncSessionInvalid() {
        let data = body(["valid": false, "reason": "SYNC_SESSION_NOT_FOUND"])
        let error = APIError(from: response(status: 409), data: data)

        #expect(error == .syncSessionInvalid(reason: "SYNC_SESSION_NOT_FOUND"))
    }

    // MARK: - Fallback to .conflict

    @Test
    func test409WithUnrecognisedReasonFallsBackToConflict() {
        let data = body(["reason": "SOME_OTHER_REASON"])
        let error = APIError(from: response(status: 409), data: data)

        #expect(error == .conflict)
    }

    @Test
    func test409WithNoReasonFieldFallsBackToConflict() {
        let data = body(["error": "conflict"])
        let error = APIError(from: response(status: 409), data: data)

        #expect(error == .conflict)
    }

    @Test
    func test409WithEmptyBodyFallsBackToConflict() {
        let error = APIError(from: response(status: 409), data: nil)

        #expect(error == .conflict)
    }

    // MARK: - Other status codes unaffected

    @Test
    func test401StillThrowsUnauthorized() {
        let error = APIError(from: response(status: 401), data: nil)

        #expect(error == .unauthorized)
    }

    @Test
    func test500StillThrowsServerError() {
        let error = APIError(from: response(status: 500), data: nil)

        #expect(error == .serverError)
    }
}
