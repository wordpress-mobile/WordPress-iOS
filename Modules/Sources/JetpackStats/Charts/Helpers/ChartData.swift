import SwiftUI

/// Chart data for a specific metric over a time period.
///
/// ## Timezone Consistency
/// All date-related properties use the site's timezone:
/// - `dateInterval`: The requested time period in the site's timezone
/// - `currentData`/`previousData`: Data points with dates in the site's timezone
/// - When rendering charts, the x-axis domain uses `dateInterval.start...dateInterval.end`
///   and the chart's environment timezone is set to the site's timezone via
///   `.environment(\.timeZone, context.timeZone)`
final class ChartData: Sendable {
    let metric: SiteMetric
    let granularity: DateRangeGranularity

    /// The requested date interval for this chart data, in the site's timezone.
    /// This defines the base time period for the chart's x-axis. The actual x-axis domain
    /// may be expanded to include all data points, especially when custom granularity
    /// (e.g., "year" for "this week") returns points outside this interval.
    let dateInterval: DateInterval

    let currentTotal: Int
    let currentData: [DataPoint]
    let previousTotal: Int
    let previousData: [DataPoint]
    let mappedPreviousData: [DataPoint]
    let maxValue: Int
    let significantPoints: SignificantPoints
    let isEmptyOrZero: Bool

    var isEmpty: Bool {
        currentData.isEmpty && previousData.isEmpty
    }

    struct SignificantPoints: Sendable {
        let currentMax: DataPoint?
        let currentMin: DataPoint?
        let previousMax: DataPoint?
        let previousMin: DataPoint?
    }

    init(
        metric: SiteMetric,
        granularity: DateRangeGranularity,
        dateInterval: DateInterval,
        currentTotal: Int,
        currentData: [DataPoint],
        previousTotal: Int,
        previousData: [DataPoint],
        mappedPreviousData: [DataPoint]
    ) {
        self.metric = metric
        self.granularity = granularity
        self.dateInterval = dateInterval
        self.currentTotal = currentTotal
        self.currentData = currentData
        self.previousTotal = previousTotal
        self.previousData = previousData
        self.mappedPreviousData = mappedPreviousData

        var maxValue = 0 // Faster without creating intermediate arrays
        var currentMaxPoint: DataPoint?
        var currentMinPoint: DataPoint?

        for point in currentData {
            if point.value > maxValue {
                maxValue = point.value
                currentMaxPoint = point
            }
            if point.value > 0 && (currentMinPoint == nil || point.value < currentMinPoint!.value) {
                currentMinPoint = point
            }
        }

        var previousMaxPoint: DataPoint?
        var previousMinPoint: DataPoint?

        for point in mappedPreviousData {
            maxValue = max(maxValue, point.value)
            if previousMaxPoint == nil || point.value > previousMaxPoint!.value {
                previousMaxPoint = point
            }
            if point.value > 0 && (previousMinPoint == nil || point.value < previousMinPoint!.value) {
                previousMinPoint = point
            }
        }

        self.maxValue = maxValue
        self.significantPoints = SignificantPoints(
            currentMax: currentMaxPoint,
            currentMin: currentMinPoint,
            previousMax: previousMaxPoint,
            previousMin: previousMinPoint
        )

        // Check if all data points are zero
        self.isEmptyOrZero = currentData.allSatisfy { $0.value == 0 } && previousData.allSatisfy { $0.value == 0 }
    }
}

// MARK: - Placeholder Data

extension ChartData {
    enum PlaceholderDateAlignment {
        case calendarPeriods
        case rangeStart
    }

