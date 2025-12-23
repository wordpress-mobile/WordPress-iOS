import SwiftUI
import Charts

/// A reusable chart card component that displays metric data over time with date range controls.
///
/// This component provides:
/// - Line and bar chart visualization options
/// - Date range selection and navigation
/// - Comparison with previous period
/// - Automatic data aggregation based on selected granularity
struct StandaloneChartCard: View {
    /// The data points to display in the chart
    let dataPoints: [DataPoint]

    /// The metric type being displayed (e.g., views, likes, comments)
    let metric: SiteMetric

    private let configuration: Configuration

    @State private var dateRange: StatsDateRange
    @Binding var chartType: ChartType
    @State private var isShowingDatePicker = false
    @State private var chartData: ChartData?

    @ScaledMetric(relativeTo: .largeTitle) private var chartHeight = 180

    @Environment(\.context) private var context

    @Environment(\.redactionReasons) private var redactionReasons

    struct Configuration {
        var minimumGranularity: DateRangeGranularity = .hour
    }

    /// Creates a new standalone chart card.
    /// - Parameters:
    ///   - dataPoints: The array of data points to display
    ///   - metric: The metric type for proper formatting and colors
    ///   - initialDateRange: The initial date range to display
    ///   - chartType: Binding to the chart type
    init(
        dataPoints: [DataPoint],
        metric: SiteMetric,
        initialDateRange: StatsDateRange,
        chartType: Binding<ChartType>,
        configuration: Configuration = .init()
    ) {
        self.dataPoints = dataPoints
        self.metric = metric
        self._dateRange = State(initialValue: initialDateRange)
        self._chartType = chartType
        self.configuration = configuration
    }

