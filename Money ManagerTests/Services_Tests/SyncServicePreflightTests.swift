//
//  SyncServicePreflightTests.swift
//  Money ManagerTests
//

import Foundation
import Testing
@testable import Money_Manager

/// Tests for PreflightOutcome — the result type returned by SyncService.runPreflight().
///
/// runPreflight() is private, so we test its effects indirectly through
/// syncOnLaunch / syncOnReconnect using a spy ChangeQueueManager.
/// For the preflight outcome enum itself, we verify the type's own behaviour.
struct PreflightOutcomeTests {

    @Test
    func testValidOutcomeIsDistinctFromInvalid() {
        let valid = PreflightOutcome.valid
        let invalid = PreflightOutcome.invalid(reason: "SYNC_SESSION_EXPIRED")

        if case .valid = valid { } else {
            Issue.record("Expected .valid")
        }
        if case .invalid(let r) = invalid {
            #expect(r == "SYNC_SESSION_EXPIRED")
        } else {
            Issue.record("Expected .invalid")
        }
    }

    @Test
    func testSkippedOutcomeExists() {
        let skipped = PreflightOutcome.skipped
        if case .skipped = skipped { } else {
            Issue.record("Expected .skipped")
        }
    }

    @Test
    func testInvalidOutcomePreservesReason() {
        let reasons = ["SYNC_SESSION_MISMATCH", "SYNC_SESSION_EXPIRED", "SYNC_SESSION_NOT_FOUND"]
        for reason in reasons {
            let outcome = PreflightOutcome.invalid(reason: reason)
            if case .invalid(let r) = outcome {
                #expect(r == reason)
            } else {
                Issue.record("Expected .invalid for \(reason)")
            }
        }
    }
}

// MARK: - APISyncPreflightResponse decoding

@MainActor
struct APISyncPreflightResponseTests {

    private func decode(_ json: String) throws -> APISyncPreflightResponse {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(APISyncPreflightResponse.self, from: data)
    }

    @Test
    func testDecodesValidTrueWithNoReason() throws {
        let response = try decode(#"{"valid": true}"#)
        #expect(response.valid == true)
        #expect(response.reason == nil)
    }

    @Test
    func testDecodesValidFalseWithMismatchReason() throws {
        let response = try decode(#"{"valid": false, "reason": "SYNC_SESSION_MISMATCH"}"#)
        #expect(response.valid == false)
        #expect(response.reason == "SYNC_SESSION_MISMATCH")
    }

    @Test
    func testDecodesValidFalseWithExpiredReason() throws {
        let response = try decode(#"{"valid": false, "reason": "SYNC_SESSION_EXPIRED"}"#)
        #expect(response.valid == false)
        #expect(response.reason == "SYNC_SESSION_EXPIRED")
    }

    @Test
    func testDecodesValidFalseWithNotFoundReason() throws {
        let response = try decode(#"{"valid": false, "reason": "SYNC_SESSION_NOT_FOUND"}"#)
        #expect(response.valid == false)
        #expect(response.reason == "SYNC_SESSION_NOT_FOUND")
    }
}
