import SwiftUI

struct ChartValueTooltipView: View {
    let selectedPoints: SelectedDataPoints
    let metric: SiteMetric
    let granularity: DateRangeGranularity

    @Environment(\.context) var context

    private var currentPoint: DataPoint? {
        selectedPoints.current
    }

    private var previousPoint: DataPoint? {
        selectedPoints.previous
    }

    private var unmappedPreviousPoint: DataPoint? {
        selectedPoints.unmappedPrevious
    }

    private var formattedDate: String? {
        guard let date = currentPoint?.date ?? previousPoint?.date else { return nil }
        return formattedDate(date)
    }

    private func formattedDate(_ date: Date) -> String {
         context.formatters.date.formatDate(date, granularity: granularity, context: .regular)
    }

    private var trend: TrendViewModel? {
        guard let currentPoint, let previousPoint else {
            return nil
        }
        return TrendViewModel(
            currentValue: currentPoint.value,
            previousValue: previousPoint.value,
            metric: metric,
            context: .regular
        )
    }

    private var isIncompleteData: Bool {
        guard let date = currentPoint?.date else { return false }
        return context.calendar.isIncompleteDataPeriod(for: date, granularity: granularity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step1) {
            // Legend-style period indicators
            VStack(alignment: .leading, spacing: 2) {
                if let currentPoint {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(metric.primaryColor)
                            .frame(width: 8, height: 8)
                        Text(formattedDate(currentPoint.date))
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }

                if let unmappedPreviousPoint {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.secondary.opacity(0.75))
                            .frame(width: 8, height: 8)
                        Text(formattedDate(unmappedPreviousPoint.date))
                            .font(.footnote)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
            }

            // Summary view
            if let trend {
                ChartValuesSummaryView(trend: trend, style: .compact)
            } else if let previousValue = previousPoint?.value {
                Text(StatsValueFormatter(metric: metric).format(value: previousValue, context: .regular))
                    .font(.subheadline.weight(.medium))
            }

            if isIncompleteData {
                Text(Strings.Chart.incompleteData)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, -6)
            }
        }
        .fixedSize()
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Constants.Colors.shadowColor, radius: 4, x: 0, y: 2)
    }
}
