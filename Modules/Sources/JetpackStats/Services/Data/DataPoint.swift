import Foundation

struct DataPoint: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let value: Int

    static func == (lhs: DataPoint, rhs: DataPoint) -> Bool {
        lhs.date == rhs.date && lhs.value == rhs.value
    }
}

extension DataPoint {
    /// Maps previous period data points to align with current period dates.
    /// - Parameters:
    ///   - previousData: The data points from the previous period
    ///   - from: The date interval of the previous period
    ///   - to: The date interval of the current period
    ///   - component: The calendar component to use for date calculations
    ///   - calendar: The calendar to use for date calculations
    /// - Returns: An array of data points with dates shifted to align with the current period
    static func mapDataPoints(
        _ dataPoits: [DataPoint],
        from: DateInterval,
        to: DateInterval,
        component: Calendar.Component,
        calendar: Calendar
    ) -> [DataPoint] {
        let offset = calendar.dateComponents([component], from: from.start, to: to.start).value(for: component) ?? 0
        return dataPoits.map { dataPoint in
            DataPoint(
                date: calendar.date(byAdding: component, value: offset, to: dataPoint.date) ?? dataPoint.date,
                value: dataPoint.value
            )
        }
    }

    static func getTotalValue(for dataPoints: [DataPoint], metric: SiteMetric) -> Int? {
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