    var body: some View {
        VStack(spacing: Constants.step1) {
            StatsCardTitleView(title: metric.localizedTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            chartHeaderView
                .padding(.trailing, -Constants.step0_5)
            chartContentView
                .padding(.horizontal, -Constants.step1)
            dateRangeControls
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        .padding(.vertical, Constants.step2)
        .padding(.horizontal, Constants.step3)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .sheet(isPresented: $isShowingDatePicker) {
            CustomDateRangePicker(dateRange: $dateRange)
        }
        .task(id: dateRange) {
            await refreshChartData()
        }
    }

    private var chartHeaderView: some View {
        // Showing currently selected (not loaded period) by design
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if let data = chartData {
                ChartValuesSummaryView(
                    trend: .make(data, context: .regular),
                    style: .compact
                )
            } else {
                ChartValuesSummaryView(
                    trend: .init(currentValue: 100, previousValue: 10, metric: .views),
                    style: .compact
                )
                .redacted(reason: .placeholder)
            }

            Spacer(minLength: 8)

            ChartLegendView(
                metric: metric,
                currentPeriod: dateRange.dateInterval,
                previousPeriod: dateRange.effectiveComparisonInterval
            )
        }
    }

    private var chartContentView: some View {
        Group {
            if dateRange.dateInterval.preferredGranularity < configuration.minimumGranularity {
                loadingErrorView(with: Strings.Chart.hourlyDataUnavailable)
            } else if let chartData {
                if chartData.isEmptyOrZero {
                    loadingErrorView(with: Strings.Chart.empty)
                } else {
                    chartContent(chartData: chartData)
                        .opacity(redactionReasons.contains(.placeholder) ? 0.2 : 1.0)
                }
            } else {
                chartContent(chartData: mockData)
                    .redacted(reason: .placeholder)
                    .opacity(0.33)
            }
        }
        .frame(height: chartHeight)
    }

    @ViewBuilder
    private func chartContent(chartData: ChartData) -> some View {
        switch chartType {
        case .line:
            LineChartView(data: chartData)
        case .columns:
            BarChartView(data: chartData)
        }
    }

    private func loadingErrorView(with message: String) -> some View {
        chartContent(chartData: mockData)
            .redacted(reason: .placeholder)
            .grayscale(1)
            .opacity(0.1)
            .overlay {
                SimpleErrorView(message: message)
            }
    }

    // MARK: –

    private var trend: TrendViewModel {
        guard let chartData else {
            return TrendViewModel(currentValue: 0, previousValue: 0, metric: metric)
        }
        return TrendViewModel(
            currentValue: chartData.currentTotal,
            previousValue: chartData.previousTotal,
            metric: metric
        )
    }

    private func refreshChartData() async {
        let chartData = await generateChartData(
            dataPoints: dataPoints,
            dateRange: dateRange,
            metric: metric,
            calendar: context.calendar,
            granularity: max(dateRange.dateInterval.preferredGranularity, configuration.minimumGranularity)
        )
        guard !Task.isCancelled else { return }
        self.chartData = chartData
    }

    private var mockData: ChartData {
        ChartData.mock(metric: .views, granularity: .day, range: dateRange)
    }

    // MARK: - Controls

    private var moreMenu: some View {
        Menu {
            Section {
                ControlGroup {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Button {
                            chartType = type
                        } label: {
                            Label(type.localizedTitle, systemImage: type.systemImage)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
        }
        .tint(Color.primary)
    }

    private var dateRangeControls: some View {
        HStack {
            // Date range menu button
            Menu {
                StatsDateRangePickerMenu(selection: $dateRange, isShowingCustomRangePicker: $isShowingDatePicker)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                    Text(context.formatters.dateRange.string(from: dateRange.dateInterval))
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, Constants.step1)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .tint(Color.primary)

            Spacer(minLength: Constants.step1)

            // Navigation controls
            HStack(spacing: 4) {
                navigationButton(direction: .backward)
                navigationButton(direction: .forward)
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private func navigationButton(direction: Calendar.NavigationDirection) -> some View {
        Button {
            dateRange = dateRange.navigate(direction)
        } label: {
            Image(systemName: direction == .backward ? "chevron.backward" : "chevron.forward")
                .font(.subheadline.weight(.medium))
                .foregroundColor(dateRange.canNavigate(in: direction) ? .primary : Color(.quaternaryLabel))
                .frame(width: 36, height: 36)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!dateRange.canNavigate(in: direction))
    }
}

private func generateChartData(
    dataPoints: [DataPoint],
    dateRange: StatsDateRange,
    metric: SiteMetric,
    calendar: Calendar,
    granularity: DateRangeGranularity
) async -> ChartData {
    let aggregator = StatsDataAggregator(calendar: calendar)

    // Filter data points for current period
    let currentDataPoints = dataPoints.filter { dataPoint in
        dateRange.dateInterval.contains(dataPoint.date)
    }

    // Process current period
    let currentPeriod = aggregator.processPeriod(
        dataPoints: currentDataPoints,
        dateInterval: dateRange.dateInterval,
        granularity: granularity,
        metric: metric
    )

    // Create previous period using calendar extension
    let previousDateInterval = dateRange.effectiveComparisonInterval

    // Filter data points for previous period
    let previousDataPoints = dataPoints.filter { dataPoint in
        previousDateInterval.contains(dataPoint.date)
    }

    let previousPeriod = aggregator.processPeriod(
        dataPoints: previousDataPoints,
        dateInterval: previousDateInterval,
        granularity: granularity,
        metric: metric
    )

    // Map previous data points to current period dates for overlay
    let mappedPreviousData = DataPoint.mapDataPoints(
        currentData: currentPeriod.dataPoints,
        previousData: previousPeriod.dataPoints
    )

    return ChartData(
        metric: metric,
        granularity: granularity,
        currentTotal: currentPeriod.total,
        currentData: currentPeriod.dataPoints,
        previousTotal: previousPeriod.total,
        previousData: previousPeriod.dataPoints,
        mappedPreviousData: mappedPreviousData
    )
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var chartType: ChartType = .line

        var body: some View {
            StandaloneChartCard(
                dataPoints: generateMockDataPoints(days: 365),
                metric: .views,
                initialDateRange: Calendar.demo.makeDateRange(for: .last7Days),
                chartType: $chartType
            )
        }
    }

    return PreviewWrapper()
        .cardStyle()
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color(.systemGroupedBackground))
        .environment(\.context, StatsContext.demo)
}

// Helper function to generate mock data
private func generateMockDataPoints(days: Int, valueRange: ClosedRange<Int> = 50...200) -> [DataPoint] {
    let calendar = Calendar.demo
    let today = Date()

    return (0..<days).compactMap { dayOffset in
        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
        let value = Int.random(in: valueRange)
        return DataPoint(date: date, value: value)
    }
}
