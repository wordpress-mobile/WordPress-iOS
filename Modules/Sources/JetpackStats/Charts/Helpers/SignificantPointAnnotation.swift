import SwiftUI

struct SignificantPointAnnotation: View {
    let value: Int
    let metric: SiteMetric
    let valueFormatter: StatsValueFormatter

    @Environment(\.colorScheme) private var colorScheme

    init(value: Int, metric: SiteMetric) {
        self.value = value
        self.metric = metric
        self.valueFormatter = StatsValueFormatter(metric: metric)
    }

    var body: some View {
        Text(valueFormatter.format(value: value, context: .compact))
            .fixedSize()
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundColor(metric.primaryColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
                ZStack {
                    Capsule()
                        .fill(Color(.systemBackground).opacity(0.75))
                    Capsule()
                        .fill(metric.primaryColor.opacity(colorScheme == .light ? 0.1 : 0.25))
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        SignificantPointAnnotation(value: 50000, metric: .views)
        SignificantPointAnnotation(value: 1234, metric: .visitors)
        SignificantPointAnnotation(value: 89, metric: .likes)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
