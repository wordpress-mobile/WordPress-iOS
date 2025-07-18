import Testing
import Foundation
@testable import JetpackStats

@Suite
struct StatsDateFormatterTests {
    let formatter = StatsDateFormatter(
        locale: Locale(identifier: "en_us"),
        timeZone: .eastern
    )

    @Test func hourFormatting() {
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

    @Test func dayFormatting() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .day)
        #expect(result == "Mar 15")
    }

    @Test func monthFormatting() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .month)
        #expect(result == "Mar")
    }

    @Test func yearFormatting() {
        let date = Date("2025-03-15T14:00:00-03:00")
        let result = formatter.formatDate(date, granularity: .year)
        #expect(result == "2025")
    }
}
