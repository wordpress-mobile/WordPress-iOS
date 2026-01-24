import SwiftUI
import WordPressUI

/// A horizontal scrollable tab view displaying metric summaries with values and trends.
///
/// Each tab shows a metric's current value, percentage change, and visual selection indicator.
struct MetricsOverviewTabView<Metric: MetricType>: View {
    /// Data for a single metric tab
    struct MetricData {
        let metric: Metric
        let value: Int?
        let previousValue: Int?
    }

    let data: [MetricData]
    @Binding var selectedMetric: Metric
    var onMetricSelected: ((Metric) -> Void)?
    var showTrend: Bool = true

    @ScaledMetric(relativeTo: .title) private var minTabWidth: CGFloat = 100

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(data, id: \.metric) { item in
                        makeItemView(for: item) {
                            selectDataType(item.metric, proxy: proxy)
                        }
                    }
                }
                .padding(.trailing, Constants.step1) // A bit extra after the last item
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
    }

    private func makeItemView(for item: MetricData, onTap: @escaping () -> Void) -> some View {
        MetricItemView(data: item, isSelected: selectedMetric == item.metric, showTrend: showTrend, onTap: onTap)
            .frame(minWidth: minTabWidth)
            .id(item.metric)
    }

    private func selectDataType(_ type: Metric, proxy: ScrollViewProxy) {
        withAnimation(.spring) {
            selectedMetric = type
            proxy.scrollTo(type, anchor: .center)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        onMetricSelected?(type)
    }
}

private struct MetricItemView<Metric: MetricType>: View {
    let data: MetricsOverviewTabView<Metric>.MetricData
    let isSelected: Bool
    let showTrend: Bool
    let onTap: () -> Void

    private var valueFormatter: any ValueFormatterProtocol {
        data.metric.makeValueFormatter()
    }

    private var formattedValue: String {
        guard let value = data.value else { return "–" }
        return valueFormatter.format(value: value, context: .compact)
    }

    private var trend: TrendViewModel? {
        guard let value = data.value, let previousValue = data.previousValue else { return nil }
        return TrendViewModel(currentValue: value, previousValue: previousValue, metric: data.metric)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                selectionIndicator
                    .padding(.leading, Constants.step2)
                    .padding(.trailing, Constants.step1)
                tabContent
                    .padding(.top, Constants.step1 + 1)
                    .padding(.bottom, Constants.step2)
                    .padding(.leading, Constants.step3)
                    .animation(.spring, value: isSelected)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Views

    private var tabContent: some View {
        VStack(alignment: .leading, spacing: -2) {
            headerView
                .unredacted()
            metricsView
        }
    }

    private var headerView: some View {
        HStack(spacing: 2) {
            if showTrend {
                Image(systemName: data.metric.systemImage)
                    .font(.caption2.weight(.medium))
                    .scaleEffect(x: 0.9, y: 0.9)
            }
            Text(data.metric.localizedTitle.uppercased())
                .font(.caption.weight(.medium))
        }
        .foregroundColor(isSelected ? .primary : .secondary)
        .animation(.easeInOut(duration: 0.25), value: isSelected)
        .padding(.trailing, 4) // Visually spacing matters less than for metricsView
    }

    private var metricsView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(formattedValue)
                .contentTransition(.numericText())
                .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .animation(.spring, value: formattedValue)

            if showTrend {
                if let trend {
                    BadgeTrendIndicator(trend: trend)
                } else {
                    // Placeholder for loading state
                    BadgeTrendIndicator(
                        trend: TrendViewModel(currentValue: 125, previousValue: 100, metric: data.metric)
                    )
                    .grayscale(1)
                    .redacted(reason: .placeholder)
                }
            }
        }
        .padding(.trailing, 8)
    }

    private var selectionIndicator: some View {
        Rectangle()
            .fill(Color.primary)
            .frame(height: 3)
            .cornerRadius(1.5)
            .opacity(isSelected ? 1 : 0)
            .scaleEffect(x: isSelected ? 1 : 0.75, anchor: .center)
            .animation(.spring, value: isSelected)
    }
}

// MARK: - Preview Support

#if DEBUG

#Preview {
    let mockData: [MetricsOverviewTabView<SiteMetric>.MetricData] = [
        .init(metric: .views, value: 128400, previousValue: 142600),
        .init(metric: .visitors, value: 49800, previousValue: 54200),
        .init(metric: .likes, value: nil, previousValue: nil),
        .init(metric: .comments, value: 210, previousValue: nil),
        .init(metric: .timeOnSite, value: 165, previousValue: 148),
        .init(metric: .bounceRate, value: nil, previousValue: 72)
    ]

    MetricsOverviewTabView(
        data: mockData,
        selectedMetric: .constant(.views)
    )
    .background(Color(.systemBackground))
    .cardStyle()
    .frame(maxHeight: .infinity, alignment: .center)
    .background(Constants.Colors.background)
}

#endif
