import Testing
import Foundation
@testable import JetpackStats

@Suite
struct StatsDataAggregationTests {
    let calendar = Calendar.mock(timeZone: TimeZone(secondsFromGMT: 0)!)

    @Test
    func hourlyAggregation() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Create test data with multiple values in the same hour
        let date1 = Date("2025-01-15T14:15:00Z")
        let date2 = Date("2025-01-15T14:30:00Z")
        let date3 = Date("2025-01-15T14:45:00Z")
        let date4 = Date("2025-01-15T15:10:00Z")

        let testData = [
            DataPoint(date: date1, value: 100),
            DataPoint(date: date2, value: 200),
            DataPoint(date: date3, value: 150),
            DataPoint(date: date4, value: 300)
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .hour, metric: .views)

        // Should have 2 hours worth of data
        #expect(aggregated.count == 2)

        // Check hour 14:00
        let hour14 = Date("2025-01-15T14:00:00Z")
        #expect(aggregated[hour14] == 450) // 100 + 200 + 150

        // Check hour 15:00
        let hour15 = Date("2025-01-15T15:00:00Z")
        #expect(aggregated[hour15] == 300)
    }

    @Test
    func dailyAggregation() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Create test data across multiple days
        let testData = [
            DataPoint(date: Date("2025-01-15T08:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-15T14:00:00Z"), value: 200),
            DataPoint(date: Date("2025-01-15T20:00:00Z"), value: 150),
            DataPoint(date: Date("2025-01-16T10:00:00Z"), value: 300)
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .day, metric: .views)

        #expect(aggregated.count == 2)

        let day1 = Date("2025-01-15T00:00:00Z")
        let day2 = Date("2025-01-16T00:00:00Z")

        #expect(aggregated[day1] == 450)
        #expect(aggregated[day2] == 300)
    }

    @Test
    func monthlyAggregation() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let testData = [
            DataPoint(date: Date("2025-01-15T08:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-20T14:00:00Z"), value: 200),
            DataPoint(date: Date("2025-02-10T10:00:00Z"), value: 300)
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .month, metric: .views)

        #expect(aggregated.count == 2)

        let jan = Date("2025-01-01T00:00:00Z")
        let feb = Date("2025-02-01T00:00:00Z")

        #expect(aggregated[jan] == 300)
        #expect(aggregated[feb] == 300)
    }

    @Test
    func yearlyAggregation() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let testData = [
            DataPoint(date: Date("2025-01-15T08:00:00Z"), value: 100),
            DataPoint(date: Date("2025-03-20T14:00:00Z"), value: 200),
            DataPoint(date: Date("2025-05-10T10:00:00Z"), value: 300)
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .year, metric: .views)

        // Year granularity aggregates by month
        #expect(aggregated.count == 1)

        let jan = Date("2025-01-01T00:00:00Z")

        #expect(aggregated[jan] == 600)
    }

    // MARK: - Date Sequence Generation Tests

    @Test
    func hourlyDateSequence() {
        let aggregator = StatsDataAggregator(calendar: calendar)
        let start = Date("2025-01-15T10:00:00Z")
        let end = Date("2025-01-15T14:00:00Z") // Exclusive upper bound

        let sequence = aggregator.generateDateSequence(dateInterval: DateInterval(start: start, end: end), by: .hour)

        #expect(sequence.count == 4) // 10:00, 11:00, 12:00, 13:00
        #expect(sequence.first == start)
        #expect(sequence.last == Date("2025-01-15T13:00:00Z"))
    }

    @Test
    func dailyDateSequence() {
        let aggregator = StatsDataAggregator(calendar: calendar)
        let start = Date("2025-01-15T00:00:00Z") // Already normalized
        let end = Date("2025-01-17T00:00:00Z") // Exclusive upper bound

        let sequence = aggregator.generateDateSequence(dateInterval: DateInterval(start: start, end: end), by: .day)

        #expect(sequence.count == 2) // Jan 15, 16 (Jan 17 is excluded as end is exclusive)
        #expect(sequence.first == Date("2025-01-15T00:00:00Z"))
        #expect(sequence.last == Date("2025-01-16T00:00:00Z"))
    }

    @Test
    func monthlyDateSequence() {
        let aggregator = StatsDataAggregator(calendar: calendar)
        let start = Date("2025-01-01T00:00:00Z") // Already normalized
        let end = Date("2025-03-01T00:00:00Z") // Exclusive upper bound

        let sequence = aggregator.generateDateSequence(dateInterval: DateInterval(start: start, end: end), by: .month)

        #expect(sequence.count == 2) // Jan, Feb (Mar is excluded as end is exclusive)
        #expect(sequence.first == Date("2025-01-01T00:00:00Z"))
        #expect(sequence.last == Date("2025-02-01T00:00:00Z"))
    }

    @Test
    func yearlyDateSequence() {
        let aggregator = StatsDataAggregator(calendar: calendar)
        let start = Date("2025-01-01T00:00:00Z")
        let end = Date("2025-06-01T00:00:00Z") // Exclusive upper bound

        // Year granularity uses month increments
        let sequence = aggregator.generateDateSequence(dateInterval: DateInterval(start: start, end: end), by: .month)

        #expect(sequence.count == 5) // Jan, Feb, Mar, Apr, May (Jun is excluded)
        #expect(sequence.first == Date("2025-01-01T00:00:00Z"))
        #expect(sequence[1] == Date("2025-02-01T00:00:00Z"))
        #expect(sequence[2] == Date("2025-03-01T00:00:00Z"))
        #expect(sequence[3] == Date("2025-04-01T00:00:00Z"))
        #expect(sequence.last == Date("2025-05-01T00:00:00Z"))
    }

    @Test
    func dateSequenceExcludesEndDate() {
        let aggregator = StatsDataAggregator(calendar: calendar)
        let start = Date("2025-01-15T00:00:00Z")
        let end = Date("2025-01-17T00:00:00Z") // Exclusive upper bound

        let sequence = aggregator.generateDateSequence(dateInterval: DateInterval(start: start, end: end), by: .day)

        // Should include Jan 15, 16 only (DateInterval end is exclusive)
        #expect(sequence.count == 2)
        #expect(sequence.contains(Date("2025-01-15T00:00:00Z")))
        #expect(sequence.contains(Date("2025-01-16T00:00:00Z")))
        #expect(!sequence.contains(Date("2025-01-17T00:00:00Z")))
    }

    @Test
    func dateSequenceWithNonNormalizedStart() {
        let aggregator = StatsDataAggregator(calendar: calendar)
        // Test with non-normalized start times
        let start = Date("2025-01-15T14:30:00Z") // Mid-day
        let end = Date("2025-01-18T14:30:00Z")

        let sequence = aggregator.generateDateSequence(dateInterval: DateInterval(start: start, end: end), by: .day)

        // Should start from the given time and increment by days
        #expect(sequence.count == 3)
        #expect(sequence[0] == Date("2025-01-15T14:30:00Z"))
        #expect(sequence[1] == Date("2025-01-16T14:30:00Z"))
        #expect(sequence[2] == Date("2025-01-17T14:30:00Z"))
    }

    // MARK: - Averaged Metrics Tests

    @Test
    func aggregateWithAveragedMetric() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let testData = [
            DataPoint(date: Date("2025-01-15T08:00:00Z"), value: 300),
            DataPoint(date: Date("2025-01-15T14:00:00Z"), value: 600),
            DataPoint(date: Date("2025-01-15T20:00:00Z"), value: 900),
            DataPoint(date: Date("2025-01-16T10:00:00Z"), value: 400)
        ]

        // Test with timeOnSite metric which uses average strategy
        let aggregated = aggregator.aggregate(testData, granularity: .day, metric: .timeOnSite)

        #expect(aggregated.count == 2)

        let day1 = Date("2025-01-15T00:00:00Z")
        let day2 = Date("2025-01-16T00:00:00Z")

        // Values should be averaged: (300 + 600 + 900) / 3 = 600
        #expect(aggregated[day1] == 600)
        // Single value: 400 / 1 = 400
        #expect(aggregated[day2] == 400)
    }

    // MARK: - Process Period Tests

    @Test
    func processPeriodDailyGranularity() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Create test data spanning multiple days
        let allDataPoints = [
            DataPoint(date: Date("2025-01-14T10:00:00Z"), value: 50),  // Outside range
            DataPoint(date: Date("2025-01-15T08:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-15T14:00:00Z"), value: 200),
            DataPoint(date: Date("2025-01-15T20:00:00Z"), value: 150),
            DataPoint(date: Date("2025-01-16T10:00:00Z"), value: 300),
            DataPoint(date: Date("2025-01-17T10:00:00Z"), value: 250),
            DataPoint(date: Date("2025-01-18T10:00:00Z"), value: 75)   // Outside range
        ]

        // Create date interval for Jan 15-17 (exclusive end)
        let dateInterval = DateInterval(
            start: Date("2025-01-15T00:00:00Z"),
            end: Date("2025-01-18T00:00:00Z")
        )

        // Filter data points for the period
        let filteredDataPoints = allDataPoints.filter { dataPoint in
            dateInterval.contains(dataPoint.date)
        }

        let result = aggregator.processPeriod(
            dataPoints: filteredDataPoints,
            dateInterval: dateInterval,
            granularity: .day,
            metric: .views
        )

        // Should have 3 days of data
        #expect(result.dataPoints.count == 3)

        // Check aggregated values
        #expect(result.dataPoints[0].date == Date("2025-01-15T00:00:00Z"))
        #expect(result.dataPoints[0].value == 450) // 100 + 200 + 150

        #expect(result.dataPoints[1].date == Date("2025-01-16T00:00:00Z"))
        #expect(result.dataPoints[1].value == 300)

        #expect(result.dataPoints[2].date == Date("2025-01-17T00:00:00Z"))
        #expect(result.dataPoints[2].value == 250)

        // Check total
        #expect(result.total == 1000) // 450 + 300 + 250
    }

    @Test
    func processPeriodHourlyGranularity() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Create test data with multiple values per hour
        let dataPoints = [
            DataPoint(date: Date("2025-01-15T14:15:00Z"), value: 100),
            DataPoint(date: Date("2025-01-15T14:30:00Z"), value: 200),
            DataPoint(date: Date("2025-01-15T14:45:00Z"), value: 150),
            DataPoint(date: Date("2025-01-15T15:10:00Z"), value: 300),
            DataPoint(date: Date("2025-01-15T16:20:00Z"), value: 250)
        ]

        // Create date interval for 3 hours
        let dateInterval = DateInterval(
            start: Date("2025-01-15T14:00:00Z"),
            end: Date("2025-01-15T17:00:00Z")
        )

        // Filter data points for the period
        let filteredDataPoints = dataPoints.filter { dataPoint in
            dateInterval.contains(dataPoint.date)
        }

        let result = aggregator.processPeriod(
            dataPoints: filteredDataPoints,
            dateInterval: dateInterval,
            granularity: .hour,
            metric: .views
        )

        // Should have 3 hours of data
        #expect(result.dataPoints.count == 3)

        // Check aggregated values
        #expect(result.dataPoints[0].value == 450) // 14:00 hour: 100 + 200 + 150
        #expect(result.dataPoints[1].value == 300) // 15:00 hour
        #expect(result.dataPoints[2].value == 250) // 16:00 hour

        #expect(result.total == 1000)
    }

    @Test
    func processPeriodWithAveragedMetric() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Create test data
        let dataPoints = [
            DataPoint(date: Date("2025-01-15T08:00:00Z"), value: 300),
            DataPoint(date: Date("2025-01-15T14:00:00Z"), value: 600),
            DataPoint(date: Date("2025-01-15T20:00:00Z"), value: 900),
            DataPoint(date: Date("2025-01-16T10:00:00Z"), value: 400)
        ]

        let dateInterval = DateInterval(
            start: Date("2025-01-15T00:00:00Z"),
            end: Date("2025-01-17T00:00:00Z")
        )

        // Filter data points for the period
        let filteredDataPoints = dataPoints.filter { dataPoint in
            dateInterval.contains(dataPoint.date)
        }

        // Use timeOnSite which requires averaging
        let result = aggregator.processPeriod(
            dataPoints: filteredDataPoints,
            dateInterval: dateInterval,
            granularity: .day,
            metric: .timeOnSite
        )

        // Values should be averaged per day
        #expect(result.dataPoints[0].value == 600) // (300 + 600 + 900) / 3
        #expect(result.dataPoints[1].value == 400) // 400 / 1

        // Total for averaged metrics is the average of all period values
        #expect(result.total == 500) // (600 + 400) / 2
    }

    @Test
    func processPeriodWithEmptyDateRange() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let dataPoints = [
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-16T10:00:00Z"), value: 200)
        ]

        // Date interval with no matching data
        let dateInterval = DateInterval(
            start: Date("2025-01-20T00:00:00Z"),
            end: Date("2025-01-22T00:00:00Z")
        )

        // Filter data points for the period (should be empty)
        let filteredDataPoints = dataPoints.filter { dataPoint in
            dateInterval.contains(dataPoint.date)
        }

        let result = aggregator.processPeriod(
            dataPoints: filteredDataPoints,
            dateInterval: dateInterval,
            granularity: .day,
            metric: .views
        )

        // Should still have dates but with zero values
        #expect(result.dataPoints.count == 2)
        #expect(result.dataPoints[0].value == 0)
        #expect(result.dataPoints[1].value == 0)
        #expect(result.total == 0)
    }

    @Test
    func processPeriodMonthlyGranularity() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let dataPoints = [
            DataPoint(date: Date("2025-01-15T10:00:00Z"), value: 100),
            DataPoint(date: Date("2025-01-25T10:00:00Z"), value: 200),
            DataPoint(date: Date("2025-02-10T10:00:00Z"), value: 300),
            DataPoint(date: Date("2025-02-20T10:00:00Z"), value: 400),
            DataPoint(date: Date("2025-03-05T10:00:00Z"), value: 500)
        ]

        let dateInterval = DateInterval(
            start: Date("2025-01-01T00:00:00Z"),
            end: Date("2025-03-01T00:00:00Z")
        )

        // Filter data points for the period
        let filteredDataPoints = dataPoints.filter { dataPoint in
            dateInterval.contains(dataPoint.date)
        }

        let result = aggregator.processPeriod(
            dataPoints: filteredDataPoints,
            dateInterval: dateInterval,
            granularity: .month,
            metric: .views
        )

        // Should have 2 months (Jan and Feb)
        #expect(result.dataPoints.count == 2)
        #expect(result.dataPoints[0].value == 300) // Jan: 100 + 200
        #expect(result.dataPoints[1].value == 700) // Feb: 300 + 400
        #expect(result.total == 1000)
    }
}
