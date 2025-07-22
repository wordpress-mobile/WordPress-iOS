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
                HStack(alignment: .center, spacing: 4) {
                    HStack(spacing: 0) {
                        Image(systemName: trend.systemImage)
                            .font(.caption2.weight(.medium))
                            .scaleEffect(x: 0.8, y: 0.8)
                        Text("\(trend.formattedPercentage)")
                    }
                }
                .font(.caption.weight(.medium)).tracking(-0.33)
                .foregroundColor(trend.sentiment.foregroundColor)
                .contentTransition(.numericText())
                .padding(.trailing, -2)
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
