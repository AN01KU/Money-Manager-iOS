import Foundation
import Testing
@testable import Money_Manager

struct CalendarDatesTests {

    // MARK: - monthInterval

    @Test func monthInterval_leapFeb2024_startsOnFeb1() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2024, month: 2, day: 15))!
        let interval = cal.monthInterval(for: date)
        let comps = cal.dateComponents([.year, .month, .day], from: interval.start)
        #expect(comps.year == 2024)
        #expect(comps.month == 2)
        #expect(comps.day == 1)
    }

    @Test func monthInterval_leapFeb2024_endsOnMar1() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2024, month: 2, day: 15))!
        let interval = cal.monthInterval(for: date)
        let comps = cal.dateComponents([.year, .month, .day], from: interval.end)
        #expect(comps.year == 2024)
        #expect(comps.month == 3)
        #expect(comps.day == 1)
    }

    @Test func monthInterval_leapFeb2024_spans29Days() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2024, month: 2, day: 15))!
        let interval = cal.monthInterval(for: date)
        let days = cal.dateComponents([.day], from: interval.start, to: interval.end).day!
        #expect(days == 29)
    }

    @Test func monthInterval_dstMarch_newYork_startsMidnight() {
        // America/New_York springs forward on the second Sunday of March.
        // The month interval must still start at local midnight on Mar 1.
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let date = cal.date(from: DateComponents(year: 2024, month: 3, day: 15))!
        let interval = cal.monthInterval(for: date)
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: interval.start)
        #expect(comps.month == 3)
        #expect(comps.day == 1)
        #expect(comps.hour == 0)
        #expect(comps.minute == 0)
    }

    @Test func monthInterval_yearWrap_december_endsJan1() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2024, month: 12, day: 15))!
        let interval = cal.monthInterval(for: date)
        let comps = cal.dateComponents([.year, .month, .day], from: interval.end)
        #expect(comps.year == 2025)
        #expect(comps.month == 1)
        #expect(comps.day == 1)
    }

    @Test func monthInterval_containsDate() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let interval = cal.monthInterval(for: date)
        #expect(interval.contains(date))
    }

    // MARK: - dayInterval

    @Test func dayInterval_startsAtMidnight() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2025, month: 5, day: 10, hour: 14, minute: 30))!
        let interval = cal.dayInterval(for: date)
        let comps = cal.dateComponents([.hour, .minute, .second], from: interval.start)
        #expect(comps.hour == 0)
        #expect(comps.minute == 0)
        #expect(comps.second == 0)
    }

    @Test func dayInterval_spans24Hours() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2025, month: 5, day: 10, hour: 14))!
        let interval = cal.dayInterval(for: date)
        #expect(interval.duration == 24 * 3600)
    }

    @Test func dayInterval_containsDate() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: DateComponents(year: 2025, month: 5, day: 10, hour: 14))!
        let interval = cal.dayInterval(for: date)
        #expect(interval.contains(date))
    }
}
