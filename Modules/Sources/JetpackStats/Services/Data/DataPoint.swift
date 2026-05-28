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
    /// Applies the time offset between the previous and current period to all previous data points,
    /// ensuring all previous data is preserved even when current data is partial or empty.
    /// Filters out any mapped points that fall outside the current period's date range.
    /// - Parameters:
    ///   - currentData: The data points from the current period (used for reference, may be partial or empty)
    ///   - previousData: The data points from the previous period (provides values)
    ///   - dateRange: The date range information containing both current and previous period boundaries
    /// - Returns: An array of data points with dates shifted to the current period and previous values, filtered to current period
    static func mapDataPoints(
        currentData: [DataPoint],
        previousData: [DataPoint],
        dateRange: StatsDateRange
    ) -> [DataPoint] {
        guard !previousData.isEmpty else { return [] }

        // Calculate offset from start of previous period to start of current period
        let dateOffset = dateRange.dateInterval.start.timeIntervalSince(dateRange.effectiveComparisonInterval.start)

        // Apply offset to all previous data points and filter to current period
        return previousData.compactMap { previous in
            let mappedDate = previous.date.addingTimeInterval(dateOffset)
            // Only include points that fall within the current period
            guard dateRange.dateInterval.contains(mappedDate) else {
                return nil
            }
            return DataPoint(date: mappedDate, value: previous.value)
        }
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
