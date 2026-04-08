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
        guard !currentSeries.isEmpty else { return nil }

        // Find the index of the closest point in currentSeries.
        // Using index-based lookup so that the corresponding previous point is
        // retrieved by position, not by exact Date equality — the mapped dates
        // may differ slightly (e.g. across DST boundaries).
        guard let closestIndex = currentSeries.indices.min(by: {
            abs(currentSeries[$0].date.timeIntervalSince(date)) <
            abs(currentSeries[$1].date.timeIntervalSince(date))
        }) else { return nil }

        let currentPoint = currentSeries[closestIndex]
        let previousPoint = mappedPreviousSeries.indices.contains(closestIndex) ? mappedPreviousSeries[closestIndex] : nil
        let unmappedPrevious = previousSeries.indices.contains(closestIndex) ? previousSeries[closestIndex] : nil

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

}
