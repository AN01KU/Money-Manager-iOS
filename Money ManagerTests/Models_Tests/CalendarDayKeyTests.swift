import Foundation
import Testing
@testable import Money_Manager

struct CalendarDayKeyTests {

    @Test func testDayKeyForTodayReturnsToday() {
        let key = Calendar.current.dayKey(for: Date())
        #expect(key == "TODAY")
    }

    @Test func testDayKeyForYesterdayIsNotToday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let key = Calendar.current.dayKey(for: yesterday)
        #expect(key != "TODAY")
    }

    @Test func testDayKeyForPastDateIsUppercased() {
        let past = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let key = Calendar.current.dayKey(for: past)
        #expect(key == key.uppercased())
    }

    @Test func testDayKeyContainsMonthAndDayForPastDate() {
        let past = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let key = Calendar.current.dayKey(for: past)
        // The formatted output includes month name and day number
        #expect(key.contains("15"))
        #expect(key != "TODAY")
    }

    @Test func testDayKeyForTomorrowIsNotToday() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let key = Calendar.current.dayKey(for: tomorrow)
        #expect(key != "TODAY")
    }

    @Test func testDayKeyIsDeterministicForSameDate() {
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 20))!
        let key1 = Calendar.current.dayKey(for: date)
        let key2 = Calendar.current.dayKey(for: date)
        #expect(key1 == key2)
    }
}
