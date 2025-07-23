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
    
    @State private var dateRange: StatsDateRange
    @State private var selectedChartType: ChartType = .line
    @State private var isShowingDatePicker = false
    @State private var cachedChartData: ChartData?
    @State private var isComputingData = false
    
    @ScaledMetric private var chartHeight = 160
    
    @Environment(\.context) private var context
    
    /// Creates a new standalone chart card.
    /// - Parameters:
    ///   - dataPoints: The array of data points to display
    ///   - metric: The metric type for proper formatting and colors
    ///   - initialDateRange: The initial date range to display
    init(dataPoints: [DataPoint], metric: SiteMetric, initialDateRange: StatsDateRange) {
        self.dataPoints = dataPoints
        self.metric = metric
        self._dateRange = State(initialValue: initialDateRange)
    }
    
    var body: some View {
        VStack(spacing: Constants.step1) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StatsCardTitleView(title: metric.localizedTitle)
                    Spacer()
                }
                
                // Show legend for current and comparison periods
                ChartLegendView(
                    metric: metric,
                    currentPeriod: dateRange.dateInterval,
                    previousPeriod: dateRange.effectiveComparisonInterval
                )
                
                ChartValuesSummaryView(trend: trend, style: .compact)
                    .padding(.top, 8)
            }
            
            // Chart content
            if let chartData = cachedChartData {
                chartContent(chartData: chartData)
                    .frame(height: chartHeight)
            } else if isComputingData {
                ProgressView()
                    .frame(height: chartHeight)
            }
            
            // Date range controls
            dateRangeControls
        }
        .padding(Constants.step2)
        .overlay(alignment: .topTrailing) {
            moreMenu
        }
        .sheet(isPresented: $isShowingDatePicker) {
            CustomDateRangePicker(dateRange: $dateRange)
        }
        .task(id: dateRange) {
            await computeChartData()
        }
    }
    
    // MARK: - Chart Content
    
    @ViewBuilder
    private func chartContent(chartData: ChartData) -> some View {
        switch selectedChartType {
        case .line:
            LineChartView(data: chartData)
        case .columns:
            BarChartView(data: chartData)
        }
    }
    
    private var trend: TrendViewModel {
        guard let chartData = cachedChartData else {
            return TrendViewModel(currentValue: 0, previousValue: 0, metric: metric)
        }
        return TrendViewModel(
            currentValue: chartData.currentTotal,
            previousValue: chartData.previousTotal,
            metric: metric
        )
    }
    
    @MainActor
    private func computeChartData() async {
        isComputingData = true
        defer { isComputingData = false }

        cachedChartData = await generateChartData(
            dataPoints: dataPoints,
            dateRange: dateRange,
            metric: metric,
            context: context
        )
    }

    // MARK: - Controls
    
    private var moreMenu: some View {
        Menu {
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
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(width: 50, height: 50)
        }
        .tint(Color.primary)
    }
    
    private var dateRangeControls: some View {
        HStack(spacing: Constants.step1) {
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
            
            Spacer()
            
            // Navigation controls
            HStack(spacing: 4) {
                // Previous button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        dateRange = dateRange.navigate(.backward)
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(dateRange.canNavigate(in: .backward) ? .primary : Color(.quaternaryLabel))
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!dateRange.canNavigate(in: .backward))
                
                // Next button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        dateRange = dateRange.navigate(.forward)
                    }
                } label: {
                    Image(systemName: "chevron.forward")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(dateRange.canNavigate(in: .forward) ? .primary : Color(.quaternaryLabel))
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!dateRange.canNavigate(in: .forward))
            }
        }
    }
}

private func generateChartData(dataPoints: [DataPoint], dateRange: StatsDateRange, metric: SiteMetric, context: StatsContext) async -> ChartData {
    let granularity = dateRange.dateInterval.preferredGranularity
    let aggregator = StatsDataAggregator(calendar: context.calendar)

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
        previousPeriod.dataPoints,
        from: previousDateInterval,
        to: dateRange.dateInterval,
        component: dateRange.component,
        calendar: context.calendar
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

#Preview("Views Chart") {
    let calendar = Calendar.current
    let dateRange = calendar.makeDateRange(for: .last7Days)
    
    return StandaloneChartCard(
        dataPoints: generateMockDataPoints(days: 365),
        metric: .views,
        initialDateRange: dateRange
    )
    .cardStyle()
    .padding()
    .background(Color(.systemGroupedBackground))
    .environment(\.context, StatsContext.demo)
}

#Preview("Likes Chart") {
    let calendar = Calendar.current
    let dateRange = calendar.makeDateRange(for: .last30Days)
    
    return StandaloneChartCard(
        dataPoints: generateMockDataPoints(days: 365, valueRange: 10...50),
        metric: .likes,
        initialDateRange: dateRange
    )
    .cardStyle()
    .padding()
    .background(Color(.systemGroupedBackground))
    .environment(\.context, StatsContext.demo)
}

// Helper function to generate mock data
private func generateMockDataPoints(days: Int, valueRange: ClosedRange<Int> = 50...200) -> [DataPoint] {
    let calendar = Calendar.current
    let today = Date()
    
    return (0..<days).compactMap { dayOffset in
        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
        let value = Int.random(in: valueRange)
        return DataPoint(date: date, value: value)
    }
}