    /// Mock data with the same shape as a loaded chart. Calendar-aligned dates match
    /// ``StatsService``; range-aligned dates use ``StatsDataAggregator`` for standalone charts.
    /// The default calendar alignment has:
    /// - one point per calendar period that overlaps the range (weeks start on Monday,
    ///   like the API's), so the first point can fall before the range start;
    /// - no points after `now`;
    /// - the comparison series is generated for the comparison interval and mapped onto
    ///   the current range with ``DataPoint/mapDataPoints(currentData:previousData:dateRange:)``.
    static func mock(
        metric: SiteMetric,
        granularity: DateRangeGranularity,
        range: StatsDateRange,
        dateAlignment: PlaceholderDateAlignment = .calendarPeriods,
        now: Date = .now
    ) -> ChartData {
        func dates(in interval: DateInterval) -> [Date] {
            switch dateAlignment {
            case .calendarPeriods:
                return periodStarts(in: interval, granularity: granularity, calendar: range.calendar, now: now)
            case .rangeStart:
                return StatsDataAggregator(calendar: range.calendar)
                    .generateDateSequence(
                        dateInterval: interval,
                        by: granularity.component,
                        now: now
                    )
            }
        }

        let valueRange = valueRange(for: metric)
        let dataPoints = dates(in: range.dateInterval)
            .map { DataPoint(date: $0, value: Int.random(in: valueRange)) }
        let previousData = dates(in: range.effectiveComparisonInterval)
            .map { date in
                let variation = Double.random(in: 0.75...0.95)
                return DataPoint(date: date, value: Int(Double(Int.random(in: valueRange)) * variation))
            }
        let mappedPreviousData = DataPoint.mapDataPoints(
            currentData: dataPoints,
            previousData: previousData,
            dateRange: range
        )
        return ChartData(
            metric: metric,
            granularity: granularity,
            dateInterval: range.dateInterval,
            currentTotal: DataPoint.getTotalValue(for: dataPoints, metric: metric) ?? 0,
            currentData: dataPoints,
            previousTotal: DataPoint.getTotalValue(for: previousData, metric: metric) ?? 0,
            previousData: previousData,
            mappedPreviousData: mappedPreviousData
        )
    }

    /// The start of every period of `granularity` that overlaps `interval`, up to `now`.
    static func periodStarts(
        in interval: DateInterval,
        granularity: DateRangeGranularity,
        calendar: Calendar,
        now: Date
    ) -> [Date] {
        var calendar = calendar
        if granularity == .week {
            calendar.firstWeekday = 2 // The stats API's weeks start on Monday.
        }
        let component = granularity.component
        guard var date = calendar.dateInterval(of: component, for: interval.start)?.start else {
            return []
        }
        var dates: [Date] = []
        while date < interval.end, date <= now {
            dates.append(date)
            guard let next = calendar.date(byAdding: component, value: 1, to: date) else {
                break
            }
            date = next
        }
        return dates
    }

    private static func valueRange(for metric: SiteMetric) -> ClosedRange<Int> {
        switch metric {
        case .views: 1000...5000
        case .visitors: 500...2500
        case .likes: 50...300
        case .comments: 10...100
        case .posts: 10...50
        case .timeOnSite: 120...300
        case .bounceRate: 40...80
        case .downloads: 100...250
        }
    }

    /// Clamps the given date to be within the range of current data points
    func clampDateToDataRange(_ date: Date) -> Date {
        guard let firstDate = currentData.first?.date,
            let lastDate = currentData.last?.date
        else {
            return date
        }

        if date < firstDate {
            return firstDate
        } else if date > lastDate {
            return lastDate
        }
        return date
    }
}

/// Keeps one copy of placeholder chart data, so re-renders while loading don't redraw
/// the placeholder with new random values.
@MainActor
final class PlaceholderChartDataCache {
    private var cached: ChartData?
    private var cachedRange: StatsDateRange?
    private let dateAlignment: ChartData.PlaceholderDateAlignment

    init(dateAlignment: ChartData.PlaceholderDateAlignment = .calendarPeriods) {
        self.dateAlignment = dateAlignment
    }

    func data(metric: SiteMetric, granularity: DateRangeGranularity, range: StatsDateRange) -> ChartData {
        if let cached,
            cached.metric == metric,
            cached.granularity == granularity,
            cachedRange == range
        {
            return cached
        }
        let data = ChartData.mock(metric: metric, granularity: granularity, range: range, dateAlignment: dateAlignment)
        cached = data
        cachedRange = range
        return data
    }
}
