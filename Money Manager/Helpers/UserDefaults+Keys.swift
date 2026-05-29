import Foundation

extension UserDefaults {
    enum Keys: String {
        case selectedCurrency
        case userTimezone
        case lastSyncAt         = "last_sync_at"
        case screenshotTokenOverride = "screenshot_token_override"
        case syncSessionID      = "sync_session_id"
        case lastLoggedInEmail  = "last_logged_in_email"
        case hasCompletedOnboarding
        case hasSeenLogin
        case defaultBudgetLimit
        case budgetMigratedToScalar
    }
}
