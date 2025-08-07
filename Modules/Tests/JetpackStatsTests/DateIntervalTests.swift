import Testing
import Foundation
@testable import JetpackStats

@Suite
struct DateIntervalTests {
    let calendar = Calendar.mock(timeZone: .eastern)

    @Test("DateInterval assumptions")
    func assumptions() throws {
        // GIVEN
        let timeZone = try #require(TimeZone(secondsFromGMT: -10800)) // -3 hours

        var calendar = Calendar.current
        calendar.timeZone = timeZone

        // WHEN
        var interval = try #require(calendar.dateInterval(of: .day, for: Date("2025-01-15T14:30:00-03:00")))

        // THEN the beginning is the beginnig of the given day
        #expect(interval.start == Date("2025-01-15T00:00:00-03:00"))

        // THEN the end is the beginning of the next day
        #expect(interval.end == Date("2025-01-16T00:00:00-03:00"))

        // THEN the interval technically contains the date with "2025-01-16" date
        #expect(interval.contains(Date("2025-01-16T00:00:00-03:00")))

        // GIVEN
        let formatter = DateIntervalFormatter()
        formatter.timeZone = timeZone
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_us")

        // THEN `DateIntervalFormatter` is fundamentally designed to represent time ranges
        #expect(formatter.string(from: interval) == "1/15/25, 12:00 AM – 1/16/25, 12:00 AM")

        // WHEN
        formatter.timeStyle = .none

        // THEN date without time may appear off
        #expect(formatter.string(from: interval) == "1/15/25 – 1/16/25")

        // WHEN date is adjusted
        interval.end = try #require(calendar.date(byAdding: .second, value: -1, to: interval.end))

        // THEN the formatting matches what the user would expect
        #expect(formatter.string(from: interval) == "1/15/25")
    }
}
