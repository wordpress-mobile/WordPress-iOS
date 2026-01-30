import Foundation

/// Represents a single data point in a time series for statistics.
///
/// ## Timezone Handling
/// All dates in DataPoint are expressed in the **site's timezone** (not UTC or local device timezone).
/// - The API returns date strings (e.g., "2024-01-15") which represent dates in the site's timezone
/// - `StatsService.convertDateToSiteTimezone` converts these to Date objects preserving the site's timezone interpretation
/// - The chart's calendar and formatters use the site's timezone (from `StatsContext.timeZone`)
/// - Charts set `.environment(\.timeZone, context.timeZone)` to display dates correctly
///
/// This ensures consistency across the entire stats system - all date calculations and
/// displays use the site's timezone, matching how WordPress represents the data.
struct DataPoint: Identifiable, Sendable {
    let id = UUID()

    /// The date of this data point in the site's timezone.
    /// Although Date is timezone-agnostic internally, this date should be interpreted
    /// using the site's calendar (StatsContext.calendar) for all date operations.
    let date: Date

    /// The metric value for this data point.
    /// For monetary metrics (revenue, CPM), this is stored in cents (multiply by 100).
    let value: Int

    static func == (lhs: DataPoint, rhs: DataPoint) -> Bool {
        lhs.date == rhs.date && lhs.value == rhs.value
    }
}

extension DataPoint {
    /// Maps previous period data points to align with current period dates.
    /// Takes the dates from current data and replaces values with corresponding previous data values.
    /// Arrays are aligned from the end - if lengths differ, the beginning of the longer array is skipped.
    /// - Parameters:
    ///   - currentData: The data points from the current period (provides dates)
    ///   - previousData: The data points from the previous period (provides values)
    /// - Returns: An array of data points with current dates and previous values
    static func mapDataPoints(
        currentData: [DataPoint],
        previousData: [DataPoint]
    ) -> [DataPoint] {
        // reversing to align by the last item in case there is a mismatch in the number of items
        zip(currentData.reversed(), previousData.reversed()).map { current, previous in
            DataPoint(date: current.date, value: previous.value)
        }.reversed()
    }

    static func getTotalValue(for dataPoints: [DataPoint], metric: some MetricType) -> Int? {
        guard !dataPoints.isEmpty else {
            return nil
        }
        let total = dataPoints.reduce(0) { $0 + $1.value }
        switch metric.aggregationStrategy {
        case .average:
            return total / dataPoints.count
        case .sum:
            return total
        }
    }
}
