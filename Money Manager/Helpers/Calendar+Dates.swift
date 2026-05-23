import Foundation

extension Calendar {
    /// Returns a `DateInterval` spanning the full month containing `date`.
    ///
    /// The interval begins at midnight on the first day of the month and
    /// ends at the last instant before midnight on the first day of the
    /// following month.
    func monthInterval(for date: Date) -> DateInterval {
        let components = dateComponents([.year, .month], from: date)
        let start = self.date(from: components)!
        let end = self.date(byAdding: DateComponents(month: 1), to: start)!
        return DateInterval(start: start, end: end)
    }

    /// Returns a `DateInterval` spanning the full day containing `date`.
    ///
    /// The interval begins at midnight (`startOfDay`) and ends 24 hours later.
    func dayInterval(for date: Date) -> DateInterval {
        let start = startOfDay(for: date)
        let end = self.date(byAdding: .day, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }

    /// Returns a display key for a date's day: "TODAY" or the month/day formatted string (uppercased).
    func dayKey(for date: Date) -> String {
        let day = startOfDay(for: date)
        return isDateInToday(day)
            ? "TODAY"
            : day.formatted(.dateTime.month(.wide).day()).uppercased()
    }
}
