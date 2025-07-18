import Foundation

struct SelectedDataPoints {
    let current: DataPoint?
    let previous: DataPoint?

    // Static method to compute selected data points from a date
    static func compute(
        for date: Date?,
        currentSeries: [DataPoint],
        previousSeries: [DataPoint]
    ) -> SelectedDataPoints? {
        guard let date else { return nil }

        // Since mappedPreviousData has the same dates as currentData,
        // we only need to find the closest date in the current series
        guard !currentSeries.isEmpty else { return nil }

        // Find the closest data point in the current series
        guard let closestPoint = findClosestDataPoint(to: date, in: currentSeries + previousSeries) else {
            return nil
        }

        // Find the closest date value
        let closestDate = closestPoint.date

        // Find points with this exact date in both series
        let currentPoint = currentSeries.first { $0.date == closestDate }
        let previousPoint = previousSeries.first { $0.date == closestDate }

        return SelectedDataPoints(current: currentPoint, previous: previousPoint)
    }

    static func compute(for date: Date?, data: ChartData) -> SelectedDataPoints? {
        compute(for: date, currentSeries: data.currentData, previousSeries: data.mappedPreviousData)
    }

    // Helper method to find the closest data point to a given date
    private static func findClosestDataPoint(to date: Date, in points: [DataPoint]) -> DataPoint? {
        guard !points.isEmpty else { return nil }

        // Find the point with minimum time difference
        return points.min { point1, point2 in
            abs(point1.date.timeIntervalSince(date)) < abs(point2.date.timeIntervalSince(date))
        }
    }
}
