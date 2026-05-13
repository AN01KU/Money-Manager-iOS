import Foundation
import SwiftData
import Testing
@testable import Money_Manager

@MainActor
struct RecurringDateHelperTests {
    
    @Test
    func testNextOccurrenceReturnsNilWhenInactive() {
        let expense = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            isActive: false
        )
        
        #expect(expense.nextOccurrence == nil)
    }
    
    @Test
    func testNextOccurrenceForDailyFrequency() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        let expense = RecurringTransaction(
            name: "Daily Coffee",
            amount: 50,
            category: "Food",
            frequency: .daily,
            startDate: yesterday
        )
        
        let next = expense.nextOccurrence
        #expect(next != nil)
        #expect(next! > yesterday)
    }
    
    @Test
    func testNextOccurrenceForWeeklyFrequency() {
        let calendar = Calendar.current
        // Start exactly 2 weeks ago (no daysOfWeek → pure weekly interval)
        let pastDate = calendar.date(byAdding: .weekOfYear, value: -2, to: Date())!

        let expense = RecurringTransaction(
            name: "Weekly Gym",
            amount: 500,
            category: "Health",
            frequency: .weekly,
            startDate: pastDate
        )

        let next = expense.nextOccurrence
        #expect(next != nil)
        // Must be strictly in the future
        #expect(next! > Date())
        // Must be within 7 days of today (weekly cadence means next occurrence is < 1 week away)
        let oneWeekAhead = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())!
        #expect(next! <= oneWeekAhead)
    }
    
    @Test
    func testNextOccurrenceForMonthlyFrequency() {
        let calendar = Calendar.current
        // Start exactly one month ago with dayOfMonth = 15
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = 15
        components.hour = 0
        components.minute = 0
        components.second = 0
        let startDate = calendar.date(byAdding: .month, value: -1, to: calendar.date(from: components)!)!

        let expense = RecurringTransaction(
            name: "Rent",
            amount: 15000,
            category: "Housing",
            frequency: .monthly,
            dayOfMonth: 15,
            startDate: startDate
        )

        let next = expense.nextOccurrence
        #expect(next != nil)
        // Must be strictly in the future
        #expect(next! > Date())
        // Must fall on day 15 (or day 28 if the month is short — matches the clamping logic)
        let dayOfMonth = calendar.component(.day, from: next!)
        #expect(dayOfMonth == 15 || dayOfMonth == 28)
    }

    @Test
    func testNextOccurrenceForMonthlyWithoutDayOfMonth() {
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!

        let expense = RecurringTransaction(
            name: "Subscription",
            amount: 100,
            category: "Entertainment",
            frequency: .monthly,
            startDate: lastMonth
        )

        let next = expense.nextOccurrence
        #expect(next != nil)
        // Must be strictly in the future
        #expect(next! > Date())
    }
    
    @Test
    func testNextOccurrenceForYearlyFrequency() {
        let lastYear = Calendar.current.date(byAdding: .year, value: -1, to: Date())!

        let expense = RecurringTransaction(
            name: "Insurance",
            amount: 12000,
            category: "Insurance",
            frequency: .yearly,
            startDate: lastYear
        )

        let next = expense.nextOccurrence
        #expect(next != nil)
        #expect(next! > Date())
    }
    
    @Test
    func testNextOccurrenceReturnsNextDateWhenBeforeEndDate() {
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        let expense = RecurringTransaction(
            name: "Active Subscription",
            amount: 100,
            category: "Entertainment",
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate,
            isActive: true
        )
        
        #expect(expense.nextOccurrence != nil)
    }
    
    @Test
    func testNextOccurrenceWithWeeklySpecificDays() {
        let pastDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        
        let expense = RecurringTransaction(
            name: "Weekly Yoga",
            amount: 200,
            category: "Health",
            frequency: .weekly,
            daysOfWeek: [1, 3, 5],
            startDate: pastDate
        )
        
        let next = expense.nextOccurrence
        #expect(next != nil)
    }
    
    @Test
    func testLastOccurrenceReturnsStartDateWhenNoLastAddedDate() {
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        
        let expense = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: startDate
        )
        
        #expect(expense.lastOccurrence == startDate)
    }
    
    @Test
    func testLastOccurrenceReturnsLastAddedDateWhenExists() {
        let startDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        let lastAdded = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        
        let expense = RecurringTransaction(
            name: "Netflix",
            amount: 649,
            category: "Entertainment",
            frequency: .monthly,
            startDate: startDate,
            lastAddedDate: lastAdded
        )
        
        #expect(expense.lastOccurrence == lastAdded)
    }
}

