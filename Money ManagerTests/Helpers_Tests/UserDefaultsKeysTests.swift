import Foundation
import Testing
@testable import Money_Manager

struct UserDefaultsKeysTests {

    // MARK: - Raw value round-trips

    @Test func testSelectedCurrencyRawValue() {
        #expect(UserDefaults.Keys.selectedCurrency.rawValue == "selectedCurrency")
    }

    @Test func testUserTimezoneRawValue() {
        #expect(UserDefaults.Keys.userTimezone.rawValue == "userTimezone")
    }

    @Test func testLastSyncAtRawValue() {
        #expect(UserDefaults.Keys.lastSyncAt.rawValue == "last_sync_at")
    }

    @Test func testScreenshotTokenOverrideRawValue() {
        #expect(UserDefaults.Keys.screenshotTokenOverride.rawValue == "screenshot_token_override")
    }

    @Test func testSyncSessionIDRawValue() {
        #expect(UserDefaults.Keys.syncSessionID.rawValue == "sync_session_id")
    }

    @Test func testLastLoggedInEmailRawValue() {
        #expect(UserDefaults.Keys.lastLoggedInEmail.rawValue == "last_logged_in_email")
    }

    @Test func testHasCompletedOnboardingRawValue() {
        #expect(UserDefaults.Keys.hasCompletedOnboarding.rawValue == "hasCompletedOnboarding")
    }

    @Test func testHasSeenLoginRawValue() {
        #expect(UserDefaults.Keys.hasSeenLogin.rawValue == "hasSeenLogin")
    }

    @Test func testDefaultBudgetLimitRawValue() {
        #expect(UserDefaults.Keys.defaultBudgetLimit.rawValue == "defaultBudgetLimit")
    }

    @Test func testBudgetMigratedToScalarRawValue() {
        #expect(UserDefaults.Keys.budgetMigratedToScalar.rawValue == "budgetMigratedToScalar")
    }

    // MARK: - Read/write round-trips

    @Test func testStringKeyRoundTrip() {
        let key = UserDefaults.Keys.selectedCurrency
        let original = UserDefaults.standard.string(forKey: key.rawValue)
        defer {
            if let original {
                UserDefaults.standard.set(original, forKey: key.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: key.rawValue)
            }
        }

        UserDefaults.standard.set("EUR", forKey: key.rawValue)
        #expect(UserDefaults.standard.string(forKey: key.rawValue) == "EUR")
    }

    @Test func testBoolKeyRoundTrip() {
        let key = UserDefaults.Keys.hasCompletedOnboarding
        let original = UserDefaults.standard.bool(forKey: key.rawValue)
        defer { UserDefaults.standard.set(original, forKey: key.rawValue) }

        UserDefaults.standard.set(true, forKey: key.rawValue)
        #expect(UserDefaults.standard.bool(forKey: key.rawValue) == true)

        UserDefaults.standard.set(false, forKey: key.rawValue)
        #expect(UserDefaults.standard.bool(forKey: key.rawValue) == false)
    }
}
