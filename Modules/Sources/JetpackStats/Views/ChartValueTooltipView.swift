import SwiftUI

struct ChartValueTooltipView: View {
    let currentPoint: DataPoint?
    let previousPoint: DataPoint?
    let metric: SiteMetric
    let granularity: DateRangeGranularity

    @Environment(\.context) var context

    private var formattedDate: String? {
        guard let date = currentPoint?.date ?? previousPoint?.date else { return nil }
        return context.formatters.date.formatDate(date, granularity: granularity)
    }

    private var trend: TrendViewModel? {
        guard let currentPoint, let previousPoint else {
            return nil
        }
        return TrendViewModel(
            currentValue: currentPoint.value,
            previousValue: previousPoint.value,
            metric: metric
        )
    }

    private var isIncompleteData: Bool {
        guard let date = currentPoint?.date else { return false }
        return context.calendar.isIncompleteDataPeriod(for: date, granularity: granularity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Use the date from whichever point is available
            if let formattedDate {
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ChartTooltipRow(
                color: metric.primaryColor,
                value: currentPoint?.value,
                isPrimary: true,
                metric: metric
            )

            ChartTooltipRow(
                color: Color.secondary,
                value: previousPoint?.value,
                isPrimary: false,
                metric: metric
            )

            if let trend {
                Text(trend.formattedTrend)
                    .contentTransition(.numericText())
                    .font(.subheadline.weight(.medium)).tracking(-0.33)
                    .foregroundColor(trend.sentiment.foregroundColor)
            }

            if isIncompleteData {
                Text(Strings.Chart.incompleteData)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .fixedSize()
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

private struct ChartTooltipRow: View {
    let color: Color
    let value: Int?
    let isPrimary: Bool
    let metric: SiteMetric

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(formattedValue)
                .font(.subheadline)
                .fontWeight(isPrimary ? .medium : .regular)
                .foregroundColor(isPrimary ? .primary : .secondary)
        }
    }

    private var formattedValue: String {
        guard let value else {
            return "–"
        }
        return StatsValueFormatter(metric: metric)
            .format(value: value)
    }
}
