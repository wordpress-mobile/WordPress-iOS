import SwiftUI

enum ChartComparisonLegendStyle: Equatable {
    case lines
    case bars
}

struct ChartComparisonLegendModel: Equatable {
    let currentPeriod: String
    let comparisonPeriod: String
    let style: ChartComparisonLegendStyle

    init(
        dateRange: StatsDateRange,
        chartType: ChartType,
        formatter: StatsDateRangeFormatter
    ) {
        currentPeriod = formatter.string(from: dateRange.dateInterval)
        comparisonPeriod = Strings.Chart.comparisonLegendItem(
            comparison: dateRange.comparison.localizedTitle,
            range: formatter.string(from: dateRange.effectiveComparisonInterval)
        )
        style = chartType == .line ? .lines : .bars
    }
}

struct ChartComparisonLegend: View {
    let model: ChartComparisonLegendModel
    let metric: SiteMetric

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Constants.step2) {
                currentPeriod
                    .fixedSize(horizontal: true, vertical: false)
                comparisonPeriod
                    .fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: Constants.step0_5) {
                currentPeriod
                comparisonPeriod
            }
        }
    }

    private var currentPeriod: some View {
        legendItem(
            label: model.currentPeriod,
            accessibilityPeriod: Strings.Chart.selectedPeriod,
            isComparison: false
        )
    }

    private var comparisonPeriod: some View {
        legendItem(
            label: model.comparisonPeriod,
            accessibilityPeriod: Strings.Chart.comparisonPeriod,
            isComparison: true
        )
    }

    private func legendItem(
        label: String,
        accessibilityPeriod: String,
        isComparison: Bool
    ) -> some View {
        HStack(spacing: Constants.step1) {
            swatch(isComparison: isComparison)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Chart.legendItem(period: accessibilityPeriod, range: label))
    }

    @ViewBuilder
    private func swatch(isComparison: Bool) -> some View {
        switch model.style {
        case .lines:
            ChartLegendLineSwatch(
                color: isComparison ? Color.secondary.opacity(0.8) : metric.primaryColor,
                isDashed: isComparison
            )
            .frame(width: 24, height: 8)
        case .bars:
            RoundedRectangle(cornerRadius: 2)
                .fill(isComparison ? Color.secondary.opacity(0.25) : metric.primaryColor)
                .frame(width: 16, height: 10)
        }
    }
}

private struct ChartLegendLineSwatch: View {
    let color: Color
    let isDashed: Bool

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let y = geometry.size.height / 2
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geometry.size.width, y: y))
            }
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: isDashed ? 2 : 3,
                    lineCap: .round,
                    dash: isDashed ? [5, 6] : []
                )
            )
        }
    }
}
