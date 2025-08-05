import Testing
import Foundation
@testable import JetpackStats

@Suite
struct DataPointTests {
    let calendar = Calendar.mock(timeZone: .eastern)

    @Test("Maps previous data to current period with simple day offset")
    func testMapPreviousDataToCurrentSimpleDayOffset() {
        // GIVEN
        let previousStart = Date("2025-01-01T00:00:00-03:00")
        let previousEnd = Date("2025-01-08T00:00:00-03:00")
        let previousRange = DateInterval(start: previousStart, end: previousEnd)

        let currentStart = Date("2025-01-08T00:00:00-03:00")
        let currentEnd = Date("2025-01-15T00:00:00-03:00")
        let currentRange = DateInterval(start: currentStart, end: currentEnd)

        let previousData = [
            DataPoint(date: Date("2025-01-01T00:00:00-03:00"), value: 100),
            DataPoint(date: Date("2025-01-02T00:00:00-03:00"), value: 200),
            DataPoint(date: Date("2025-01-03T00:00:00-03:00"), value: 300),
            DataPoint(date: Date("2025-01-04T00:00:00-03:00"), value: 400),
            DataPoint(date: Date("2025-01-05T00:00:00-03:00"), value: 500),
            DataPoint(date: Date("2025-01-06T00:00:00-03:00"), value: 600),
            DataPoint(date: Date("2025-01-07T00:00:00-03:00"), value: 700)
        ]

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            previousData,
            from: previousRange,
            to: currentRange,
            component: .day,
            calendar: calendar
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
        let previousStart = Date("2024-12-01T00:00:00-03:00")
        let previousEnd = Date("2025-01-01T00:00:00-03:00")
        let previousRange = DateInterval(start: previousStart, end: previousEnd)

        let currentStart = Date("2025-01-01T00:00:00-03:00")
        let currentEnd = Date("2025-02-01T00:00:00-03:00")
        let currentRange = DateInterval(start: currentStart, end: currentEnd)

        let previousData = [
            DataPoint(date: Date("2024-12-01T00:00:00-03:00"), value: 1000),
            DataPoint(date: Date("2024-12-15T00:00:00-03:00"), value: 2000),
            DataPoint(date: Date("2024-12-31T00:00:00-03:00"), value: 3000)
        ]

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            previousData,
            from: previousRange,
            to: currentRange,
            component: .month,
            calendar: calendar
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
        let previousRange = DateInterval(
            start: Date("2025-01-01T00:00:00-03:00"),
            end: Date("2025-01-08T00:00:00-03:00")
        )
        let currentRange = DateInterval(
            start: Date("2025-01-08T00:00:00-03:00"),
            end: Date("2025-01-15T00:00:00-03:00")
        )
        let previousData: [DataPoint] = []

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            previousData,
            from: previousRange,
            to: currentRange,
            component: .day,
            calendar: calendar
        )

        // THEN
        #expect(mappedData.isEmpty)
    }

    @Test("Maps year-over-year comparison")
    func testMapYearOverYearComparison() {
        // GIVEN
        let previousStart = Date("2024-01-01T00:00:00-03:00")
        let previousEnd = Date("2024-01-08T00:00:00-03:00")
        let previousRange = DateInterval(start: previousStart, end: previousEnd)

        let currentStart = Date("2025-01-01T00:00:00-03:00")
        let currentEnd = Date("2025-01-08T00:00:00-03:00")
        let currentRange = DateInterval(start: currentStart, end: currentEnd)

        let previousData = [
            DataPoint(date: Date("2024-01-01T00:00:00-03:00"), value: 1000),
            DataPoint(date: Date("2024-01-07T00:00:00-03:00"), value: 2000)
        ]

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            previousData,
            from: previousRange,
            to: currentRange,
            component: .year,
            calendar: calendar
        )

        // THEN
        #expect(mappedData.count == 2)
        #expect(mappedData[0].date == Date("2025-01-01T00:00:00-03:00"))
        #expect(mappedData[0].value == 1000)
        #expect(mappedData[1].date == Date("2025-01-07T00:00:00-03:00"))
        #expect(mappedData[1].value == 2000)
    }
}
