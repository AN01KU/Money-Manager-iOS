//
//  ServerErrorCodeTests.swift
//  Money ManagerTests
//

import Foundation
import Testing
@testable import Money_Manager

struct ServerErrorCodeTests {

    // MARK: - Raw value round-trips

    @Test func testStaleWrite() {
        #expect(ServerErrorCode(rawValue: "STALE_WRITE") == .staleWrite)
    }

    @Test func testOverrideAlreadyExists() {
        #expect(ServerErrorCode(rawValue: "OVERRIDE_ALREADY_EXISTS") == .overrideAlreadyExists)
    }

    @Test func testPredefinedNotFound() {
        #expect(ServerErrorCode(rawValue: "PREDEFINED_NOT_FOUND") == .predefinedNotFound)
    }

    @Test func testInvalidIcon() {
        #expect(ServerErrorCode(rawValue: "INVALID_ICON") == .invalidIcon)
    }

    @Test func testInvalidColor() {
        #expect(ServerErrorCode(rawValue: "INVALID_COLOR") == .invalidColor)
    }

    @Test func testIdOwnedByAnotherUser() {
        #expect(ServerErrorCode(rawValue: "ID_OWNED_BY_ANOTHER_USER") == .idOwnedByAnotherUser)
    }

    @Test func testIdOwnedByAnotherGroup() {
        #expect(ServerErrorCode(rawValue: "ID_OWNED_BY_ANOTHER_GROUP") == .idOwnedByAnotherGroup)
    }

    @Test func testMixedCurrencySettlement() {
        #expect(ServerErrorCode(rawValue: "MIXED_CURRENCY_SETTLEMENT") == .mixedCurrencySettlement)
    }

    @Test func testMixedCurrencyGroupTx() {
        #expect(ServerErrorCode(rawValue: "MIXED_CURRENCY_GROUP_TX") == .mixedCurrencyGroupTx)
    }

    @Test func testAddMemberFailed() {
        #expect(ServerErrorCode(rawValue: "add_member_failed") == .addMemberFailed)
    }

    @Test func testUnknownCodeReturnsNil() {
        #expect(ServerErrorCode(rawValue: "UNKNOWN_CODE") == nil)
        #expect(ServerErrorCode(rawValue: "") == nil)
    }

    // MARK: - APIError mapping via init(from:data:)

    private func response(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    private func body(_ dict: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: dict)
    }

    @Test func test400InvalidIconMapsToInvalidField() {
        let error = APIError(from: response(status: 400), data: body(["code": "INVALID_ICON"]))
        #expect(error == .invalidField("icon"))
    }

    @Test func test400InvalidColorMapsToInvalidField() {
        let error = APIError(from: response(status: 400), data: body(["code": "INVALID_COLOR"]))
        #expect(error == .invalidField("color"))
    }

    @Test func test400MixedCurrencySettlementMaps() {
        let error = APIError(from: response(status: 400), data: body(["code": "MIXED_CURRENCY_SETTLEMENT"]))
        #expect(error == .mixedCurrencySettlement)
    }

    @Test func test400MixedCurrencyGroupTxMaps() {
        let error = APIError(from: response(status: 400), data: body(["code": "MIXED_CURRENCY_GROUP_TX"]))
        #expect(error == .mixedCurrencyGroupTx)
    }

    @Test func test400AddMemberFailedMaps() {
        let error = APIError(from: response(status: 400), data: body(["code": "add_member_failed"]))
        #expect(error == .addMemberFailed)
    }

    @Test func test400UnknownCodeFallsBackToHttpError() {
        let error = APIError(from: response(status: 400), data: body(["code": "SOME_UNKNOWN", "error": "bad input"]))
        #expect(error == .httpError(statusCode: 400, message: "bad input"))
    }

    @Test func test404PredefinedNotFoundMaps() {
        let error = APIError(from: response(status: 404), data: body(["code": "PREDEFINED_NOT_FOUND"]))
        #expect(error == .predefinedNotFound)
    }

    @Test func test404OtherCodeFallsBackToNotFound() {
        let error = APIError(from: response(status: 404), data: body(["code": "SOMETHING_ELSE"]))
        #expect(error == .notFound)
    }

    @Test func test409StaleWriteMaps() {
        let error = APIError(from: response(status: 409), data: body(["code": "STALE_WRITE"]))
        #expect(error == .staleWrite)
    }

    @Test func test409OverrideAlreadyExistsMaps() {
        let error = APIError(from: response(status: 409), data: body(["code": "OVERRIDE_ALREADY_EXISTS"]))
        #expect(error == .overrideAlreadyExists)
    }

    @Test func test409IdOwnedByAnotherUserMaps() {
        let error = APIError(from: response(status: 409), data: body(["code": "ID_OWNED_BY_ANOTHER_USER"]))
        #expect(error == .idOwnedByAnotherUser)
    }

    @Test func test409IdOwnedByAnotherGroupMaps() {
        let error = APIError(from: response(status: 409), data: body(["code": "ID_OWNED_BY_ANOTHER_GROUP"]))
        #expect(error == .idOwnedByAnotherGroup)
    }

    @Test func test409UnknownCodeFallsBackToConflict() {
        let error = APIError(from: response(status: 409), data: body(["code": "SOME_UNKNOWN"]))
        #expect(error == .conflict)
    }
}
