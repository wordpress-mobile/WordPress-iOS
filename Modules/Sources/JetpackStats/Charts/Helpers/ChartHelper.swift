import SwiftUI
import Charts

/// Helper to create consistent chart configuration across different chart types.
struct ChartHelper {
    /// Calculates the x-axis domain for charts from chart data.
    static func xAxisDomain(
        for data: ChartData,
        calendar: Calendar
    ) -> ClosedRange<Date> {
        xAxisDomain(
            for: data.dateInterval,
            dataPoints: data.currentData,
            granularity: data.granularity,
            calendar: calendar
        )
    }

    /// Calculates the x-axis domain, expanding the date interval to include all data points.
    ///
    /// Handles edge cases where granularity selections return data points outside the requested
    /// date range (e.g., "year" granularity for "this week" returns YYYY-01-01).
    static func xAxisDomain(
        for dateInterval: DateInterval,
        dataPoints: [DataPoint],
        granularity: DateRangeGranularity,
        calendar: Calendar
    ) -> ClosedRange<Date> {
        if granularity > dateInterval.preferredGranularity {
            return extendedDomain(
                for: dateInterval,
                dataPoints: dataPoints,
                granularity: granularity,
                calendar: calendar
            )
        }
        return dateInterval.start...dateInterval.end
    }

    /// Extends the domain when granularity is larger than appropriate for the date range.
    private static func extendedDomain(
        for dateInterval: DateInterval,
        dataPoints: [DataPoint],
        granularity: DateRangeGranularity,
        calendar: Calendar
    ) -> ClosedRange<Date> {
        guard let firstDataPoint = dataPoints.first?.date else {
            return dateInterval.start...dateInterval.end
        }

        let periodStart = calendar.dateInterval(of: granularity.component, for: firstDataPoint)?.start ?? firstDataPoint

        // For 1-2 data points: show 3 periods centered (like web version)
        if dataPoints.count <= 2 {
            let start = calendar.date(byAdding: granularity.component, value: -2, to: periodStart) ?? periodStart
            let end = calendar.date(byAdding: granularity.component, value: 3, to: periodStart) ?? periodStart
            return start...end
        }

        // For more data points: show enough periods to include all data
        guard let lastDataPoint = dataPoints.last?.date else {
            return periodStart...periodStart
        }

        let lastPeriodStart = calendar.dateInterval(of: granularity.component, for: lastDataPoint)?.start ?? lastDataPoint
        let end = calendar.date(byAdding: granularity.component, value: 1, to: lastPeriodStart) ?? lastPeriodStart

        return periodStart...end
    }

    /// Creates an x-axis with marks at unit boundaries aligned with the chart granularity.
    @AxisContentBuilder
    static func makeXAxis(
        domain: ClosedRange<Date>,
        granularity: DateRangeGranularity,
        calendar: Calendar
    ) -> some AxisContent {
        if granularity == .hour {
            AxisMarks(preset: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(centered: true) {
                        ChartAxisDateLabel(date: date, granularity: granularity)
                    }
                }
            }
        } else {
            AxisMarks(values: .stride(by: granularity.component, count: 1, calendar: calendar)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(centered: true, collisionResolution: .greedy(minimumSpacing: 6)) {
                        ChartAxisDateLabel(date: date, granularity: granularity)
                    }
                }
            }
        }
    }
}
