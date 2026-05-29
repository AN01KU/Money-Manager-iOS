import Foundation
import SwiftData
import Testing
@testable import Money_Manager

/// Table-driven tests for ReplayErrorPolicy.decide(for:error:).
/// All tests are pure — no ModelContext or network required.
struct ReplayErrorPolicyTests {

    // MARK: - Helpers

    private func decide(
        action: ChangeAction = .create,
        entityType: EntityType = .transaction,
        error: APIError
    ) -> ReplayAction {
        ReplayErrorPolicy.decide(action: action, entityType: entityType, error: error)
    }

    // MARK: - .unauthorized → .sessionExpired

    @Test func testUnauthorized_returnsSessionExpired() {
        #expect(decide(error: .unauthorized) == .sessionExpired)
    }

    // MARK: - .syncSessionInvalid → .orphanAll

    @Test func testSyncSessionInvalid_returnsOrphanAll() {
        #expect(decide(error: .syncSessionInvalid(reason: "EXPIRED")) == .orphanAll)
    }

    @Test func testSyncSessionInvalid_mismatch_returnsOrphanAll() {
        #expect(decide(error: .syncSessionInvalid(reason: "SYNC_SESSION_MISMATCH")) == .orphanAll)
    }

    // MARK: - .transientError → .stop

    @Test func testTransientError_returnsStop() {
        #expect(decide(error: .transientError) == .stop)
    }

    // MARK: - .staleWrite → .discardChange

    @Test func testStaleWrite_onUpdate_returnsDiscardChange() {
        #expect(decide(action: .update, error: .staleWrite) == .discardChange)
    }

    @Test func testStaleWrite_onCreate_returnsDiscardChange() {
        #expect(decide(action: .create, error: .staleWrite) == .discardChange)
    }

    // MARK: - .notFound + delete → .discardChangeAndEntity

