import SwiftUI

final class ChartData: Sendable {
    let metric: SiteMetric
    let granularity: DateRangeGranularity
    let currentTotal: Int
    let currentData: [DataPoint]
    let previousTotal: Int
    let previousData: [DataPoint]
    let mappedPreviousData: [DataPoint]
    let maxValue: Int

    var isEmpty: Bool {
        currentData.isEmpty && previousData.isEmpty
    }

    init(metric: SiteMetric, granularity: DateRangeGranularity, currentTotal: Int, currentData: [DataPoint], previousTotal: Int, previousData: [DataPoint], mappedPreviousData: [DataPoint]) {
        self.metric = metric
        self.granularity = granularity
        self.currentTotal = currentTotal
        self.currentData = currentData
        self.previousTotal = previousTotal
        self.previousData = previousData
        self.mappedPreviousData = mappedPreviousData

        var maxValue = 0 // Faster without creating intermediate arrays
        for point in currentData {
            maxValue = max(maxValue, point.value)
        }
        for point in mappedPreviousData {
            maxValue = max(maxValue, point.value)
        }
        self.maxValue = maxValue
    }
}

// MARK: - Placeholder Data

extension ChartData {
    static func mock(metric: SiteMetric, granularity: DateRangeGranularity, range: StatsDateRange) -> ChartData {
        let dataPoints = generateMockDataPoints(
            granularity: granularity,
            range: range,
            metric: metric
        )
        let previousData = dataPoints.map { dataPoint in
            let variation = Double.random(in: 0.75...0.95)
            return DataPoint(
                date: dataPoint.date,
                value: Int(Double(dataPoint.value) * variation)
            )
        }
        return ChartData(
            metric: metric,
            granularity: granularity,
            currentTotal: DataPoint.getTotalValue(for: dataPoints, metric: metric) ?? 0,
            currentData: dataPoints,
            previousTotal: DataPoint.getTotalValue(for: previousData, metric: metric) ?? 0,
            previousData: previousData,
            mappedPreviousData: previousData
        )
    }

    private static func generateMockDataPoints(
        granularity: DateRangeGranularity,
        range: StatsDateRange,
        metric: SiteMetric
    ) -> [DataPoint] {
        let calendar = range.calendar
        var dataPoints: [DataPoint] = []

        let valueRange = valueRange(for: metric)

        // Generate data points for each component in the range
        var currentDate = range.dateInterval.start
        while currentDate < range.dateInterval.end {
            let value = Int.random(in: valueRange)
            dataPoints.append(DataPoint(date: currentDate, value: value))

            guard let nextDate = calendar.date(byAdding: granularity.component, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return dataPoints
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
}
