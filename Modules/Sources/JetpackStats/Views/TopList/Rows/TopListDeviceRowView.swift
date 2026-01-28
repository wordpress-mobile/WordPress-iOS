import SwiftUI

struct TopListDeviceRowView: View {
    let item: TopListItem.Device
    let totalValue: Int

    private var percentage: Double {
        guard totalValue > 0, let itemValue = item.metrics.views else { return 0.0 }
        return Double(itemValue) / Double(totalValue) * 100.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(item.displayName)
                .font(.callout)
                .foregroundColor(.primary)
            // For screensize breakdown, percentage is shown in TopListMetricsView instead
            if item.breakdown != .screensize {
                Text((percentage / 100).formatted(.percent.precision(.fractionLength(1))))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
    }
}
