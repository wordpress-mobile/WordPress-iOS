import SwiftUI
import WordPressKit

struct YearlyTrendsView: View {
    let viewModel: YearlyTrendsViewModel

    private let cellSpacing: CGFloat = 6
    private let yearLabelWidth: CGFloat = 36

    init(viewModel: YearlyTrendsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            yearlyHeatmap
            legend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var yearlyHeatmap: some View {
        VStack(spacing: cellSpacing) {
            ForEach(viewModel.sortedYears, id: \.self) { year in
                yearRow(for: year)
            }
        }
    }
    
    @ViewBuilder
    private func yearRow(for year: Int) -> some View {
        let monthlyData = viewModel.getMonthlyData(for: year)
        
        VStack(spacing: cellSpacing) {
            // First row: Jul-Dec (top)
            HStack(spacing: 8) {
                Text(String(year))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: yearLabelWidth, alignment: .trailing)
                
                HStack(spacing: cellSpacing) {
                    ForEach(6..<12) { index in
                        if let dataPoint = monthlyData[index] {
                            monthCell(dataPoint: dataPoint)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            // Empty cell for months with no data
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            
            // Second row: Jan-Jun (bottom)
            HStack(spacing: 8) {
                Color.clear
                    .frame(width: yearLabelWidth)
                
                HStack(spacing: cellSpacing) {
                    ForEach(0..<6) { index in
                        if let dataPoint = monthlyData[index] {
                            monthCell(dataPoint: dataPoint)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            // Empty cell for months with no data
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func monthCell(dataPoint: DataPoint) -> some View {
        MonthCell(
            dataPoint: dataPoint,
            metric: viewModel.metric,
            maxValue: viewModel.maxMonthlyViews,
            formatter: viewModel
        )
    }
    
    private var legend: some View {
        HeatmapLegendView(metric: viewModel.metric, labelWidth: yearLabelWidth)
    }
}

@MainActor
final class YearlyTrendsViewModel: ObservableObject {
    let metric: SiteMetric
    
    private let valueFormatter: StatsValueFormatter
    private let aggregator: StatsDataAggregator
    
    let sortedYears: [Int]
    let maxMonthlyViews: Int
    
    private var monthlyData: [Int: [Int: DataPoint]] = [:] // year -> month -> DataPoint
    
    init(dataPoints: [DataPoint], calendar: Calendar, timeZone: TimeZone, metric: SiteMetric = .views) {
        self.metric = metric
        
        self.valueFormatter = StatsValueFormatter(metric: metric)
        
        // Configure calendar with the correct time zone
        var localCalendar = calendar
        localCalendar.timeZone = timeZone
        
        // Initialize aggregator with the local calendar
        self.aggregator = StatsDataAggregator(calendar: localCalendar)
        
        // Use StatsDataAggregator to aggregate data by month
        let normalizedData = aggregator.aggregate(dataPoints, granularity: .month, metric: metric)
        
        // Process normalized data into year -> month -> DataPoint structure
        var monthlyData: [Int: [Int: DataPoint]] = [:]
        var maxMonthlyViews = 0
        
        for (date, value) in normalizedData {
            let components = localCalendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { continue }
            
            if monthlyData[year] == nil {
                monthlyData[year] = [:]
            }
            
            let dataPoint = DataPoint(date: date, value: value)
            monthlyData[year]?[month] = dataPoint
            
            // Track max monthly value
            maxMonthlyViews = max(maxMonthlyViews, value)
        }
        
        self.monthlyData = monthlyData
        self.sortedYears = monthlyData.keys.sorted(by: >)
        self.maxMonthlyViews = max(maxMonthlyViews, 1) // Avoid division by zero
    }
    
    func getMonthlyData(for year: Int) -> [DataPoint?] {
        var monthlyItems: [DataPoint?] = Array(repeating: nil, count: 12)
        
        if let yearData = monthlyData[year] {
            for (month, dataPoint) in yearData {
                if month >= 1 && month <= 12 {
                    monthlyItems[month - 1] = dataPoint
                }
            }
        }
        
        return monthlyItems
    }
    
    func formatValue(_ value: Int) -> String {
        valueFormatter.format(value: value, context: .compact)
    }
}

private struct MonthCell: View {
    let dataPoint: DataPoint
    let metric: SiteMetric
    let maxValue: Int
    let formatter: YearlyTrendsViewModel
    
    @State private var showingPopover = false
    
    var body: some View {
        HeatmapCellView(
            value: dataPoint.value,
            metric: metric,
            maxValue: maxValue
        )
        .onTapGesture {
            showingPopover = true
        }
        .popover(isPresented: $showingPopover) {
            MonthlyTrendsTooltipView(
                date: dataPoint.date,
                value: dataPoint.value,
                metric: metric,
                formatter: formatter
            )
            .modifier(PopoverPresentationModifier())
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let dateString = dateFormatter.string(from: dataPoint.date)
        return "\(dateString), \(formatter.formatValue(dataPoint.value)) \(metric.localizedTitle)"
    }
}

private struct MonthlyTrendsTooltipView: View {
    let date: Date
    let value: Int
    let metric: SiteMetric
    let formatter: YearlyTrendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Text(formattedDate)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Month value
            HStack(spacing: 6) {
                Circle()
                    .fill(metric.primaryColor)
                    .frame(width: 8, height: 8)
                Text(formatter.formatValue(value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(metric.localizedTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: date)
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: Constants.step2) {
            YearlyTrendsView(
                viewModel: YearlyTrendsViewModel(
                    dataPoints: mockDataPoints(),
                    calendar: Calendar.current,
                    timeZone: TimeZone.current,
                    metric: .views
                )
            )
            .padding(Constants.step2)
            .cardStyle()
        }
    }
    .background(Constants.Colors.background)
}

private func mockDataPoints() -> [DataPoint] {
    var dataPoints: [DataPoint] = []
    let calendar = Calendar.current
    
    for year in [2021, 2022, 2023, 2024] {
        for month in 1...12 {
            // Skip future months
            if year == 2024 && month > 7 { continue }
            
            // Generate daily data points for each month
            let daysInMonth = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: month))!)?.count ?? 30
            
            for day in 1...daysInMonth {
                if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                    let baseViews = year == 2024 ? 500 : (year == 2023 ? 400 : 200)
                    let viewsCount = Int.random(in: (baseViews / 2)...baseViews)
                    dataPoints.append(DataPoint(date: date, value: viewsCount))
                }
            }
        }
    }
    
    return dataPoints
}
