import Foundation

struct SelectedDataPoints {
    let current: DataPoint?
    let previous: DataPoint?
    let unmappedPrevious: DataPoint?

    // Static method to compute selected data points from a date
    static func compute(
        for date: Date?,
        currentSeries: [DataPoint],
        previousSeries: [DataPoint],
        mappedPreviousSeries: [DataPoint]
    ) -> SelectedDataPoints? {
        guard let date else { return nil }

        // Since mappedPreviousData has the same dates as currentData,
        // we only need to find the closest date in the current series
        guard !currentSeries.isEmpty else { return nil }

        // Find the closest data point in the current series
        guard let closestPoint = findClosestDataPoint(to: date, in: currentSeries + mappedPreviousSeries) else {
            return nil
        }

        // Find the closest date value
        let closestDate = closestPoint.date

        // Find points with this exact date in both series
        let currentPoint = currentSeries.first { $0.date == closestDate }
        let previousPointIndex = mappedPreviousSeries.firstIndex { $0.date == closestDate }
        var previousPoint: DataPoint? {
            guard let previousPointIndex, mappedPreviousSeries.indices.contains(previousPointIndex) else { return nil }
            return mappedPreviousSeries[previousPointIndex]
        }
        // We need this just to display the data in the tooltip.
        var unmappedPrevious: DataPoint? {
            guard let previousPointIndex, previousSeries.indices.contains(previousPointIndex) else { return nil }
            return previousSeries[previousPointIndex]
        }
        return SelectedDataPoints(current: currentPoint, previous: previousPoint, unmappedPrevious: unmappedPrevious)
    }

    static func compute(for date: Date?, data: ChartData) -> SelectedDataPoints? {
        compute(
            for: date,
            currentSeries: data.currentData,
            previousSeries: data.previousData,
            mappedPreviousSeries: data.mappedPreviousData
        )
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
