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
            case .standard:
                HStack(alignment: .center, spacing: 16) {
                    Text(trend.formattedCurrentValue)
                        .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    BadgeTrendIndicator(trend: trend)
                }
            case .compact:
                HStack(alignment: .center, spacing: 12) {
                    Text(trend.formattedCurrentValue)
                        .font(.subheadline.weight(.medium))
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
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(trend.sentiment.foregroundColor)
                }
            }
        }
        .animation(.default, value: trend)
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
