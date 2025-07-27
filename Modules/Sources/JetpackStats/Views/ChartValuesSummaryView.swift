import SwiftUI

struct ChartValuesSummaryView: View {
    let trend: TrendViewModel
    var style: SummaryStyle = .standard

    enum SummaryStyle: CaseIterable {
        case standard
        case compact
    }

    var body: some View {
        Group {
            switch style {
            case .standard: standard
            case .compact: compact
            }
        }
        .animation(.default, value: trend)
    }

    private var standard: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(trend.formattedCurrentValue)
                .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                .foregroundColor(.primary)
                .contentTransition(.numericText())

            BadgeTrendIndicator(trend: trend)
        }
    }

    private var compact: some View {
        HStack(alignment: .center, spacing: 9) {
            Text(trend.formattedCurrentValue)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.primary)
                .contentTransition(.numericText())

            Group {
                Text(trend.formattedChange)
                HStack(spacing: 2) {
                    Image(systemName: trend.systemImage)
                        .font(.caption2.weight(.medium))
                    Text(trend.formattedPercentage)
                }
            }
            .contentTransition(.numericText())
            .font(.system(.subheadline, design: .rounded, weight: .medium))
            .foregroundColor(trend.sentiment.foregroundColor)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(ChartValuesSummaryView.SummaryStyle.allCases, id: \.self) { style in
            ChartValuesSummaryView(trend: .init(currentValue: 1000, previousValue: 500, metric: .views), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 500, previousValue: 1000, metric: .views), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 100, previousValue: 100, metric: .views), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 56, previousValue: 60, metric: .bounceRate), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 42, previousValue: 0, metric: .views), style: style)
            Divider()
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
