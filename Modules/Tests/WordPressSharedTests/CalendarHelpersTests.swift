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

    @Test(arguments: 1...7)
    func weekdayIndexRoundTripIsIdentity(firstWeekday: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday

        for index in 0..<7 {
            let unlocalized = calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: index)
            #expect(calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: unlocalized) == index)

            let localized = calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: index)
            #expect(calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: localized) == index)
        }
    }

    @Test(arguments: 1...7)
    func weekdayIndicesStayWithinAWeek(firstWeekday: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = firstWeekday

        for index in 0..<7 {
            #expect((0..<7).contains(calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: index)))
            #expect((0..<7).contains(calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: index)))
        }
    }

    @Test func weekdayIndicesWhenWeekStartsOnSaturday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 7 // Saturday

        // Localized 0 is Saturday, index 6 in the Sunday-based scheme.
        #expect(calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: 0) == 6)
        // Localized 1 is Sunday, which wraps to index 0.
        #expect(calendar.unlocalizedWeekdayIndex(localizedWeekdayIndex: 1) == 0)
        // Saturday (unlocalized 6) is the first day of the week, localized 0.
        #expect(calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: 6) == 0)
        // Sunday (unlocalized 0) is the second day, localized 1.
        #expect(calendar.localizedWeekdayIndex(unlocalizedWeekdayIndex: 0) == 1)
    }

    @Test(arguments: [1, 30, 365])
    func daysElapsedCountsSpansAcrossBoundaries(daysAgo: Int) {
        let calendar = Calendar.current
        let past = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        #expect(calendar.daysElapsedSinceDate(past) == daysAgo)
    }

    @Test func daysElapsedIsNegativeForFutureDates() {
        let calendar = Calendar.current
        let inThreeDays = calendar.date(byAdding: .day, value: 3, to: Date())!
        #expect(calendar.daysElapsedSinceDate(inThreeDays) == -3)
    }

    @Test func daysElapsedIgnoresTimeOfDay() {
        let calendar = Calendar.current
        let sameDay = calendar.date(byAdding: .day, value: -10, to: Date())!
        // Two different times on the same calendar day yield the same whole-day
        // count -- the time component is normalized away. Mid-day times avoid the
        // midnight boundary, where normalizedDate() can round to an adjacent day.
        let morning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: sameDay)!
        let evening = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: sameDay)!
        #expect(calendar.daysElapsedSinceDate(morning) == calendar.daysElapsedSinceDate(evening))
    }
}
