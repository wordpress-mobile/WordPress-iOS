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
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
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
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(trend.formattedCurrentValue)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }

            Text(trend.formattedTrend)
                .contentTransition(.numericText())
                .font(.system(.footnote, design: .rounded, weight: .medium)).tracking(-0.33)
                .foregroundColor(trend.sentiment.foregroundColor)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(ChartValuesSummaryView.SummaryStyle.allCases, id: \.self) { style in
            ChartValuesSummaryView(trend: .init(currentValue: 1000, previousValue: 500, metric: SiteMetric.views), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 500, previousValue: 1000, metric: SiteMetric.views), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 100, previousValue: 100, metric: SiteMetric.views), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 56, previousValue: 60, metric: SiteMetric.bounceRate), style: style)
            ChartValuesSummaryView(trend: .init(currentValue: 42, previousValue: 0, metric: SiteMetric.views), style: style)
            Divider()
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
