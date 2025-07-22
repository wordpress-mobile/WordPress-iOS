import SwiftUI

struct TopListMetricsView: View {
    let currentValue: Int
    let previousValue: Int?
    let metric: SiteMetric
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(StatsValueFormatter.formatNumber(currentValue, onlyLarge: true))
                .font(.subheadline.weight(.medium)).tracking(-0.1)
                .foregroundColor(.primary)
                .contentTransition(.numericText())

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
