import Foundation
import WordPressShared

struct PieChartData: Identifiable, Sendable {
    let id = UUID()
    let metric: SiteMetric
    let segments: [Segment]
    let totalValue: Int

    struct Segment: Identifiable, Sendable {
        let id: String
        let name: String
        let value: Int
        let percentage: Double
        let isOther: Bool
    }

    init(items: [any TopListItemProtocol], metric: SiteMetric) {
        self.metric = metric

        // Calculate total value for the metric
        let total = items.reduce(0) { sum, item in
            sum + (item.metrics[metric] ?? 0)
        }
        self.totalValue = total

        // Create segments with percentages, sorted by value descending
        let sortedItems = items.sorted { ($0.metrics[metric] ?? 0) > ($1.metrics[metric] ?? 0) }

        let allSegments = sortedItems.compactMap { item -> Segment? in
            guard let value = item.metrics[metric], value > 0 else { return nil }

            let percentage = total > 0 ? Double(value) / Double(total) * 100.0 : 0.0

            return Segment(
                id: item.id.id,
                name: item.displayName,
                value: value,
                percentage: percentage,
                isOther: false
            )
        }

        // Smart Adaptive Algorithm:
        // - Show 3-6 segments based on data distribution
        // - Always show top 3 (if available)
        // - Never show more than 6 total segments
        // - Only show segments >= 2% (unless needed to reach minimum)

        let minSegments = 3
        let maxSegments = 6
        let minPercentage = 2.0

        if allSegments.count <= minSegments {
            // Show all segments if we have 3 or fewer
            self.segments = allSegments
        } else {
            // Determine which segments to show
            var selectedSegments: [Segment] = []
            var remainingSegments: [Segment] = []

            for (index, segment) in allSegments.enumerated() {
                if index < minSegments {
                    // Always include top 3
                    selectedSegments.append(segment)
                } else if selectedSegments.count < maxSegments && segment.percentage >= minPercentage {
                    // Include segments above threshold, up to max
                    selectedSegments.append(segment)
                } else {
                    // Aggregate the rest
                    remainingSegments.append(segment)
                }
            }

            // Create "Other" segment if we have remaining items
            if !remainingSegments.isEmpty {
                let otherValue = remainingSegments.reduce(0) { $0 + $1.value }
                let otherPercentage = total > 0 ? Double(otherValue) / Double(total) * 100.0 : 0.0

                // Create unique ID for "Other" segment based on aggregated item IDs
                let aggregatedIDs = remainingSegments.map { $0.id }.sorted().joined(separator: "-")
                let otherID = "pie-chart-other-\(aggregatedIDs.hashValue)"

                let otherSegment = Segment(
                    id: otherID,
                    name: Strings.Chart.other,
                    value: otherValue,
                    percentage: otherPercentage,
                    isOther: true
                )

                self.segments = selectedSegments + [otherSegment]
            } else {
                self.segments = selectedSegments
            }
        }
    }
}
