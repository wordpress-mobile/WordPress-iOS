import SwiftUI

// MARK: - HeatmapCellView

/// A reusable heatmap cell view that displays a colored rectangle with an optional value label.
/// Used in both WeeklyTrendsView and YearlyTrendsView for consistent visual representation.
struct HeatmapCellView: View {
    let value: Int
    let formattedValue: String
    let color: Color
    let intensity: Double

    @Environment(\.colorScheme) var colorScheme

    /// Creates a heatmap cell with automatic formatting and color calculation based on metric
    init(
        value: Int,
        metric: SiteMetric,
        maxValue: Int
    ) {
        let intensity = maxValue > 0 ? min(1.0, Double(value) / Double(maxValue)) : 0
        let formatter = StatsValueFormatter(metric: metric)

        self.value = value
        self.formattedValue = formatter.format(value: value, context: .compact)
        self.color = metric.primaryColor
        self.intensity = intensity
    }

    var body: some View {
        RoundedRectangle(cornerRadius: Constants.step1)
            .fill(Constants.heatmapColor(baseColor: color, intensity: intensity, colorScheme: colorScheme))
            .overlay {
                if value > 0 {
                    Text(formattedValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .dynamicTypeSize(...DynamicTypeSize.xLarge)
                }
            }
    }
}

// MARK: - HeatmapLegendView

/// A reusable legend view for heatmaps showing the intensity gradient from less to more
struct HeatmapLegendView: View {
    let metric: SiteMetric
    let labelWidth: CGFloat?

    @Environment(\.colorScheme) var colorScheme

    init(metric: SiteMetric, labelWidth: CGFloat? = nil) {
        self.metric = metric
        self.labelWidth = labelWidth
    }

    var body: some View {
        HStack(spacing: Constants.step2) {
            HStack(spacing: 8) {
                if let labelWidth {
                    Text(Strings.PostDetails.less)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: labelWidth, alignment: .trailing)
                } else {
                    Text(Strings.PostDetails.less)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 3) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: Constants.step1)
                            .fill(heatmapColor(for: Double(level) / 4.0))
                            .frame(width: 16, height: 16)
                    }
                }

                Text(Strings.PostDetails.more)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func heatmapColor(for intensity: Double) -> Color {
        Constants.heatmapColor(baseColor: metric.primaryColor, intensity: intensity, colorScheme: colorScheme)
    }
}
