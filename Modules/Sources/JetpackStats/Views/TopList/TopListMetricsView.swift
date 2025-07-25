import SwiftUI

struct TopListMetricsView: View {
    let currentValue: Int
    let previousValue: Int?
    let metric: SiteMetric
    var showDetails = true
    var showChevron = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 3) {
                Text(StatsValueFormatter.formatNumber(currentValue, onlyLarge: true))
                    .font(.subheadline.weight(.medium)).tracking(-0.1)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                if hasDetails {
                    Image(systemName: "chevron.forward")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            if showDetails, let trend {
                Text(trend.formattedTrend)
                    .fixedSize()
                    .foregroundColor(trend.sentiment.foregroundColor)
                    .contentTransition(.numericText())
                    .font(.caption.weight(.medium)).tracking(-0.33)
            }
        }
        .animation(.spring, value: trend)
    }

    private var trend: TrendViewModel? {
        guard let previousValue else {
            return nil
        }
        return TrendViewModel(currentValue: currentValue, previousValue: previousValue, metric: metric)
    }
}
