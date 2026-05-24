//
//  ReplayErrorPolicy.swift
//  Money Manager
//

import Foundation

/// What replayAll should do after a single change fails.
enum ReplayAction: Equatable {
    /// Remove only the pending change; leave the local entity intact.
    case discardChange
    /// Remove both the pending change and the local entity.
    case discardChangeAndEntity
    /// Move the change to the dead-letter queue with a reason string.
    case deadLetter(reason: String)
    /// Orphan the entire queue and stop processing. Posts .syncSessionOrphaned.
    case orphanAll
    /// Stop processing the current batch without mutating the change.
    /// Used for transient errors (502) that should be retried on next sync trigger.
    case stop
    /// Post .authSessionExpired and stop.
    case sessionExpired
    /// Increment retry count and schedule a backoff window.
    case retryLater(reason: String)

    nonisolated static func == (lhs: ReplayAction, rhs: ReplayAction) -> Bool {
        switch (lhs, rhs) {
        case (.discardChange, .discardChange),
             (.discardChangeAndEntity, .discardChangeAndEntity),
             (.orphanAll, .orphanAll),
             (.stop, .stop),
             (.sessionExpired, .sessionExpired):
            return true
        case let (.deadLetter(lR), .deadLetter(rR)):
            return lR == rR
        case let (.retryLater(lR), .retryLater(rR)):
            return lR == rR
        default:
            return false
        }
    }
}

enum ReplayErrorPolicy {
    /// Pure decision function — no side effects. Takes raw string values from
    /// the PendingChange to avoid @MainActor isolation on the @Model type.
    nonisolated static func decide(action: String, entityType: String, error apiError: APIError) -> ReplayAction {
        switch apiError {
        case .unauthorized:
            return .sessionExpired

        case .syncSessionInvalid:
            return .orphanAll

        case .transientError:
            // 502 — server-side blip, back off and retry on next sync trigger.
            return .stop

        case .staleWrite:
            // Server has a newer version; drop our stale pending write.
            return .discardChange

        case .notFound where action == "delete",
             .notFound where action == "update":
            // Entity gone from server; purge the local row.
            return .discardChangeAndEntity

        case .overrideAlreadyExists where action == "create" && entityType == "category":
            // Server already owns this override; next pull will bring the canonical version.
            return .discardChangeAndEntity

        case .predefinedNotFound where action == "create" && entityType == "category":
            // Predefined category removed by admin; local override is dead.
            return .discardChangeAndEntity

        case .invalidField(let field):
            return .deadLetter(reason: "Invalid \(field)")

        case .mixedCurrencySettlement, .mixedCurrencyGroupTx, .addMemberFailed:
            return .deadLetter(reason: apiError.errorDescription ?? "Permanent 400")

        case .idOwnedByAnotherUser, .idOwnedByAnotherGroup:
            return .discardChangeAndEntity

        case .conflict where action == "create":
            // 409 on create — entity already on server; treat as success.
            return .discardChange

        default:
            let detail: String
            if case .httpError(let code, let msg) = apiError {
                detail = "HTTP \(code): \(msg ?? "(no body)")"
            } else {
                detail = apiError.localizedDescription
            }
            return .retryLater(reason: detail)
        }
    }
}
