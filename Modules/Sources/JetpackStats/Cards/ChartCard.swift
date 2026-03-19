import SwiftUI
import Charts

struct ChartCard: View {
    @ObservedObject private var viewModel: ChartCardViewModel
    @Environment(\.context) private var context

    private var dateRange: StatsDateRange { viewModel.effectiveDateRange }
    private var metrics: [SiteMetric] { viewModel.metrics }
    private var selectedMetric: SiteMetric { viewModel.selectedMetric }
    private var selectedChartType: ChartType { viewModel.selectedChartType }

    @State private var isShowingRawData = false

    @ScaledMetric(relativeTo: .largeTitle) private var chartHeight = 140

    init(viewModel: ChartCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Constants.step0_5) {
                headerView(for: selectedMetric)
                    .unredacted()
                contentView
            }
            .padding(.vertical, 14)
            .padding(.horizontal, Constants.step3)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectedBarDate = nil
            }

            if metrics.count > 1 {
                Divider()
                cardFooterView
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onAppear {
            viewModel.onAppear()
        }
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .cardStyle()
        .grayscale(viewModel.isStale ? 1 : 0)
        .opacity(viewModel.isEditing ? 0.6 : 1)
        .scaleEffect(viewModel.isEditing ? 0.95 : 1)
        .animation(.smooth, value: viewModel.isStale)
        .animation(.spring, value: viewModel.isEditing)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Strings.Accessibility.chartContainer)
        .sheet(isPresented: $viewModel.isEditing) {
            NavigationStack {
                ChartCardCustomizationView(chartViewModel: viewModel)
                    .navigationTitle(Strings.Cards.selectMetric)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingRawData) {
            if let data = viewModel.chartData[selectedMetric] {
                NavigationStack {
                    ChartDataListView(data: data, dateRange: dateRange)
                }
            }
        }
    }

    private func makeHeaderViewModel(for metric: SiteMetric) -> ChartCardHeaderView.ViewModel {
        let data = viewModel.chartData[selectedMetric] ?? mockChartData
        return ChartCardHeaderView.ViewModel(
            trend: viewModel.selectedBarTrend ?? .make(data, context: .regular),
            metricTitle: metric.localizedTitle,
            period: context.formatters.dateRange.string(from: viewModel.dateRange.subrange ?? viewModel.dateRange.range),
            showComparison: dateRange.comparison != .off
        )
    }

    private func headerView(for metric: SiteMetric) -> some View {
        ChartCardHeaderView(viewModel: makeHeaderViewModel(for: metric))
            .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
            // Leave room for the "more" menu overlay (50pt button, 24pt card padding = 26pt overlap)
            .padding(.trailing, Constants.step3 + Constants.step0_5)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Strings.Accessibility.cardTitle(metric.localizedTitle))
    }

    @ViewBuilder
    private var contentView: some View {
        // warning: important to put `chartContentView` in a container in order for animations to work properly. Do NOT remove the container.
        HStack {
            chartContentView
        }
        .environment(\.showComparison, dateRange.comparison != .off)
        .animation(.spring, value: selectedMetric)
        .animation(.spring, value: selectedChartType)
        .animation(.easeInOut, value: viewModel.isFirstLoad)
    }

    @ViewBuilder
    private var chartContentView: some View {
        if viewModel.isFirstLoad {
            mainChartView(metric: selectedMetric, data: mockChartData)
                .redacted(reason: .placeholder)
                .opacity(0.2)
                .pulsating()
        } else if let data = viewModel.chartData[selectedMetric] {
            if data.isEmpty, data.granularity == .hour {
                loadingErrorView(with: Strings.Chart.hourlyDataUnavailable)
            } else {
                mainChartView(metric: selectedMetric, data: data)
                    .accessibilityIdentifier("chart_card_chart_view")
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        } else {
            loadingErrorView(with: viewModel.loadingError?.localizedDescription ?? Strings.Errors.generic)
        }
    }

    private var cardFooterView: some View {
        MetricsOverviewTabView(
            data: viewModel.isFirstLoad ? viewModel.placeholderTabViewData : viewModel.tabViewData,
            selectedMetric: $viewModel.selectedMetric,
            onMetricSelected: { metric in
                viewModel.tracker?.send(.chartMetricSelected, properties: [
                    "metric": metric.analyticsName
                ])
            }
        )
        .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
        .pulsating(viewModel.isFirstLoad)
        .background(CardGradientBackground(metric: selectedMetric))
    }

    private func loadingErrorView(with message: String) -> some View {
        mainChartView(metric: selectedMetric, data: mockChartData)
            .redacted(reason: .placeholder)
            .grayscale(1)
            .opacity(0.1)
            .overlay {
                SimpleErrorView(message: message)
            }
    }

    private var mockChartData: ChartData {
        ChartData.mock(metric: .views, granularity: dateRange.dateInterval.preferredGranularity, range: dateRange)
    }

    // MARK: - Header View

    private var moreMenu: some View {
        Menu {
            moreMenuContent
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
        }
        .tint(Color.primary)
    }

    @ViewBuilder
    private var moreMenuContent: some View {
        chartTypeSection
        granularitySection
        dataSection
        EditCardMenuContent(cardViewModel: viewModel)
    }

    private var chartTypeSection: some View {
        Section {
            ControlGroup {
                ForEach(ChartType.allCases) { type in
                    Button {
                        let previousType = viewModel.selectedChartType
                        viewModel.selectedChartType = type

                        viewModel.tracker?.send(.chartTypeChanged, properties: [
                            "from_type": previousType.rawValue,
                            "to_type": type.rawValue
                        ])
                    } label: {
                        Label(type.localizedTitle, systemImage: type.systemImage)
                    }
                }
            }
        }
    }

    private var granularitySection: some View {
        Section {
            Menu {
                granularityButton(for: nil)
                let options: [DateRangeGranularity] = [.day, .week, .month, .year]
                ForEach(options) { granularity in
                    granularityButton(for: granularity)
                }
            } label: {
                Label(viewModel.effectiveGranularity.localizedTitle, systemImage: "calendar")
            }
        }
    }

    private func granularityButton(for granularity: DateRangeGranularity?) -> some View {
        Button {
            let previousGranularity = viewModel.selectedGranularity
            viewModel.selectedGranularity = granularity
            viewModel.tracker?.send(.chartGranularityChanged, properties: [
                "from": previousGranularity?.analyticsName ?? "automatic",
                "to": granularity?.analyticsName ?? "automatic"
            ])
        } label: {
            Label(
                granularity?.localizedTitle ?? Strings.Granularity.automatic,
                systemImage: viewModel.selectedGranularity == granularity ? "checkmark" : ""
            )
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                // Track raw data view
                viewModel.tracker?.send(.rawDataViewed, properties: [
                    "card_type": "chart",
                    "metric": viewModel.selectedMetric.analyticsName
                ])
                isShowingRawData = true
            } label: {
                Label(Strings.Chart.showData, systemImage: "tablecells")
            }
            Link(destination: URL(string: "https://wordpress.com/support/stats/understand-your-sites-traffic/")!) {
                Label(Strings.Buttons.learnMore, systemImage: "info.circle")
            }
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private func mainChartView(metric: SiteMetric, data: ChartData) -> some View {
        VStack(alignment: .leading, spacing: Constants.step1 / 2) {
            chartContentView(data: data)
                .frame(height: chartHeight)
                .padding(.horizontal, -Constants.step1)
                .transition(.push(from: .trailing).combined(with: .opacity).combined(with: .scale))
        }
    }

    @ViewBuilder
    private func chartContentView(data: ChartData) -> some View {
        switch selectedChartType {
        case .line:
            LineChartView(data: data)
        case .columns:
            BarChartView(data: data, selectedBarDate: $viewModel.selectedBarDate)
        }
    }
}

private struct CardGradientBackground: View {
    let metric: SiteMetric

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LinearGradient(
            colors: [
                metric.primaryColor.opacity(colorScheme == .light ? 0.03 : 0.04),
                Constants.Colors.secondaryBackground,
            ],
            startPoint: .top,
            endPoint: .center
        )
    }
}

