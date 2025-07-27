import SwiftUI
import DesignSystem

struct StandaloneMetricView: View {
    let metric: SiteMetric
    let value: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: metric.systemImage)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)

                Text(metric.localizedTitle)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            Text(StatsValueFormatter.formatNumber(value, onlyLarge: true))
                .font(Font.make(.recoleta, textStyle: .title2, weight: .medium))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
        }
    }
}

#Preview {
    StandaloneMetricView(metric: .views, value: 12345)
        .padding()
}
