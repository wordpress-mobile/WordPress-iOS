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
                        if let monthItem = monthlyData[index] {
                            monthCell(monthItem: monthItem)
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
                        if let monthItem = monthlyData[index] {
                            monthCell(monthItem: monthItem)
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
    private func monthCell(monthItem: YearlyTrendsViewModel.MonthItem) -> some View {
        MonthCell(
            monthItem: monthItem,
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
    struct MonthItem {
        let date: Date // Beginning of month
        let value: Int
    }
    
    let metric: SiteMetric
    
    private let valueFormatter: StatsValueFormatter
    
    let sortedYears: [Int]
    let maxMonthlyViews: Int
    
    private var monthlyData: [Int: [Int: MonthItem]] = [:] // year -> month -> MonthItem
    
    init(dataPoints: [DataPoint], calendar: Calendar, timeZone: TimeZone, metric: SiteMetric = .views) {
        self.metric = metric
        
        self.valueFormatter = StatsValueFormatter(metric: metric)
        
        // Process data points to compute monthly totals
        var monthlyData: [Int: [Int: MonthItem]] = [:]
        var monthlyTotals: [String: Int] = [:] // Temporary storage for accumulating values
        var maxMonthlyViews = 0
        
        // Configure calendar with the correct time zone
        var localCalendar = calendar
        localCalendar.timeZone = timeZone
        
        // First pass: accumulate values by year-month
        for dataPoint in dataPoints {
            let components = localCalendar.dateComponents([.year, .month], from: dataPoint.date)
            guard let year = components.year, let month = components.month else { continue }
            
            let key = "\(year)-\(month)"
            monthlyTotals[key, default: 0] += dataPoint.value
        }
        
        // Second pass: create MonthItems with beginning-of-month dates
        for (key, value) in monthlyTotals {
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let year = Int(parts[0]),
                  let month = Int(parts[1]) else { continue }
            
            // Create date at beginning of month
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = 1
            
            guard let monthDate = localCalendar.date(from: dateComponents) else { continue }
            
            if monthlyData[year] == nil {
                monthlyData[year] = [:]
            }
            
            let monthItem = MonthItem(date: monthDate, value: value)
            monthlyData[year]?[month] = monthItem
            
            // Track max monthly value
            maxMonthlyViews = max(maxMonthlyViews, value)
        }
        
        self.monthlyData = monthlyData
        self.sortedYears = monthlyData.keys.sorted(by: >)
        self.maxMonthlyViews = max(maxMonthlyViews, 1) // Avoid division by zero
    }
    
    func getMonthlyData(for year: Int) -> [MonthItem?] {
        var monthlyItems: [MonthItem?] = Array(repeating: nil, count: 12)
        
        if let yearData = monthlyData[year] {
            for (month, item) in yearData {
                if month >= 1 && month <= 12 {
                    monthlyItems[month - 1] = item
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
    let monthItem: YearlyTrendsViewModel.MonthItem
    let metric: SiteMetric
    let maxValue: Int
    let formatter: YearlyTrendsViewModel
    
    @State private var showingPopover = false
    
    var body: some View {
        HeatmapCellView(
            value: monthItem.value,
            metric: metric,
            maxValue: maxValue
        )
        .onTapGesture {
            showingPopover = true
        }
        .popover(isPresented: $showingPopover) {
            MonthlyTrendsTooltipView(
                date: monthItem.date,
                value: monthItem.value,
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
        let dateString = dateFormatter.string(from: monthItem.date)
        return "\(dateString), \(formatter.formatValue(monthItem.value)) \(metric.localizedTitle)"
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
