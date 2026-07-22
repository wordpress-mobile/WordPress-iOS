import Foundation
import Testing
import WordPressShared

struct CalendarHelpersTests {
    @Test func weekdayIndicesAreIdentityWhenWeekStartsOnSunday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1 // Sunday

        for index in 0..<7 {
            #expect(calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: index) == index)
            #expect(calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: index) == index)
        }
    }

    @Test func weekdayIndicesShiftWhenWeekStartsOnMonday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday

        // Localized 0 is Monday, which is index 1 in the Sunday-based scheme.
        #expect(calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: 0) == 1)
        // Localized 6 is Sunday, which is index 0.
        #expect(calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: 6) == 0)
        // The inverse: Sunday (unlocalized 0) is the last day, localized 6.
        #expect(calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: 0) == 6)
        // Monday (unlocalized 1) is the first day, localized 0.
        #expect(calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: 1) == 0)
    }

    @Test func daysElapsedCountsWholeCalendarDays() {
        let calendar = Calendar.current
        let today = Date()
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!

        #expect(calendar.daysElapsedSinceDate(fiveDaysAgo) == 5)
        #expect(calendar.daysElapsedSinceDate(today) == 0)
    }
}
