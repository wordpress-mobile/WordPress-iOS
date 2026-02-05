import Testing
import Foundation
@testable import JetpackStats

@Suite
struct DataPointTests {
    private let calendar = Calendar.mock()

    @Test("Maps previous data to current period with simple day offset")
    func testMapPreviousDataToCurrentSimpleDayOffset() {
        // GIVEN
        let currentData = [
            DataPoint(date: Date("2025-01-08T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-09T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-10T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-11T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-12T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-13T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-14T00:00:00-03:00"), value: 0)
        ]

        let previousData = [
            DataPoint(date: Date("2025-01-01T00:00:00-03:00"), value: 100),
            DataPoint(date: Date("2025-01-02T00:00:00-03:00"), value: 200),
            DataPoint(date: Date("2025-01-03T00:00:00-03:00"), value: 300),
            DataPoint(date: Date("2025-01-04T00:00:00-03:00"), value: 400),
            DataPoint(date: Date("2025-01-05T00:00:00-03:00"), value: 500),
            DataPoint(date: Date("2025-01-06T00:00:00-03:00"), value: 600),
            DataPoint(date: Date("2025-01-07T00:00:00-03:00"), value: 700)
        ]

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-08T00:00:00-03:00"),
                end: Date("2025-01-15T00:00:00-03:00")
            ),
            component: .day,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN
        #expect(mappedData.count == 7)
        #expect(mappedData[0].date == Date("2025-01-08T00:00:00-03:00"))
        #expect(mappedData[0].value == 100)
        #expect(mappedData[1].date == Date("2025-01-09T00:00:00-03:00"))
        #expect(mappedData[1].value == 200)
        #expect(mappedData[6].date == Date("2025-01-14T00:00:00-03:00"))
        #expect(mappedData[6].value == 700)
    }

    @Test("Maps previous month data to current month")
    func testMapPreviousMonthDataToCurrent() {
        // GIVEN
        let currentData = [
            DataPoint(date: Date("2025-01-01T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-15T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-31T00:00:00-03:00"), value: 0)
        ]

        let previousData = [
            DataPoint(date: Date("2024-12-01T00:00:00-03:00"), value: 1000),
            DataPoint(date: Date("2024-12-15T00:00:00-03:00"), value: 2000),
            DataPoint(date: Date("2024-12-31T00:00:00-03:00"), value: 3000)
        ]

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-01T00:00:00-03:00"),
                end: Date("2025-02-01T00:00:00-03:00")
            ),
            component: .month,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN
        #expect(mappedData.count == 3)
        #expect(mappedData[0].date == Date("2025-01-01T00:00:00-03:00"))
        #expect(mappedData[0].value == 1000)
        #expect(mappedData[1].date == Date("2025-01-15T00:00:00-03:00"))
        #expect(mappedData[1].value == 2000)
        #expect(mappedData[2].date == Date("2025-01-31T00:00:00-03:00"))
        #expect(mappedData[2].value == 3000)
    }

    @Test("Maps with empty previous data")
    func testMapEmptyPreviousData() {
        // GIVEN
        let currentData = [
            DataPoint(date: Date("2025-01-08T00:00:00-03:00"), value: 100),
            DataPoint(date: Date("2025-01-09T00:00:00-03:00"), value: 200),
            DataPoint(date: Date("2025-01-10T00:00:00-03:00"), value: 300)
        ]
        let previousData: [DataPoint] = []

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-08T00:00:00-03:00"),
                end: Date("2025-01-11T00:00:00-03:00")
            ),
            component: .day,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN
        #expect(mappedData.isEmpty)
    }

    @Test("Maps all previous data even when current data is partial (today scenario)")
    func testMapPartialCurrentDataPreservesAllPreviousData() {
        // GIVEN - "Today" at 10 AM scenario
        // Current period has only 10 hours (00:00 to 09:00)
        // Previous period has full 24 hours
        let currentData = [
            DataPoint(date: Date("2025-01-15T00:00:00-03:00"), value: 1),
            DataPoint(date: Date("2025-01-15T01:00:00-03:00"), value: 2),
            DataPoint(date: Date("2025-01-15T02:00:00-03:00"), value: 3),
            DataPoint(date: Date("2025-01-15T03:00:00-03:00"), value: 4),
            DataPoint(date: Date("2025-01-15T04:00:00-03:00"), value: 5),
            DataPoint(date: Date("2025-01-15T05:00:00-03:00"), value: 6),
            DataPoint(date: Date("2025-01-15T06:00:00-03:00"), value: 7),
            DataPoint(date: Date("2025-01-15T07:00:00-03:00"), value: 8),
            DataPoint(date: Date("2025-01-15T08:00:00-03:00"), value: 9),
            DataPoint(date: Date("2025-01-15T09:00:00-03:00"), value: 10)
        ]

        let previousData = [
            DataPoint(date: Date("2025-01-14T00:00:00-03:00"), value: 100),
            DataPoint(date: Date("2025-01-14T01:00:00-03:00"), value: 101),
            DataPoint(date: Date("2025-01-14T02:00:00-03:00"), value: 102),
            DataPoint(date: Date("2025-01-14T03:00:00-03:00"), value: 103),
            DataPoint(date: Date("2025-01-14T04:00:00-03:00"), value: 104),
            DataPoint(date: Date("2025-01-14T05:00:00-03:00"), value: 105),
            DataPoint(date: Date("2025-01-14T06:00:00-03:00"), value: 106),
            DataPoint(date: Date("2025-01-14T07:00:00-03:00"), value: 107),
            DataPoint(date: Date("2025-01-14T08:00:00-03:00"), value: 108),
            DataPoint(date: Date("2025-01-14T09:00:00-03:00"), value: 109),
            DataPoint(date: Date("2025-01-14T10:00:00-03:00"), value: 110),
            DataPoint(date: Date("2025-01-14T11:00:00-03:00"), value: 111),
            DataPoint(date: Date("2025-01-14T12:00:00-03:00"), value: 112),
            DataPoint(date: Date("2025-01-14T13:00:00-03:00"), value: 113),
            DataPoint(date: Date("2025-01-14T14:00:00-03:00"), value: 114),
            DataPoint(date: Date("2025-01-14T15:00:00-03:00"), value: 115),
            DataPoint(date: Date("2025-01-14T16:00:00-03:00"), value: 116),
            DataPoint(date: Date("2025-01-14T17:00:00-03:00"), value: 117),
            DataPoint(date: Date("2025-01-14T18:00:00-03:00"), value: 118),
            DataPoint(date: Date("2025-01-14T19:00:00-03:00"), value: 119),
            DataPoint(date: Date("2025-01-14T20:00:00-03:00"), value: 120),
            DataPoint(date: Date("2025-01-14T21:00:00-03:00"), value: 121),
            DataPoint(date: Date("2025-01-14T22:00:00-03:00"), value: 122),
            DataPoint(date: Date("2025-01-14T23:00:00-03:00"), value: 123)
        ]

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-15T00:00:00-03:00"),
                end: Date("2025-01-16T00:00:00-03:00")
            ),
            component: .hour,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN - All 24 previous data points should be preserved and mapped to current period dates
        #expect(mappedData.count == 24, "All previous data points should be preserved")
        #expect(mappedData[0].date == Date("2025-01-15T00:00:00-03:00"))
        #expect(mappedData[0].value == 100)
        #expect(mappedData[9].date == Date("2025-01-15T09:00:00-03:00"))
        #expect(mappedData[9].value == 109)
        #expect(mappedData[10].date == Date("2025-01-15T10:00:00-03:00"), "Hour 10 should be mapped")
        #expect(mappedData[10].value == 110, "Hour 10 should have previous value")
        #expect(mappedData[23].date == Date("2025-01-15T23:00:00-03:00"))
        #expect(mappedData[23].value == 123)
    }

    @Test("Maps year-over-year comparison")
    func testMapYearOverYearComparison() {
        // GIVEN
        let currentData = [
            DataPoint(date: Date("2025-01-01T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-07T00:00:00-03:00"), value: 0)
        ]

        let previousData = [
            DataPoint(date: Date("2024-01-01T00:00:00-03:00"), value: 1000),
            DataPoint(date: Date("2024-01-07T00:00:00-03:00"), value: 2000)
        ]

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-01T00:00:00-03:00"),
                end: Date("2025-01-08T00:00:00-03:00")
            ),
            component: .day,
            comparison: .samePeriodLastYear,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN
        #expect(mappedData.count == 2)
        #expect(mappedData[0].date == Date("2025-01-01T00:00:00-03:00"))
        #expect(mappedData[0].value == 1000)
        #expect(mappedData[1].date == Date("2025-01-07T00:00:00-03:00"))
        #expect(mappedData[1].value == 2000)
    }

    @Test("Maps previous month data to current month filtering data beyond period")
    func testMapPreviousWeekDataToCurrent() {
        // GIVEN - February 2026 (Feb 1 - Mar 1) has 4 weeks
        // Previous period (Jan 4 - Feb 1) has 4 weeks
        // We'll use 5 data points where the last one falls beyond Feb when mapped
        // Current period: February 2026 (4 weeks: Feb 1, 8, 15, 22)
        let currentData = [
            DataPoint(date: Date("2026-02-01T00:00:00-03:00"), value: 10),
            DataPoint(date: Date("2026-02-08T00:00:00-03:00"), value: 20),
            DataPoint(date: Date("2026-02-15T00:00:00-03:00"), value: 30),
            DataPoint(date: Date("2026-02-22T00:00:00-03:00"), value: 40)
        ]

        // Previous period has 4 data points that fit, plus 1 that doesn't
        // Test that the 5th point which falls beyond Feb when mapped gets filtered
        let previousData = [
            DataPoint(date: Date("2026-01-04T00:00:00-03:00"), value: 100),
            DataPoint(date: Date("2026-01-11T00:00:00-03:00"), value: 200),
            DataPoint(date: Date("2026-01-18T00:00:00-03:00"), value: 300),
            DataPoint(date: Date("2026-01-25T00:00:00-03:00"), value: 400),
            DataPoint(date: Date("2026-02-02T00:00:00-03:00"), value: 500)  // Beyond effectiveComparisonInterval, will map beyond Mar
        ]

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2026-02-01T00:00:00-03:00"),
                end: Date("2026-03-01T00:00:00-03:00")
            ),
            component: .weekOfYear,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN - Only 4 weeks should be included (5th point filtered out as it maps beyond Feb)
        #expect(mappedData.count == 4, "5th data point should be filtered out")
        #expect(mappedData[0].date == Date("2026-02-01T00:00:00-03:00"))
        #expect(mappedData[0].value == 100)
        #expect(mappedData[1].date == Date("2026-02-08T00:00:00-03:00"))
        #expect(mappedData[1].value == 200)
        #expect(mappedData[2].date == Date("2026-02-15T00:00:00-03:00"))
        #expect(mappedData[2].value == 300)
        #expect(mappedData[3].date == Date("2026-02-22T00:00:00-03:00"))
        #expect(mappedData[3].value == 400)
    }

    @Test("Maps with empty current data")
    func testMapWithEmptyCurrentData() {
        // GIVEN - No current data yet (e.g., viewing "Today" at midnight)
        let currentData: [DataPoint] = []

        let previousData = [
            DataPoint(date: Date("2025-01-14T00:00:00-03:00"), value: 100),
            DataPoint(date: Date("2025-01-14T01:00:00-03:00"), value: 101),
            DataPoint(date: Date("2025-01-14T02:00:00-03:00"), value: 102)
        ]

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-15T00:00:00-03:00"),
                end: Date("2025-01-16T00:00:00-03:00")
            ),
            component: .hour,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN - Previous data should still be mapped to current period
        #expect(mappedData.count == 3)
        #expect(mappedData[0].date == Date("2025-01-15T00:00:00-03:00"))
        #expect(mappedData[0].value == 100)
        #expect(mappedData[1].date == Date("2025-01-15T01:00:00-03:00"))
        #expect(mappedData[1].value == 101)
        #expect(mappedData[2].date == Date("2025-01-15T02:00:00-03:00"))
        #expect(mappedData[2].value == 102)
    }

    @Test("Maps weeks with more previous data than current")
    func testMapWeeksWithMorePreviousData() {
        // GIVEN - Current week has 3 days of data, previous week has full 7 days
        let currentData = [
            DataPoint(date: Date("2025-01-20T00:00:00-03:00"), value: 1),
            DataPoint(date: Date("2025-01-21T00:00:00-03:00"), value: 2),
            DataPoint(date: Date("2025-01-22T00:00:00-03:00"), value: 3)
        ]

        let previousData = [
            DataPoint(date: Date("2025-01-13T00:00:00-03:00"), value: 10),
            DataPoint(date: Date("2025-01-14T00:00:00-03:00"), value: 20),
            DataPoint(date: Date("2025-01-15T00:00:00-03:00"), value: 30),
            DataPoint(date: Date("2025-01-16T00:00:00-03:00"), value: 40),
            DataPoint(date: Date("2025-01-17T00:00:00-03:00"), value: 50),
            DataPoint(date: Date("2025-01-18T00:00:00-03:00"), value: 60),
            DataPoint(date: Date("2025-01-19T00:00:00-03:00"), value: 70)
        ]

        let dateRange = StatsDateRange(
            interval: DateInterval(
                start: Date("2025-01-20T00:00:00-03:00"),
                end: Date("2025-01-27T00:00:00-03:00")
            ),
            component: .day,
            calendar: calendar
        )

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData,
            dateRange: dateRange
        )

        // THEN - All 7 previous data points should be preserved
        #expect(mappedData.count == 7, "All 7 previous data points should be preserved")
        #expect(mappedData[0].date == Date("2025-01-20T00:00:00-03:00"))
        #expect(mappedData[0].value == 10)
        #expect(mappedData[3].date == Date("2025-01-23T00:00:00-03:00"))
        #expect(mappedData[3].value == 40)
        #expect(mappedData[6].date == Date("2025-01-26T00:00:00-03:00"))
        #expect(mappedData[6].value == 70)
    }

}
