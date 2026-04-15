import Foundation

extension Calendar {
    /// Returns a display key for a date's day: "TODAY" or the month/day formatted string (uppercased).
    func dayKey(for date: Date) -> String {
        let day = startOfDay(for: date)
        return isDateInToday(day)
            ? "TODAY"
            : day.formatted(.dateTime.month(.wide).day()).uppercased()
    }
}
