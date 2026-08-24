import SwiftUI
import DesignSystem

struct StandaloneMetricView: View {
    let metric: SiteMetric
    let value: Int
    var dateInterval: DateInterval?

    @Environment(\.context) private var context

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(metric.localizedTitle)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(StatsValueFormatter.formatNumber(value, onlyLarge: true))
                .font(Constants.Typography.smallDisplayFont)
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            if let dateInterval {
                Text(context.formatters.dateRange.string(from: dateInterval))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        StandaloneMetricView(metric: .views, value: 12345)
        StandaloneMetricView(
            metric: .views,
            value: 12345,
            dateInterval: Calendar.demo.makeDateRange(for: .last7Days).dateInterval
        )
    }
    .padding()
}
