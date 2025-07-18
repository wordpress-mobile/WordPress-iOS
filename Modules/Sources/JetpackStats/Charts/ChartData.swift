import SwiftUI

final class ChartData {
    let metric: SiteMetric
    let granularity: DateRangeGranularity
    let currentData: [DataPoint]
    let previousData: [DataPoint]
    let mappedPreviousData: [DataPoint]

    lazy private(set) var currentTotal = DataPoint.getTotalValue(for: currentData, metric: metric)
    lazy private(set) var previousTotal = DataPoint.getTotalValue(for: previousData, metric: metric)

    init(metric: SiteMetric, granularity: DateRangeGranularity, currentData: [DataPoint], previousData: [DataPoint], mappedPreviousData: [DataPoint]) {
        self.metric = metric
        self.granularity = granularity
        self.currentData = currentData
        self.previousData = previousData
        self.mappedPreviousData = mappedPreviousData
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
            currentData: dataPoints,
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
        case .timeOnSite: 120...300
        case .bounceRate: 40...80
        }
    }
}
