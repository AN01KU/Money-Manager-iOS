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
        let pastDate = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())!

        let expense = RecurringTransaction(
            name: "Weekly Gym",
            amount: 500,
            category: "Health",
            frequency: .weekly,
            startDate: pastDate
        )

        let next = expense.nextOccurrence
        #expect(next != nil)
        #expect(next! > Date())
    }
    
    @Test
    func testNextOccurrenceForMonthlyFrequency() {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        
        let expense = RecurringTransaction(
            name: "Rent",
            amount: 15000,
            category: "Housing",
            frequency: .monthly,
            dayOfMonth: 1,
            startDate: lastMonth
        )
        
        let next = expense.nextOccurrence
        #expect(next != nil)
    }
    
    @Test
    func testNextOccurrenceForMonthlyWithoutDayOfMonth() {
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        
        let expense = RecurringTransaction(
            name: "Subscription",
            amount: 100,
            category: "Entertainment",
            frequency: .monthly,
            startDate: lastMonth
        )
        
        let next = expense.nextOccurrence
        #expect(next != nil)
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
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let yesterdayString = yesterday.relativeString
        let tomorrowString = tomorrow.relativeString
        
        #expect(yesterdayString.contains("day") || yesterdayString.contains("ago"))
        #expect(tomorrowString.contains("day") || tomorrowString.contains("in"))
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
