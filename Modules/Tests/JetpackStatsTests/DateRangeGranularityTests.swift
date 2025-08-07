import Testing
import Foundation
@testable import JetpackStats

@Suite
struct DateRangeGranularityTests {
    let calendar = Calendar.mock(timeZone: .eastern)

    @Test("Determined period for 1 day or less returns hour granularity")
    func granularityForLessThanOneDay() {
        // Same day (1 day exclusive upper bound)
        let singleDay = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-02T00:00:00-03:00")
        )
        #expect(singleDay.preferredGranularity == .hour)
    }

    @Test("Determined period for 2+ days returns day granularity")
    func granularityForDays() {
        // 2 days
        let twoDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-03T00:00:00-03:00")
        )
        #expect(twoDays.preferredGranularity == .day)

        // 3 days
        let threeDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-04T00:00:00-03:00")
        )
        #expect(threeDays.preferredGranularity == .day)

        // 7 days
        let sevenDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-08T00:00:00-03:00")
        )
        #expect(sevenDays.preferredGranularity == .day)

        // 15 days
        let fifteenDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-16T00:00:00-03:00")
        )
        #expect(fifteenDays.preferredGranularity == .day)

        // 31 days (full month)
        let fullMonth = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-02-01T00:00:00-03:00")
        )
        #expect(fullMonth.preferredGranularity == .day)

        // 90 days
        let ninetyDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-03-31T00:00:00-03:00")
        )
        #expect(ninetyDays.preferredGranularity == .day)
    }

    @Test("Determined period for 91+ days returns month granularity")
    func granularityForMonths() {
        // 91 days
        let ninetyOneDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-04-01T00:00:00-03:00")
        )
        #expect(ninetyOneDays.preferredGranularity == .month)

        // ~181 days (6 months)
        let sixMonths = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-07-01T00:00:00-03:00")
        )
        #expect(sixMonths.preferredGranularity == .month)

        // 366 days (leap year)
        let leapYear = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2025-01-01T00:00:00-03:00")
        )
        #expect(leapYear.preferredGranularity == .month)

        // 730 days (2 years)
        let twoYears = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2025-12-31T00:00:00-03:00")
        )
        #expect(twoYears.preferredGranularity == .month)
    }

    @Test("Determined period for 25+ months returns year granularity")
    func granularityForYears() {
        // 25 months (just over 2 years)
        let twentyFiveMonths = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2026-02-02T00:00:00-03:00")
        )
        #expect(twentyFiveMonths.preferredGranularity == .month)

        // 3 years
        let threeYears = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2027-01-02T00:00:00-03:00")
        )
        #expect(threeYears.preferredGranularity == .month)

        // 5 years
        let fiveYears = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2029-01-02T00:00:00-03:00")
        )
        #expect(fiveYears.preferredGranularity == .year)
    }

    @Test("Granularity respects transitions at 14 and 90 day boundaries")
    func granularityBoundaryTransitions() {
        // Single day - should be hour
        let singleDay = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-02T00:00:00-03:00")
        )
        #expect(singleDay.preferredGranularity == .hour)

        // 14 days - should be day
        let fourteenDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-15T00:00:00-03:00")
        )
        #expect(fourteenDays.preferredGranularity == .day)

        // 15 days - should be day
        let fifteenDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-01-16T00:00:00-03:00")
        )
        #expect(fifteenDays.preferredGranularity == .day)

        // 90 days - should be day
        let ninetyDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-03-31T00:00:00-03:00")
        )
        #expect(ninetyDays.preferredGranularity == .day)

        // 91 days - should be month
        let ninetyOneDays = DateInterval(
            start: Date("2024-01-01T00:00:00-03:00"),
            end: Date("2024-04-01T00:00:00-03:00")
        )
        #expect(ninetyOneDays.preferredGranularity == .month)
    }

    @Test("Granularity for preset ranges matches expected values")
    func granularityForPresets() {
        // Today - should be hour (single day)
        #expect(calendar.makeDateInterval(for: .today).preferredGranularity == .hour)

        // Yesterday - should be hour (single day)
        #expect(calendar.makeDateInterval(for: .today).preferredGranularity == .hour)

        // Last 7 days - should be day
        #expect(calendar.makeDateInterval(for: .last7Days).preferredGranularity == .day)

        // Last 30 days - should be day
        #expect(calendar.makeDateInterval(for: .last30Days).preferredGranularity == .day)

        // Last 12 months - should be month
        #expect(calendar.makeDateInterval(for: .last12Months).preferredGranularity == .month)
    }
}
