import Testing
import Foundation
@testable import JetpackStats

@Suite
struct DataPointTests {
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

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData
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

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData
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

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData
        )

        // THEN
        #expect(mappedData.isEmpty)
    }

    @Test("Maps with mismatched array lengths, aligned from the end")
    func testMapMismatchedArrayLengths() {
        // GIVEN - current has 6 items, previous has 5 items
        let currentData = [
            DataPoint(date: Date("2025-01-08T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-09T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-10T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-11T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-12T00:00:00-03:00"), value: 0),
            DataPoint(date: Date("2025-01-13T00:00:00-03:00"), value: 0)
        ]

        let previousData = [
            DataPoint(date: Date("2025-01-01T00:00:00-03:00"), value: 100),
            DataPoint(date: Date("2025-01-02T00:00:00-03:00"), value: 200),
            DataPoint(date: Date("2025-01-03T00:00:00-03:00"), value: 300),
            DataPoint(date: Date("2025-01-04T00:00:00-03:00"), value: 400),
            DataPoint(date: Date("2025-01-05T00:00:00-03:00"), value: 500)
        ]

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData
        )

        // THEN - should have 5 items (min count), aligned from the end
        // current[1..5] paired with previous[0..4]
        #expect(mappedData.count == 5)
        #expect(mappedData[0].date == Date("2025-01-09T00:00:00-03:00"))
        #expect(mappedData[0].value == 100)
        #expect(mappedData[1].date == Date("2025-01-10T00:00:00-03:00"))
        #expect(mappedData[1].value == 200)
        #expect(mappedData[4].date == Date("2025-01-13T00:00:00-03:00"))
        #expect(mappedData[4].value == 500)
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

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData
        )

        // THEN
        #expect(mappedData.count == 2)
        #expect(mappedData[0].date == Date("2025-01-01T00:00:00-03:00"))
        #expect(mappedData[0].value == 1000)
        #expect(mappedData[1].date == Date("2025-01-07T00:00:00-03:00"))
        #expect(mappedData[1].value == 2000)
    }

    @Test("Maps previous week data to current week")
    func testMapPreviousWeekDataToCurrent() {
        // GIVEN
        let currentData = [
            DataPoint(date: Date("2025-11-17T05:00:00+00:00"), value: 0),
            DataPoint(date: Date("2025-11-24T05:00:00+00:00"), value: 0),
            DataPoint(date: Date("2025-12-01T05:00:00+00:00"), value: 0),
            DataPoint(date: Date("2025-12-08T05:00:00+00:00"), value: 0),
            DataPoint(date: Date("2025-12-15T05:00:00+00:00"), value: 0)
        ]

        let previousData = [
            DataPoint(date: Date("2025-10-20T04:00:00+00:00"), value: 3),
            DataPoint(date: Date("2025-10-27T04:00:00+00:00"), value: 5),
            DataPoint(date: Date("2025-11-03T05:00:00+00:00"), value: 0),
            DataPoint(date: Date("2025-11-10T05:00:00+00:00"), value: 0),
            DataPoint(date: Date("2025-11-17T05:00:00+00:00"), value: 1)
        ]

        // WHEN
        let mappedData = DataPoint.mapDataPoints(
            currentData: currentData,
            previousData: previousData
        )

        // THEN
        #expect(mappedData.count == 5)
        #expect(mappedData[0].date == Date("2025-11-17T05:00:00+00:00"))
        #expect(mappedData[0].value == 3)
        #expect(mappedData[1].date == Date("2025-11-24T05:00:00+00:00"))
        #expect(mappedData[1].value == 5)
        #expect(mappedData[2].date == Date("2025-12-01T05:00:00+00:00"))
        #expect(mappedData[2].value == 0)
        #expect(mappedData[3].date == Date("2025-12-08T05:00:00+00:00"))
        #expect(mappedData[3].value == 0)
        #expect(mappedData[4].date == Date("2025-12-15T05:00:00+00:00"))
        #expect(mappedData[4].value == 1)
    }
}
