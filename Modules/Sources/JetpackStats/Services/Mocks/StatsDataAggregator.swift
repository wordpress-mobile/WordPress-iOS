import Foundation

/// Represents aggregated data with sum and count
struct AggregatedDataPoint {
    let sum: Int
    let count: Int
}

/// Handles data aggregation and normalization for stats.
///
/// Example usage:
/// ```swift
/// let aggregator = StatsDataAggregator(calendar: .current)
///
/// // Raw hourly data points across multiple days
/// let hourlyData: [Date: Int] = [
///     Date("2025-01-15T10:15:00Z"): 120,
///     Date("2025-01-15T14:30:00Z"): 200,
///     Date("2025-01-15T20:45:00Z"): 150,
///     Date("2025-01-16T11:20:00Z"): 300,
///     Date("2025-01-16T15:10:00Z"): 180
/// ]
///
/// // Aggregate by day with normalization for views (sum strategy)
/// let dailyViews = aggregator.aggregate(hourlyData, granularity: .day, metric: .views)
/// // Result: [
/// //   Date("2025-01-15T00:00:00Z"): 470,  // sum of all views
/// //   Date("2025-01-16T00:00:00Z"): 480   // sum of all views
/// // ]
///
/// // Aggregate by day with normalization for bounce rate (average strategy)
/// let dailyBounceRate = aggregator.aggregate(hourlyData, granularity: .day, metric: .bounceRate)
/// // Result: [
/// //   Date("2025-01-15T00:00:00Z"): 156,  // 470/3 (average)
/// //   Date("2025-01-16T00:00:00Z"): 240   // 480/2 (average)
/// // ]
/// ```
struct StatsDataAggregator {
    var calendar: Calendar

    /// Aggregates data points based on the given granularity and normalizes for the specified metric.
    /// This combines the previous aggregate and normalizeForMetric functions for efficiency.
    func aggregate(_ dataPoints: [DataPoint], granularity: DateRangeGranularity, metric: SiteMetric) -> [Date: Int] {
        var aggregatedData: [Date: AggregatedDataPoint] = [:]

        // First pass: aggregate data
        for dataPoint in dataPoints {
            if let aggregatedDate = makeAggegationDate(for: dataPoint.date, granularity: granularity) {
                let existing = aggregatedData[aggregatedDate]
                aggregatedData[aggregatedDate] = AggregatedDataPoint(
                    sum: (existing?.sum ?? 0) + dataPoint.value,
                    count: (existing?.count ?? 0) + 1
                )
            }
        }

        // Second pass: normalize based on metric strategy
        var normalizedData: [Date: Int] = [:]
        for (date, dataPoint) in aggregatedData {
            switch metric.aggregationStrategy {
            case .sum:
                normalizedData[date] = dataPoint.sum
            case .average:
                if dataPoint.count > 0 {
                    normalizedData[date] = dataPoint.sum / dataPoint.count
                }
            }
        }

        return normalizedData
    }

    private func makeAggegationDate(for date: Date, granularity: DateRangeGranularity) -> Date? {
        let dateComponents = calendar.dateComponents(granularity.calendarComponents, from: date)
        return calendar.date(from: dateComponents)
    }

    /// Generates sequence of dates between start and end with the given component.
    func generateDateSequence(dateInterval: DateInterval, by component: Calendar.Component, value: Int = 1) -> [Date] {
        var dates: [Date] = []
        var currentDate = dateInterval.start
        let now = Date()
        // DateInterval.end is exclusive
        while currentDate < dateInterval.end && currentDate <= now {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: component, value: value, to: currentDate) ?? currentDate
        }
        return dates
    }

    /// Processes a period of data by aggregating and normalizing data points.
    /// - Parameters:
    ///   - dataPoints: Data points already filtered for the period
    ///   - dateInterval: The date interval to process
    ///   - granularity: The aggregation granularity
    ///   - metric: The metric type for normalization
    /// - Returns: Processed period data with aggregated data points and total
    func processPeriod(
        dataPoints: [DataPoint],
        dateInterval: DateInterval,
        granularity: DateRangeGranularity,
        metric: SiteMetric
    ) -> PeriodData {
        // Aggregate and normalize data in one pass
        let normalizedData = aggregate(dataPoints, granularity: granularity, metric: metric)

        // Generate complete date sequence for the range
        let dateSequence = generateDateSequence(dateInterval: dateInterval, by: granularity.component)

        // Create data points for each date in the sequence
        let periodDataPoints = dateSequence.map { date in
            let aggregationDate = makeAggegationDate(for: date, granularity: granularity)
            return DataPoint(date: date, value: normalizedData[aggregationDate ?? date] ?? 0)
        }

        // Calculate total using DataPoint's getTotalValue method
        let total = DataPoint.getTotalValue(for: periodDataPoints, metric: metric) ?? 0

        return PeriodData(dataPoints: periodDataPoints, total: total)
    }
}

/// Represents processed data for a specific period
struct PeriodData {
    let dataPoints: [DataPoint]
    let total: Int
}
