import SwiftUI

struct ChartLegendView: View {
    let metric: SiteMetric
    let currentPeriod: DateInterval
    let previousPeriod: DateInterval

    @Environment(\.context) var context

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            // Current period
            HStack(spacing: 6) {
                Text(context.formatters.dateRange.string(from: currentPeriod))
                    .foregroundColor(.primary)
                Circle()
                    .fill(metric.primaryColor)
                    .frame(width: 6, height: 6)
            }

            // Previous period
            HStack(spacing: 6) {
                Text(context.formatters.dateRange.string(from: previousPeriod))
                    .foregroundColor(.secondary.opacity(0.75))
                    .font(.footnote)
                Circle()
                    .fill(Color.secondary.opacity(0.75))
                    .frame(width: 6, height: 6)
            }
        }
        .font(.footnote.weight(.medium))
        .allowsTightening(true)
        .lineLimit(1)
    }
}
