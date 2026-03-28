import Foundation

extension RecurringTransaction {
    var nextOccurrence: Date? {
        guard isActive else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var nextDate = calendar.startOfDay(for: startDate)
        
        switch frequency {
        case "daily":
            while nextDate <= today {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }
            
        case "weekly":
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
            
        case "monthly":
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
            
        case "yearly":
            while nextDate <= today {
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
            }
            
        default:
            return nil
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
}