public enum ChartType: String, CaseIterable, Identifiable, Codable {
    case line
    case columns

    public var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .line: Strings.Chart.lineChart
        case .columns: Strings.Chart.barChart
        }
    }

    var systemImage: String {
        switch self {
        case .line: "chart.line.uptrend.xyaxis"
        case .columns: "chart.bar"
        }
    }
}

// MARK: - ChartCardHeaderView

struct ChartCardHeaderView: View {
    struct ViewModel: Equatable {
        let trend: TrendViewModel
        let metricTitle: String
        let period: String
        let showComparison: Bool
    }

    let viewModel: ViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: -1) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(viewModel.trend.formattedCurrentValue)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .kerning(-0.5)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    Text(viewModel.metricTitle)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
                Text(viewModel.period)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.secondary)
                if viewModel.showComparison {
                    Text("\(viewModel.trend.formattedChange)  \(viewModel.trend.iconSign) \(viewModel.trend.formattedPercentage)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(viewModel.trend.sentiment.foregroundColor)
                        .contentTransition(.numericText())
                        .padding(.top, 5)
                }
            }
            Spacer(minLength: 0)
        }
        .animation(.spring, value: viewModel)
    }
}

private struct ChartCardPreview: View {
    @StateObject var viewModel = ChartCardViewModel(
        configuration: ChartCardConfiguration(
            metrics: [.views, .visitors, .likes, .comments]
        ),
        dateRange: Calendar.demo.makeDateRange(for: .today),
        service: MockStatsService(),
        tracker: MockStatsTracker.shared
    )

    var body: some View {
        ChartCard(viewModel: viewModel)
            .cardStyle()
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ChartCardPreview()
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
