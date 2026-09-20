import Foundation
import Testing

@testable import WordPress

/// "Now" is pinned rather than read from the clock, so the boundaries between
/// buckets can be exercised directly and the results do not drift with the
/// date the suite happens to run on.
@Suite("CustomPostDateGrouper")
struct CustomPostDateGrouperTests {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 2026-09-10 12:00 UTC: mid-month, so "earlier this month" has room on both sides.
    private let now = Self.utc(year: 2026, month: 9, day: 10)

    private func group(of date: Date) -> CustomPostDateGroup {
        CustomPostDateGrouper(now: now, calendar: calendar, locale: Locale(identifier: "en_US")).group(for: date)
    }

    @Test("today is this week")
    func today() {
        #expect(group(of: now) == .thisWeek)
    }

    @Test("six days ago is still this week")
    func sixDaysAgo() {
        #expect(group(of: now.addingTimeInterval(-6 * 86_400)) == .thisWeek)
    }

    @Test("a future date groups with this week rather than falling through")
    func future() {
        #expect(group(of: now.addingTimeInterval(3 * 86_400)) == .thisWeek)
    }

    @Test("eight days ago in the same month is earlier this month")
    func eightDaysAgo() {
        #expect(group(of: now.addingTimeInterval(-8 * 86_400)) == .earlierThisMonth(monthName: "September"))
    }

    @Test("an earlier month in the same year is named without its year")
    func earlierMonthSameYear() {
        #expect(group(of: Self.utc(year: 2026, month: 7, day: 24)) == .month(label: "July"))
    }

    @Test("a month in an earlier year carries its year")
    func earlierYear() {
        #expect(group(of: Self.utc(year: 2025, month: 3, day: 2)) == .month(label: "March 2025"))
    }

    @Test("the same month in an earlier year is not mistaken for this month")
    func sameMonthLastYear() {
        #expect(group(of: Self.utc(year: 2025, month: 9, day: 10)) == .month(label: "September 2025"))
    }

    @Test("the week window crosses a year boundary")
    func yearBoundary() {
        let january = Self.utc(year: 2027, month: 1, day: 3)
        let grouper = CustomPostDateGrouper(now: january, calendar: calendar, locale: Locale(identifier: "en_US"))
        #expect(grouper.group(for: Self.utc(year: 2026, month: 12, day: 30)) == .thisWeek)
        #expect(grouper.group(for: Self.utc(year: 2026, month: 12, day: 20)) == .month(label: "December 2026"))
    }

    @Test("titles read as headers")
    func titles() {
        #expect(CustomPostDateGroup.earlierThisMonth(monthName: "July").localizedTitle == "Earlier in July")
        #expect(CustomPostDateGroup.month(label: "March 2025").localizedTitle == "March 2025")
    }

    private static func utc(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
