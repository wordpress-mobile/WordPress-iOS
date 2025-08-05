import SwiftUI

struct ChartLegendView: View {
    let metric: SiteMetric
    let currentPeriod: DateInterval
    let previousPeriod: DateInterval

    @Environment(\.context) var context
    @ScaledMetric(relativeTo: .footnote) private var circleSize: CGFloat = 6

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            // Current period
            HStack(spacing: 6) {
                Text(context.formatters.dateRange.string(from: currentPeriod))
                    .foregroundColor(.primary)
                Circle()
                    .fill(metric.primaryColor)
                    .frame(width: circleSize, height: circleSize)
            }

            // Previous period
            HStack(spacing: 6) {
                Text(context.formatters.dateRange.string(from: previousPeriod))
                    .foregroundColor(.secondary.opacity(0.75))
                    .font(.footnote)
                Circle()
                    .fill(Color.secondary.opacity(0.75))
                    .frame(width: circleSize, height: circleSize)
            }
        }
        .font(.footnote.weight(.medium))
        .allowsTightening(true)
        .lineLimit(1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}
