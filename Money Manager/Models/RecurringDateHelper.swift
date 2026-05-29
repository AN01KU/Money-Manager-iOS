import Foundation

extension RecurringTransaction {
    var nextOccurrence: Date? {
        guard isActive else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var nextDate = calendar.startOfDay(for: startDate)
        
        switch frequency {
        case .daily:
            while nextDate <= today {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }

        case .weekly:
            guard let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty else {
                while nextDate <= today {
                    nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
                }
                return nextDate
            }

            while nextDate <= today {
                let weekday = calendar.component(.weekday, from: nextDate)
                let adjustedWeekday = weekday - 1

                if daysOfWeek.contains(adjustedWeekday) && nextDate > today {
                    break
                }
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }

        case .monthly:
            guard let dayOfMonth = dayOfMonth else {
                while nextDate <= today {
                    nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
                }
                return nextDate
            }

            while nextDate <= today {
                var components = calendar.dateComponents([.year, .month], from: nextDate)
                components.day = min(dayOfMonth, 28)

                if let nextMonth = calendar.date(from: components),
                   let nextWithDay = calendar.date(byAdding: .month, value: 1, to: nextMonth) {
                    nextDate = nextWithDay
                } else {
                    nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
                }
            }

        case .yearly:
            while nextDate <= today {
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            }
        }
        
        if let endDate = endDate, nextDate > endDate {
            return nil
        }
        
        return nextDate
    }
    
    var lastOccurrence: Date? {
        return lastAddedDate ?? startDate
    }
}

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Formatted label for a recurring transaction's next occurrence date.
    ///
    /// Defaults to the device's current time zone and locale so the displayed
    /// day matches what the user sees on their clock — the backend already
    /// emits `next_occurrence` in the user's timezone, so we must not double
    /// shift by formatting in UTC. The arguments are exposed so unit tests
    /// can pin a fixed timezone fixture.
    func formattedNextOccurrence(
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        formatted(
            Date.FormatStyle(
                date: .abbreviated,
                time: .omitted,
                locale: locale,
                timeZone: timeZone
            )
        )
    }
}
