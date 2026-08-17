import SwiftUI
import DesignSystem

struct StandaloneMetricView: View {
    let metric: SiteMetric
    let value: Int

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
        }
    }
}

#Preview {
    StandaloneMetricView(metric: .views, value: 12345)
        .padding()
}
