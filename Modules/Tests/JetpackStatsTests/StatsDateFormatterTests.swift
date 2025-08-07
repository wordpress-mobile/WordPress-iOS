import Testing
import Foundation
@testable import JetpackStats

@Suite
struct StatsDateFormatterTests {
    let formatter = StatsDateFormatter(
        locale: Locale(identifier: "en_us"),
        timeZone: .eastern
    )

    @Test func hourFormattingCompact() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .hour)
        #expect(result == "2 PM")

        let midnight = Date("2025-03-15T00:00:00-03:00")
        let midnightResult = formatter.formatDate(midnight, granularity: .hour)
        #expect(midnightResult == "12 AM")

        let noon = Date("2025-03-15T12:00:00-03:00")
        let noonResult = formatter.formatDate(noon, granularity: .hour)
        #expect(noonResult == "12 PM")
    }

    @Test func hourFormattingRegular() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .hour, context: .regular)
        #expect(result == "2 PM")

        let midnight = Date("2025-03-15T00:00:00-03:00")
        let midnightResult = formatter.formatDate(midnight, granularity: .hour, context: .regular)
        #expect(midnightResult == "12 AM")
    }

    @Test func dayFormattingCompact() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .day)
        #expect(result == "Mar 15")
    }

    @Test func dayFormattingRegular() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .day, context: .regular)
        #expect(result == "Saturday, March 15")
    }

    @Test func monthFormattingCompact() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .month)
        #expect(result == "Mar")
    }

    @Test func monthFormattingRegular() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .month, context: .regular)
        #expect(result == "March 2025")
    }

    @Test func yearFormattingCompact() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .year)
        #expect(result == "2025")
    }

    @Test func yearFormattingRegular() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .year, context: .regular)
        #expect(result == "2025")
    }
}
