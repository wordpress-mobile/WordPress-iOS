import SwiftUI

/// Simplified chart data structure for metrics without comparison period support.
final class SimpleChartData: Sendable {
    let metric: any MetricType
    let granularity: DateRangeGranularity
    let currentTotal: Int
    let currentData: [DataPoint]
    let maxValue: Int
    var isEmpty: Bool {
        currentData.isEmpty || currentData.allSatisfy { $0.value == 0 }
    }

    init(
        metric: any MetricType,
        granularity: DateRangeGranularity,
        currentTotal: Int,
        currentData: [DataPoint]
    ) {
        self.metric = metric
        self.granularity = granularity
        self.currentTotal = currentTotal
        self.currentData = currentData
        self.maxValue = currentData.map(\.value).max() ?? 0
    }

    /// Creates mock chart data for preview and testing purposes.
    static func mock(
        metric: any MetricType,
        granularity: DateRangeGranularity = .day,
        dataPointCount: Int = 7
    ) -> SimpleChartData {
        let calendar = Calendar.current
        let now = Date()

        var mockData: [DataPoint] = []
        for i in 0..<dataPointCount {
            guard let date = calendar.date(byAdding: granularity.component, value: -dataPointCount + i + 1, to: now) else {
                continue
            }

            // Generate random values - generic approach
            let value = Int.random(in: 100...1000)
            mockData.append(DataPoint(date: date, value: value))
        }

        let total = DataPoint.getTotalValue(for: mockData, metric: metric) ?? 0

        return SimpleChartData(
            metric: metric,
            granularity: granularity,
            currentTotal: total,
            currentData: mockData
        )
    }
}
