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

    /// Calculates the x-axis domain, expanding the date interval to include all data points if needed.
    ///
    /// If any data points fall outside the requested interval, extends the domain to show
    /// complete granularity periods (e.g., for year granularity, show the entire year).
    static func xAxisDomain(
        for dateInterval: DateInterval,
        dataPoints: [DataPoint],
        granularity: DateRangeGranularity,
        calendar: Calendar
    ) -> ClosedRange<Date> {
        guard let firstDataPoint = dataPoints.first?.date,
              let lastDataPoint = dataPoints.last?.date else {
            return dateInterval.start...dateInterval.end
        }

        // Check if any data points fall outside the interval
        let needsExpansion = firstDataPoint < dateInterval.start || lastDataPoint >= dateInterval.end

        // If all points are within the interval, use it as-is
        guard needsExpansion else {
            return dateInterval.start...dateInterval.end
        }

        // Expand to include all data points
        let rawStart = min(dateInterval.start, firstDataPoint)
        let rawEnd = max(dateInterval.end, lastDataPoint)

        // Align to granularity boundaries
        let periodStart = calendar.dateInterval(of: granularity.component, for: rawStart)?.start ?? rawStart
        let periodEnd = calendar.dateInterval(of: granularity.component, for: rawEnd)?.end ?? rawEnd
        return periodStart...periodEnd
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
