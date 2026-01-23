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
