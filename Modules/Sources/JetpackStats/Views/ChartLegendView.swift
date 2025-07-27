import SwiftUI

struct ChartLegendView: View {
    let metric: SiteMetric
    let currentPeriod: DateInterval
    let previousPeriod: DateInterval

    @Environment(\.context) var context

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Current period
            HStack(spacing: 6) {
                Circle()
                    .fill(metric.primaryColor)
                    .frame(width: 6, height: 6)
                Text(context.formatters.dateRange.string(from: currentPeriod))
                    .foregroundColor(.primary)
            }
            .layoutPriority(1)

            // Previous period
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.secondary.opacity(0.8))
                    .frame(width: 6, height: 6)
                Text(context.formatters.dateRange.string(from: previousPeriod))
                    .foregroundColor(.secondary)
            }
            .layoutPriority(0.5)
        }
        .font(.footnote.weight(.medium))
        .allowsTightening(true)
        .lineLimit(1)
    }
}
