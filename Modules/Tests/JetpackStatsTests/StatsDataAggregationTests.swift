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

        let testData: [Date: Int] = [
            date1: 100,
            date2: 200,
            date3: 150,
            date4: 300
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .hour)

        // Should have 2 hours worth of data
        #expect(aggregated.count == 2)

        // Check hour 14:00
        let hour14 = Date("2025-01-15T14:00:00Z")
        #expect(aggregated[hour14]?.sum == 450) // 100 + 200 + 150
        #expect(aggregated[hour14]?.count == 3)

        // Check hour 15:00
        let hour15 = Date("2025-01-15T15:00:00Z")
        #expect(aggregated[hour15]?.sum == 300)
        #expect(aggregated[hour15]?.count == 1)
    }

    @Test
    func dailyAggregation() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Create test data across multiple days
        let testData: [Date: Int] = [
            Date("2025-01-15T08:00:00Z"): 100,
            Date("2025-01-15T14:00:00Z"): 200,
            Date("2025-01-15T20:00:00Z"): 150,
            Date("2025-01-16T10:00:00Z"): 300
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .day)

        #expect(aggregated.count == 2)

        let day1 = Date("2025-01-15T00:00:00Z")
        let day2 = Date("2025-01-16T00:00:00Z")

        #expect(aggregated[day1]?.sum == 450)
        #expect(aggregated[day1]?.count == 3)
        #expect(aggregated[day2]?.sum == 300)
        #expect(aggregated[day2]?.count == 1)
    }

    @Test
    func monthlyAggregation() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let testData: [Date: Int] = [
            Date("2025-01-15T08:00:00Z"): 100,
            Date("2025-01-20T14:00:00Z"): 200,
            Date("2025-02-10T10:00:00Z"): 300
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .month)

        #expect(aggregated.count == 2)

        let jan = Date("2025-01-01T00:00:00Z")
        let feb = Date("2025-02-01T00:00:00Z")

        #expect(aggregated[jan]?.sum == 300)
        #expect(aggregated[jan]?.count == 2)
        #expect(aggregated[feb]?.sum == 300)
        #expect(aggregated[feb]?.count == 1)
    }

    @Test
    func yearlyAggregation() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let testData: [Date: Int] = [
            Date("2025-01-15T08:00:00Z"): 100,
            Date("2025-03-20T14:00:00Z"): 200,
            Date("2025-05-10T10:00:00Z"): 300
        ]

        let aggregated = aggregator.aggregate(testData, granularity: .year)

        // Year granularity aggregates by month
        #expect(aggregated.count == 1)

        let jan = Date("2025-01-01T00:00:00Z")

        #expect(aggregated[jan]?.sum == 600)
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

    // MARK: - Aggregation Helper Tests

    @Test
    func aggregateByComponents() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let testData: [Date: Int] = [
            Date("2025-01-15T14:15:00Z"): 100,
            Date("2025-01-15T14:30:00Z"): 200,
            Date("2025-01-15T15:10:00Z"): 300
        ]

        let aggregated = aggregator.aggregateByComponents(
            testData,
            components: [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour]
        )

        #expect(aggregated.count == 2)
    }

    @Test
    func normalizeForMetric_regularMetrics() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let aggregatedData: [Date: AggregatedDataPoint] = [
            Date("2025-01-15T00:00:00Z"): AggregatedDataPoint(sum: 600, count: 3),
            Date("2025-01-16T00:00:00Z"): AggregatedDataPoint(sum: 900, count: 3)
        ]

        // For regular metrics (views, visitors, etc), values should not change
        let normalized = aggregator.normalizeForMetric(aggregatedData, metric: SiteMetric.views)

        #expect(normalized[Date("2025-01-15T00:00:00Z")] == 600)
        #expect(normalized[Date("2025-01-16T00:00:00Z")] == 900)
    }

    @Test
    func normalizeForMetric_averagedMetrics() {
        let aggregator = StatsDataAggregator(calendar: calendar)

        let aggregatedData: [Date: AggregatedDataPoint] = [
            Date("2025-01-15T00:00:00Z"): AggregatedDataPoint(sum: 600, count: 3),
            Date("2025-01-16T00:00:00Z"): AggregatedDataPoint(sum: 900, count: 3)
        ]

        // For timeOnSite and bounceRate, values should be averaged
        let normalized = aggregator.normalizeForMetric(aggregatedData, metric: SiteMetric.timeOnSite)

        #expect(normalized[Date("2025-01-15T00:00:00Z")] == 200) // 600/3
        #expect(normalized[Date("2025-01-16T00:00:00Z")] == 300) // 900/3
    }
}