    @Test func testNotFound_onDelete_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .delete, error: .notFound) == .discardChangeAndEntity)
    }

    // MARK: - .notFound + update → .discardChangeAndEntity

    @Test func testNotFound_onUpdate_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .update, error: .notFound) == .discardChangeAndEntity)
    }

    // MARK: - .notFound + create → retryLater (fall-through)

    @Test func testNotFound_onCreate_returnsRetryLater() {
        if case .retryLater = decide(action: .create, error: .notFound) { } else {
            Issue.record("Expected retryLater for 404 on create")
        }
    }

    // MARK: - .overrideAlreadyExists + create + category → .discardChangeAndEntity

    @Test func testOverrideAlreadyExists_onCreate_category_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .create, entityType: .category, error: .overrideAlreadyExists) == .discardChangeAndEntity)
    }

    // MARK: - .overrideAlreadyExists + other context → retryLater (fall-through)

    @Test func testOverrideAlreadyExists_onUpdate_category_returnsRetryLater() {
        if case .retryLater = decide(action: .update, entityType: .category, error: .overrideAlreadyExists) { } else {
            Issue.record("Expected retryLater for overrideAlreadyExists on update")
        }
    }

    @Test func testOverrideAlreadyExists_onCreate_transaction_returnsRetryLater() {
        // .overrideAlreadyExists is NOT .conflict — falls to default.
        if case .retryLater = decide(action: .create, entityType: .transaction, error: .overrideAlreadyExists) { } else {
            Issue.record("Expected retryLater for overrideAlreadyExists on non-category entity")
        }
    }

    // MARK: - .predefinedNotFound + create + category → .discardChangeAndEntity

    @Test func testPredefinedNotFound_onCreate_category_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .create, entityType: .category, error: .predefinedNotFound) == .discardChangeAndEntity)
    }

    @Test func testPredefinedNotFound_onUpdate_category_returnsRetryLater() {
        if case .retryLater = decide(action: .update, entityType: .category, error: .predefinedNotFound) { } else {
            Issue.record("Expected retryLater for predefinedNotFound on update")
        }
    }

    // MARK: - .invalidField → .deadLetter

    @Test func testInvalidField_icon_returnsDeadLetter() {
        #expect(decide(error: .invalidField("icon")) == .deadLetter(reason: "Invalid icon"))
    }

    @Test func testInvalidField_color_returnsDeadLetter() {
        #expect(decide(error: .invalidField("color")) == .deadLetter(reason: "Invalid color"))
    }

    // MARK: - Permanent 400s → .deadLetter (no retry increment)

    @Test func testMixedCurrencySettlement_returnsDeadLetter() {
        if case .deadLetter = decide(error: .mixedCurrencySettlement) { } else {
            Issue.record("Expected deadLetter for mixedCurrencySettlement")
        }
    }

    @Test func testMixedCurrencyGroupTx_returnsDeadLetter() {
        if case .deadLetter = decide(error: .mixedCurrencyGroupTx) { } else {
            Issue.record("Expected deadLetter for mixedCurrencyGroupTx")
        }
    }

    @Test func testAddMemberFailed_returnsDeadLetter() {
        if case .deadLetter = decide(error: .addMemberFailed) { } else {
            Issue.record("Expected deadLetter for addMemberFailed")
        }
    }

    // MARK: - .idOwnedByAnotherUser / Group → .discardChangeAndEntity

    @Test func testIdOwnedByAnotherUser_onCreate_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .create, error: .idOwnedByAnotherUser) == .discardChangeAndEntity)
    }

    @Test func testIdOwnedByAnotherUser_onUpdate_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .update, error: .idOwnedByAnotherUser) == .discardChangeAndEntity)
    }

    @Test func testIdOwnedByAnotherGroup_onCreate_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .create, error: .idOwnedByAnotherGroup) == .discardChangeAndEntity)
    }

    @Test func testIdOwnedByAnotherGroup_onUpdate_returnsDiscardChangeAndEntity() {
        #expect(decide(action: .update, error: .idOwnedByAnotherGroup) == .discardChangeAndEntity)
    }

    // MARK: - .conflict + create → .discardChange

    @Test func testConflict_onCreate_returnsDiscardChange() {
        #expect(decide(action: .create, error: .conflict) == .discardChange)
    }

    // MARK: - .conflict + update → retryLater (fall-through)

    @Test func testConflict_onUpdate_returnsRetryLater() {
        if case .retryLater = decide(action: .update, error: .conflict) { } else {
            Issue.record("Expected retryLater for conflict on update")
        }
    }

    // MARK: - Generic server errors → .retryLater

    @Test func testServerError_returnsRetryLater() {
        if case .retryLater = decide(error: .serverError) { } else {
            Issue.record("Expected retryLater for serverError")
        }
    }

    @Test func testUnknownError_returnsRetryLater() {
        if case .retryLater = decide(error: .unknown) { } else {
            Issue.record("Expected retryLater for unknown error")
        }
    }

    @Test func testHttpError_returnsRetryLaterWithDetail() {
        let action = decide(error: .httpError(statusCode: 503, message: "Service Unavailable"))
        #expect(action == .retryLater(reason: "HTTP 503: Service Unavailable"))
    }

    @Test func testHttpError_nilMessage_returnsRetryLaterWithNoBody() {
        let action = decide(error: .httpError(statusCode: 503, message: nil))
        #expect(action == .retryLater(reason: "HTTP 503: (no body)"))
    }

    // MARK: - ReplayAction equality

    @Test func testReplayActionEquality_deadLetter() {
        #expect(ReplayAction.deadLetter(reason: "x") == .deadLetter(reason: "x"))
        #expect(ReplayAction.deadLetter(reason: "x") != .deadLetter(reason: "y"))
    }

    @Test func testReplayActionEquality_retryLater() {
        #expect(ReplayAction.retryLater(reason: "a") == .retryLater(reason: "a"))
        #expect(ReplayAction.retryLater(reason: "a") != .retryLater(reason: "b"))
    }

    @Test func testReplayActionEquality_distinctCases() {
        #expect(ReplayAction.discardChange != .discardChangeAndEntity)
        #expect(ReplayAction.stop != .sessionExpired)
        #expect(ReplayAction.orphanAll != .discardChange)
    }
}
