import SwiftUI

struct TopListMetricsView: View {
    let currentValue: Int
    let previousValue: Int?
    let metric: SiteMetric
    var showChevron = false
    var device: TopListItem.Device?

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 3) {
                Text(formattedValue)
                    .font(.system(.subheadline, design: .rounded, weight: .medium)).tracking(-0.1)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                if showChevron {
                    Image(systemName: "chevron.forward")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.trailing, -2)
                }
            }
            if let trend {
                Text(trend.formattedTrendShort)
                    .foregroundColor(trend.sentiment.foregroundColor)
                    .contentTransition(.numericText())
                    .font(.system(.caption, design: .rounded, weight: .medium)).tracking(-0.33)
            }
        }
        .animation(.spring, value: trend)
    }

    // TEMPORARY WORKAROUND (CMM-1168):
    // For screensize breakdown, display as percentage since the values are percentages * 100
    // (e.g., 7380 represents 73.8%). For other breakdowns, display as regular numbers.
    private var formattedValue: String {
        if let device, device.breakdown == .screensize {
            let percentage = Double(currentValue) / 100.0
            return (percentage / 100).formatted(.percent.precision(.fractionLength(1)))
        } else {
            return StatsValueFormatter.formatNumber(currentValue, onlyLarge: true)
        }
    }

    private var trend: TrendViewModel? {
        guard let previousValue else {
            return nil
        }
        return TrendViewModel(currentValue: currentValue, previousValue: previousValue, metric: metric)
    }
}
