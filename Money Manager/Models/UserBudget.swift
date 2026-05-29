import Foundation
import SwiftData

/// Persists the single per-user budget scalar returned by GET /me/budget.
/// At most one row ever exists in the store.
@Model
final class UserBudget {
    /// Stable sentinel UUID — never changes, allows ChangeQueueManager deduplication.
    static let sentinelID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    @Attribute(.unique) var id: UUID
    var limit: Double?
    var updatedAt: Date

    init(limit: Double? = nil) {
        self.id = UserBudget.sentinelID
        self.limit = limit
        self.updatedAt = Date()
    }
}
