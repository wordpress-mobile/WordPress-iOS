import SwiftUI
import WordPressKit

struct YearlyTrendsView: View {
    let viewModel: YearlyTrendsViewModel

    private let cellSpacing: CGFloat = 6
    private let yearLabelWidth: CGFloat = 36

    init(dataPoints: [DataPoint], calendar: Calendar, timeZone: TimeZone, metric: SiteMetric = .views) {
        self.viewModel = YearlyTrendsViewModel(
            dataPoints: dataPoints,
            calendar: calendar,
            timeZone: timeZone,
            metric: metric
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            yearlyHeatmap
            legend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
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
                        monthCell(
                            month: viewModel.monthLabels[index],
                            year: year,
                            viewsCount: monthlyData[index]
                        )
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            
            // Second row: Jan-Jun (bottom)
            HStack(spacing: 8) {
                Color.clear
                    .frame(width: yearLabelWidth)
                
                HStack(spacing: cellSpacing) {
                    ForEach(0..<6) { index in
                        monthCell(
                            month: viewModel.monthLabels[index],
                            year: year,
                            viewsCount: monthlyData[index]
                        )
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
    
    @State private var showingPopover = false
    @State private var selectedMonth: (month: String, year: Int, viewsCount: Int)?
    
    @ViewBuilder
    private func monthCell(month: String, year: Int, viewsCount: Int) -> some View {
        HeatmapCellView(
            value: viewsCount,
            metric: viewModel.metric,
            maxValue: viewModel.maxMonthlyViews
        )
        .onTapGesture {
            selectedMonth = (month: month, year: year, viewsCount: viewsCount)
            showingPopover = true
        }
        .popover(isPresented: $showingPopover) {
            if let selected = selectedMonth {
                MonthlyTrendsTooltipView(
                    month: selected.month,
                    year: selected.year,
                    viewsCount: selected.viewsCount,
                    metric: viewModel.metric,
                    formatter: viewModel
                )
                .modifier(PopoverPresentationModifier())
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(month) \(year), \(viewModel.formatValue(viewsCount)) \(viewModel.metric.localizedTitle)")
        .accessibilityAddTraits(.isButton)
    }
    
    private var legend: some View {
        HeatmapLegendView(metric: viewModel.metric, labelWidth: yearLabelWidth)
    }
    
    private var accessibilityLabel: String {
        let yearsCount = min(viewModel.sortedYears.count, 3)
        let totalValue = viewModel.sortedYears.prefix(3).reduce(0) { sum, year in
            sum + (viewModel.yearlyTotals[year] ?? 0)
        }
        let formattedTotal = viewModel.formatValue(totalValue)
        
        return Strings.PostDetails.yearlyActivityAccessibility(
            yearsCount: yearsCount,
            metric: viewModel.metric.localizedTitle,
            total: formattedTotal
        )
    }
}

@MainActor
final class YearlyTrendsViewModel: ObservableObject {
    let dataPoints: [DataPoint]
    let calendar: Calendar
    let timeZone: TimeZone
    let metric: SiteMetric
    
    private let valueFormatter: StatsValueFormatter
    
    let monthLabels: [String]
    let yearlyTotals: [Int: Int]
    let sortedYears: [Int]
    let maxMonthlyViews: Int
    
    private var monthlyData: [Int: [Int: Int]] = [:] // year -> month -> total views
    
    init(dataPoints: [DataPoint], calendar: Calendar, timeZone: TimeZone, metric: SiteMetric = .views) {
        self.dataPoints = dataPoints
        self.calendar = calendar
        self.timeZone = timeZone
        self.metric = metric
        
        self.valueFormatter = StatsValueFormatter(metric: metric)
        
        // Generate month labels using Calendar
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? Locale.current
        self.monthLabels = formatter.shortMonthSymbols ?? ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Process data points to compute yearly and monthly totals
        var yearlyTotals: [Int: Int] = [:]
        var monthlyData: [Int: [Int: Int]] = [:]
        var maxMonthlyViews = 0
        
        // Configure calendar with the correct time zone
        var localCalendar = calendar
        localCalendar.timeZone = timeZone
        
        for dataPoint in dataPoints {
            let components = localCalendar.dateComponents([.year, .month], from: dataPoint.date)
            guard let year = components.year, let month = components.month else { continue }
            
            // Update yearly total
            yearlyTotals[year, default: 0] += dataPoint.value
            
            // Update monthly total
            if monthlyData[year] == nil {
                monthlyData[year] = [:]
            }
            monthlyData[year]?[month, default: 0] += dataPoint.value
            
            // Track max monthly value
            let monthTotal = monthlyData[year]?[month] ?? 0
            maxMonthlyViews = max(maxMonthlyViews, monthTotal)
        }
        
        self.yearlyTotals = yearlyTotals
        self.monthlyData = monthlyData
        self.sortedYears = yearlyTotals.keys.sorted(by: >)
        self.maxMonthlyViews = max(maxMonthlyViews, 1) // Avoid division by zero
    }
    
    func getMonthlyData(for year: Int) -> [Int] {
        var monthlyViews = Array(repeating: 0, count: 12)
        
        if let yearData = monthlyData[year] {
            for (month, views) in yearData {
                if month >= 1 && month <= 12 {
                    monthlyViews[month - 1] = views
                }
            }
        }
        
        return monthlyViews
    }
    
    func formatValue(_ value: Int) -> String {
        valueFormatter.format(value: value, context: .compact)
    }
    
    func heatmapColor(for intensity: Double) -> Color {
        Constants.heatmapColor(baseColor: metric.primaryColor, intensity: intensity)
    }
}



private struct MonthlyTrendsTooltipView: View {
    let month: String
    let year: Int
    let viewsCount: Int
    let metric: SiteMetric
    let formatter: YearlyTrendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Text("\(month) \(year)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Month value
            HStack(spacing: 6) {
                Circle()
                    .fill(metric.primaryColor)
                    .frame(width: 8, height: 8)
                Text(formatter.formatValue(viewsCount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(metric.localizedTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: Constants.step2) {
            YearlyTrendsView(
                dataPoints: mockDataPoints(),
                calendar: Calendar.current,
                timeZone: TimeZone.current,
                metric: .views
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