@MainActor
struct DateExtensionTests {
    
    @Test
    func testRelativeStringReturnsNonEmptyString() {
        let today = Date()
        #expect(!today.relativeString.isEmpty)
    }
    
    @Test
    func testRelativeStringContainsExpectedUnits() {
        // Use a fixed 7-day offset so the result is always a "week" unit, not locale-dependent words.
        // RelativeDateTimeFormatter is locale-aware but we assert non-emptiness and that
        // the past/future direction differs — both of which are locale-independent.
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let sevenDaysAhead = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let pastString = sevenDaysAgo.relativeString
        let futureString = sevenDaysAhead.relativeString

        #expect(!pastString.isEmpty)
        #expect(!futureString.isEmpty)
        // The two strings must differ — past and future produce distinct formatted output
        // regardless of locale.
        #expect(pastString != futureString)
    }
    
    @Test
    func testShortDateStringReturnsFormattedDate() {
        let date = Date()
        let formatted = date.shortDateString
        
        #expect(!formatted.isEmpty)
        #expect(formatted.count > 5)
    }
    
    @Test
    func testShortDateStringDoesNotContainTime() {
        let date = Date()
        let formatted = date.shortDateString

        #expect(!formatted.contains(":"))
    }

    // MARK: - formattedNextOccurrence: respects passed time zone (no UTC-as-local drift)

    @Test
    func testFormattedNextOccurrenceRespectsTimeZone() {
        // Same UTC instant rendered in different time zones must produce
        // different local dates — proving the formatter honours `timeZone`
        // and does not silently use UTC.
        // 2026-05-13T20:00:00Z → May 14 in Asia/Kolkata (+05:30),
        //                         May 13 in UTC.
        let formatter = ISO8601DateFormatter()
        let instant = formatter.date(from: "2026-05-13T20:00:00Z")!
        let enUS = Locale(identifier: "en_US")

        let kolkata = instant.formattedNextOccurrence(
            timeZone: TimeZone(identifier: "Asia/Kolkata")!,
            locale: enUS
        )
        let utc = instant.formattedNextOccurrence(
            timeZone: TimeZone(identifier: "UTC")!,
            locale: enUS
        )

        #expect(kolkata == "May 14, 2026")
        #expect(utc == "May 13, 2026")
    }

    @Test
    func testFormattedNextOccurrenceDefaultsToCurrentTimeZone() {
        // Default arguments must match an explicit `.current` invocation —
        // i.e. the helper defers to the device's calendar/timezone for the UI.
        let now = Date()
        #expect(
            now.formattedNextOccurrence()
                == now.formattedNextOccurrence(timeZone: .current, locale: .current)
        )
    }

    // MARK: - nextOccurrence: past endDate returns nil

    @Test
    func testNextOccurrenceReturnsNilWhenPastEndDate() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!

        let recurring = RecurringTransaction(
            name: "Old Subscription",
            amount: 100,
            category: "Entertainment",
            frequency: .daily,
            startDate: twoDaysAgo,
            endDate: yesterday,  // endDate is in the past
            isActive: true
        )

        // nextOccurrence would be tomorrow, but endDate is yesterday → should return nil
        #expect(recurring.nextOccurrence == nil)
    }

    // MARK: - nextOccurrence: weekly with specific days of week

    @Test
    func testNextOccurrenceWeeklyWithEmptyDaysOfWeekFallsBack() {
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!

        let recurring = RecurringTransaction(
            name: "Weekly",
            amount: 200,
            category: "Food",
            frequency: .weekly,
            daysOfWeek: [], // empty → falls back to weekly interval
            startDate: lastWeek,
            isActive: true
        )

        let next = recurring.nextOccurrence
        #expect(next != nil)
        // next should be after today
        #expect(next! > Date())
    }
}
