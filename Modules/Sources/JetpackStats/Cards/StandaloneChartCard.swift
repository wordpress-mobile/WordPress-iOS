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
            chartContent
                .frame(height: chartHeight)
            
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
    }
    
    // MARK: - Chart Content
    
    @ViewBuilder
    private var chartContent: some View {
        switch selectedChartType {
        case .line:
            LineChartView(data: chartData)
        case .columns:
            BarChartView(data: chartData)
        }
    }
    
    private var trend: TrendViewModel {
        TrendViewModel(
            currentValue: chartData.currentTotal,
            previousValue: chartData.previousTotal,
            metric: metric
        )
    }
    
    private var chartData: ChartData {
        // Filter data points within the selected date range
        let filteredDataPoints = dataPoints.filter { dataPoint in
            dateRange.dateInterval.contains(dataPoint.date)
        }
        
        // Determine appropriate granularity based on date range
        let granularity = dateRange.dateInterval.preferredGranularity
        
        // Aggregate data based on granularity
        let aggregator = StatsDataAggregator(calendar: context.calendar)
        let aggregatedData = aggregator.aggregate(filteredDataPoints, granularity: granularity)
        let normalizedData = aggregator.normalizeForMetric(aggregatedData, metric: metric)
        
        // Generate complete date sequence for the range
        let dateSequence = aggregator.generateDateSequence(
            dateInterval: dateRange.dateInterval,
            by: granularity.component
        )
        
        // Create data points for chart
        let currentDataPoints = dateSequence.map { date in
            let aggregationDate = aggregator.makeAggegationDate(for: date, granularity: granularity)
            return DataPoint(date: date, value: normalizedData[aggregationDate ?? date] ?? 0)
        }
        
        let currentTotal = currentDataPoints.reduce(0) { $0 + $1.value }
        
        // Calculate previous period data for comparison
        let previousDateRange = StatsDateRange(
            interval: dateRange.effectiveComparisonInterval,
            component: dateRange.component,
            comparison: dateRange.comparison,
            calendar: context.calendar
        )
        
        // Get data points for previous period
        let previousFilteredDataPoints = dataPoints.filter { dataPoint in
            previousDateRange.dateInterval.contains(dataPoint.date)
        }
        
        // Aggregate previous period data
        let previousAggregated = aggregator.aggregate(previousFilteredDataPoints, granularity: granularity)
        let previousNormalized = aggregator.normalizeForMetric(previousAggregated, metric: metric)
        
        // Generate date sequence for previous period
        let previousDateSequence = aggregator.generateDateSequence(
            dateInterval: previousDateRange.dateInterval,
            by: granularity.component
        )
        
        // Create previous data points
        let previousDataPoints = previousDateSequence.map { date in
            let aggregationDate = aggregator.makeAggegationDate(for: date, granularity: granularity)
            return DataPoint(date: date, value: previousNormalized[aggregationDate ?? date] ?? 0)
        }
        
        let previousTotal = previousDataPoints.reduce(0) { $0 + $1.value }
        
        // Map previous data points to current period dates for overlay
        let mappedPreviousData = DataPoint.mapDataPoints(
            previousDataPoints,
            from: previousDateRange.dateInterval,
            to: dateRange.dateInterval,
            component: dateRange.component,
            calendar: context.calendar
        )
        
        return ChartData(
            metric: metric,
            granularity: granularity,
            currentTotal: currentTotal,
            currentData: currentDataPoints,
            previousTotal: previousTotal,
            previousData: previousDataPoints,
            mappedPreviousData: mappedPreviousData
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
                    Image(systemName: "chevron.left")
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
                    Image(systemName: "chevron.right")
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

// MARK: - Chart Type

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
