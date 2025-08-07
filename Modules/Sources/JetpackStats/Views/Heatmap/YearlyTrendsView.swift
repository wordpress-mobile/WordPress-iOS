import SwiftUI
@preconcurrency import WordPressKit

struct YearlyTrendsView: View {
    let viewModel: YearlyTrendsViewModel

    private let cellSpacing: CGFloat = 6
    private let yearLabelWidth: CGFloat = 40

    init(viewModel: YearlyTrendsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            yearlyHeatmap
            legend
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
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

        HStack(spacing: 8) {
            Text(String(year))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: yearLabelWidth, alignment: .trailing)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
            VStack(spacing: cellSpacing) {
                // First row: Jul-Dec (top)
                HStack(spacing: cellSpacing) {
                    ForEach(6..<12) { index in
                        monthCell(dataPoint: monthlyData[index])
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                // Second row: Jan-Jun (bottom)
                HStack(spacing: cellSpacing) {
                    ForEach(0..<6) { index in
                        monthCell(dataPoint: monthlyData[index])
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
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

final class YearlyTrendsViewModel: ObservableObject {
    let metric: SiteMetric

    private let calendar: Calendar
    private let valueFormatter: StatsValueFormatter

    let sortedYears: [Int]
    let maxMonthlyViews: Int

    private var monthlyData: [Int: [DataPoint]] = [:] // year -> array of 12 DataPoints (Jan=0, Dec=11)

    init(dataPoints: [DataPoint], calendar: Calendar, metric: SiteMetric = .views) {
        self.metric = metric
        self.calendar = calendar

        self.valueFormatter = StatsValueFormatter(metric: metric)

        // Initialize aggregator with the calendar
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Use StatsDataAggregator to aggregate data by month
        let normalizedData = aggregator.aggregate(dataPoints, granularity: .month, metric: metric)

        // Process normalized data into year -> array of 12 months structure
        var monthlyData: [Int: [DataPoint]] = [:]
        var maxMonthlyViews = 0

        // First, collect all years that have data
        var yearsWithData = Set<Int>()
        for (date, _) in normalizedData {
            let components = calendar.dateComponents([.year], from: date)
            if let year = components.year {
                yearsWithData.insert(year)
            }
        }

        // Initialize arrays with empty DataPoints for each year
        for year in yearsWithData {
            var yearData: [DataPoint] = []

            // Create DataPoint for each month
            for month in 1...12 {
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                dateComponents.day = 1

                if let monthDate = calendar.date(from: dateComponents) {
                    yearData.append(DataPoint(date: monthDate, value: 0))
                }
            }

            monthlyData[year] = yearData
        }

        // Fill in actual values
        for (date, value) in normalizedData {
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month, month >= 1 && month <= 12 else { continue }

            // Update the DataPoint with the actual value
            monthlyData[year]?[month - 1] = DataPoint(date: date, value: value)

            // Track max monthly value
            maxMonthlyViews = max(maxMonthlyViews, value)
        }

        self.monthlyData = monthlyData
        // Sort years in descending order and take only the last 5 years
        let allSortedYears = monthlyData.keys.sorted(by: >)
        self.sortedYears = Array(allSortedYears.prefix(4))
        self.maxMonthlyViews = max(maxMonthlyViews, 1) // Avoid division by zero
    }

    func getMonthlyData(for year: Int) -> [DataPoint] {
        guard let yearData = monthlyData[year] else {
            return []
        }
        return yearData
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
                    calendar: Calendar.demo,
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
    let calendar = Calendar.demo

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
