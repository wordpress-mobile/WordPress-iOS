import SwiftUI
import Charts

struct ChartCard: View {
    @ObservedObject private var viewModel: ChartCardViewModel

    private var dateRange: StatsDateRange { viewModel.dateRange }
    private var metrics: [SiteMetric] { viewModel.metrics }

    @State private var selectedMetric: SiteMetric
    @State private var selectedChartType: ChartType = .line
    @State private var isShowingRawData = false

    @ScaledMetric(relativeTo: .body) private var chartHeight = 180

    init(viewModel: ChartCardViewModel) {
        self.viewModel = viewModel

        self._selectedMetric = .init(initialValue: viewModel.metrics.first ?? .views)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Constants.step1 / 2) {
                headerView(for: selectedMetric)
                    .unredacted()
                contentView
            }
            .padding(.vertical, Constants.step2)
            .padding(.horizontal, Constants.step3)

            if metrics.count > 1 {
                Divider()
                footerView
            }
        }
        .background(
            LinearGradient(
                colors: [
                    selectedMetric.primaryColor.opacity(0.02),
                    selectedMetric.primaryColor.opacity(0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            viewModel.onAppear()
        }
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .grayscale(viewModel.isStale ? 1 : 0)
        .animation(.smooth, value: viewModel.isStale)
    }

    private func headerView(for metric: SiteMetric) -> some View {
        HStack {
            StatsCardTitleView(title: metric.localizedTitle, showChevron: false)
            Spacer(minLength: 44)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: Constants.step1 / 2) {
            // Showing currently selected (not loaded period) by design
            ChartLegendView(
                metric: selectedMetric,
                currentPeriod: dateRange.dateInterval,
                previousPeriod: dateRange.effectiveComparisonInterval
            )
            .frame(maxWidth: .infinity, alignment: .leading)

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
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            } else {
                loadingErrorView(with: viewModel.loadingError?.localizedDescription ?? Strings.Errors.generic)
            }
        }
        .animation(.spring, value: selectedMetric)
        .animation(.spring, value: selectedChartType)
        .animation(.easeInOut, value: viewModel.isFirstLoad)
    }

    private var footerView: some View {
        MetricsOverviewTabView(
            data: viewModel.isFirstLoad ? viewModel.placeholderTabViewData : viewModel.tabViewData,
            selectedMetric: $selectedMetric
        )
        .redacted(reason: viewModel.isFirstLoad ? .placeholder : [])
        .pulsating(viewModel.isFirstLoad)
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
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 56, height: 50)
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
    }

    // MARK: - Chart View

    @ViewBuilder
    private func mainChartView(metric: SiteMetric, data: ChartData) -> some View {
        VStack(alignment: .leading, spacing: Constants.step1 / 2) {
            ChartValuesSummaryView(
                trend: TrendViewModel.make(data, context: .regular),
                style: metrics.count > 1 ? .compact : .standard
            )
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
            BarChartView(data: data)
        }
    }
}

enum ChartType: String, CaseIterable {
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

private struct ChartCardPreview: View {
    @StateObject var viewModel = ChartCardViewModel(
        metrics: [.views, .visitors, .likes, .comments],
        dateRange: Calendar.demo.makeDateRange(for: .today),
        service: MockStatsService()
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
