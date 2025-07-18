import SwiftUI
import Charts

struct ChartCard: View {
    let metrics: [SiteMetric]
    let dateRange: StatsDateRange

    @StateObject private var viewModel: ChartCardViewModel

    @State private var selectedMetric: SiteMetric
    @State private var selectedChartType: ChartType = .line
    @State private var isShowingRawData = false

    @ScaledMetric(relativeTo: .body) private var chartHeight = 180

    init(metrics: [SiteMetric], dateRange: StatsDateRange, service: any StatsServiceProtocol) {
        self.metrics = metrics
        self.dateRange = dateRange

        assert(metrics.count > 0)
        self._selectedMetric = .init(initialValue: metrics.first ?? .views)

        let viewModel = ChartCardViewModel(metrics: metrics, service: service)
        self._viewModel = StateObject(wrappedValue: viewModel)

        viewModel.loadData(for: dateRange)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                headerView(for: selectedMetric)
                    .unredacted()
                contentView
            }
            .padding(Constants.step2)

            if metrics.count > 1 {
                Divider()
                footerView
            }
        }
        .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .grayscale(viewModel.isStale ? 1 : 0)
        .animation(.smooth, value: viewModel.isStale)
        .onChange(of: dateRange) { newRange in
            viewModel.loadData(for: newRange)
        }
    }

    private func headerView(for metric: SiteMetric) -> some View {
        HStack {
            StatsCardTitleView(title: metric.localizedTitle, showChevron: false)
            Spacer(minLength: 44)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            if viewModel.isFirstLoad {
                mainChartView(metric: selectedMetric, data: mockChartData)
            } else if let chartData = viewModel.chartData[selectedMetric] {
                mainChartView(metric: selectedMetric, data: chartData)
            } else if let error = viewModel.loadingError {
                mainChartView(metric: selectedMetric, data: mockChartData)
                    .redacted(reason: .placeholder)
                    .grayscale(1)
                    .opacity(0.66)
                    .overlay {
                        SimpleErrorView(error: error)
                            .background(Color(.systemBackground).opacity(0.9))
                            .padding(-2) // Wasn't covering the chart well
                    }
            }
        }
        .animation(.spring, value: selectedMetric)
        .animation(.spring, value: selectedChartType)
    }

    private var footerView: some View {
        MetricsOverviewTabView(
            data: viewModel.isFirstLoad ? viewModel.placeholderTabViewData : viewModel.tabViewData,
            selectedMetric: $selectedMetric
        )
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
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
        }
        .tint(Color.primary)
        .sheet(isPresented: $isShowingRawData) {
            NavigationStack {
                ChartDataListView(
                    chartDataDict: viewModel.chartData,
                    selectedMetric: selectedMetric,
                    dateRanges: dateRange
                )
            }
        }
    }

    @ViewBuilder
    private var moreMenuContent: some View {
        Section {
            ControlGroup {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button {
                        selectedChartType = type
                    } label: {
                        Label(type.localizedTitle, systemImage: type.systemImage)
                    }
                }
            }
        }
        Section {
            Button {
                // Not implemented
            } label: {
                Label(Strings.Buttons.share, systemImage: "square.and.arrow.up")
            }
            Button {
                isShowingRawData = true
            } label: {
                Label(Strings.Chart.showData, systemImage: "tablecells")
            }
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private func mainChartView(metric: SiteMetric, data: ChartData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Showing currently selected (not loaded period) by design
            ChartLegendView(
                metric: metric,
                currentPeriod: dateRange.dateInterval,
                previousPeriod: dateRange.effectiveComparisonInterval
            )
            .unredacted()
            .padding(.bottom, 6)
            .padding(.trailing, 20)

            ChartValuesSummaryView(
                trend: TrendViewModel.make(data, context: .regular),
                style: metrics.count > 1 ? .compact : .standard
            )

            chartContentView(data: data)
                .frame(height: chartHeight)
                .opacity(viewModel.isFirstLoad ? 0.33 : 1)
                .transition(.push(from: .trailing).combined(with: .opacity).combined(with: .scale))
        }
    }

    @ViewBuilder
    private func chartContentView(data: ChartData) -> some View {
        switch selectedChartType {
        case .line:
            LineChartView(data: data)
        case .columns:
            BarChartView(data: data)
        }
    }
}

private enum ChartType: String, CaseIterable {
    case line
    case columns

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

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ChartCard(
                metrics: [.views, .visitors, .likes, .comments],
                dateRange: Calendar.demo.makeDateRange(for: .last7Days),
                service: MockStatsService()
            )
            .cardStyle()

            ChartCard(
                metrics: [.timeOnSite, .bounceRate],
                dateRange: Calendar.demo.makeDateRange(for: .last30Days),
                service: MockStatsService()
            )
            .cardStyle()
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
