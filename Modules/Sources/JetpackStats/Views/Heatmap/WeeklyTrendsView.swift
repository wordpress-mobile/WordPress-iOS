import SwiftUI
@preconcurrency import WordPressKit

struct WeeklyTrendsView: View {
    let viewModel: WeeklyTrendsViewModel

    private let cellSpacing: CGFloat = 4
    private let weekLabelWidth: CGFloat = 40

    @State private var selectedDay: DataPoint?
    @State private var selectedWeek: Week?

    init(viewModel: WeeklyTrendsViewModel) {
        self.viewModel = viewModel
    }

    struct Week {
        let startDate: Date
        let days: [DataPoint]
        let averagePerDay: Int

        static func make(from breakdown: StatsWeeklyBreakdown, using calendar: Calendar) -> Week? {
            guard let startDate = calendar.date(from: breakdown.startDay) else { return nil }

            let days = breakdown.days.compactMap { day -> DataPoint? in
                guard let date = calendar.date(from: day.date) else { return nil }
                return DataPoint(date: date, value: day.viewsCount)
            }

            return Week(startDate: startDate, days: days, averagePerDay: 0)
        }

        static func make(from breakdowns: [StatsWeeklyBreakdown], using calendar: Calendar) -> [Week] {
            breakdowns.compactMap { make(from: $0, using: calendar) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: cellSpacing) {
            header
            heatmap
            legend
                .padding(.top, Constants.step1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var header: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: weekLabelWidth)

            HStack(spacing: cellSpacing) {
                ForEach(viewModel.dayLabels, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var heatmap: some View {
        VStack(spacing: cellSpacing) {
            // Show last 4 weeks, 7 days per week
            ForEach(Array(viewModel.weeks.prefix(4).enumerated()), id: \.offset) { weekIndex, week in
                HStack(spacing: 8) {
                    // Week label
                    Text(viewModel.weekLabel(for: week))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: weekLabelWidth, alignment: .trailing)
                        .dynamicTypeSize(...DynamicTypeSize.large)

                    HStack(spacing: cellSpacing) {
                        // Days in the week
                        ForEach(week.days, id: \.date) { day in
                            DayCell(
                                day: day,
                                week: week,
                                previousWeek: viewModel.previousWeek(for: week),
                                maxValue: viewModel.maxValue,
                                metric: viewModel.metric,
                                formatter: viewModel,
                                calendar: viewModel.calendar
                            )
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                        }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HeatmapLegendView(metric: viewModel.metric, labelWidth: weekLabelWidth)
    }
}

final class WeeklyTrendsViewModel: ObservableObject {
    let weeks: [WeeklyTrendsView.Week]
    let calendar: Calendar
    let metric: SiteMetric

    private let valueFormatter: StatsValueFormatter
    private let weekFormatter: DateFormatter
    private let aggregator: StatsDataAggregator

    let dayLabels: [String]
    let maxValue: Int

    init(dataPoints: [DataPoint], calendar: Calendar, metric: SiteMetric = .views) {
        self.calendar = calendar
        self.metric = metric

        // Initialize aggregator
        self.aggregator = StatsDataAggregator(calendar: calendar)

        // Initialize formatters
        self.valueFormatter = StatsValueFormatter(metric: metric)

        self.weekFormatter = DateFormatter()
        self.weekFormatter.dateFormat = "MMM d"
        self.weekFormatter.calendar = calendar
        self.weekFormatter.timeZone = calendar.timeZone

        // Cache day labels
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? Locale.current

        // Get weekday symbols in the order defined by the calendar's firstWeekday
        let symbols = formatter.veryShortWeekdaySymbols ?? []
        let firstWeekday = calendar.firstWeekday

        // Reorder symbols to start with the calendar's first weekday
        let reorderedSymbols = Array(symbols[(firstWeekday - 1)...]) + Array(symbols[..<(firstWeekday - 1)])
        self.dayLabels = reorderedSymbols

        // Process data points into weeks
        let allWeeks = Self.processDataIntoWeeks(dataPoints: dataPoints, calendar: calendar, metric: metric)

        // Keep only the most recent 5 weeks
        self.weeks = Array(allWeeks.prefix(5))

        // Calculate max value once
        self.maxValue = self.weeks.flatMap { $0.days }.map { $0.value }.max() ?? 1
    }

    private static func processDataIntoWeeks(dataPoints: [DataPoint], calendar: Calendar, metric: SiteMetric) -> [WeeklyTrendsView.Week] {
        guard !dataPoints.isEmpty else { return [] }

        // Group data points by week
        var weeklyData: [Date: [DataPoint]] = [:]

        for dataPoint in dataPoints {
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: dataPoint.date)?.start ?? dataPoint.date
            weeklyData[startOfWeek, default: []].append(dataPoint)
        }

        // Create Week objects with sorted days and calculated average
        let weeks = weeklyData.map { startDate, days in
            // Create a dictionary of existing data points by date
            var daysByDate: [Date: DataPoint] = [:]
            for day in days {
                // Normalize to start of day to avoid time component issues
                let normalizedDate = calendar.startOfDay(for: day.date)
                daysByDate[normalizedDate] = day
            }

            // Fill in all 7 days of the week
            var completeDays: [DataPoint] = []
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    let normalizedDate = calendar.startOfDay(for: date)
                    if let existingDay = daysByDate[normalizedDate] {
                        completeDays.append(existingDay)
                    } else {
                        // Add empty day with 0 value
                        completeDays.append(DataPoint(date: date, value: 0))
                    }
                }
            }

            let weekTotal = DataPoint.getTotalValue(for: completeDays, metric: metric) ?? 0
            let averagePerDay: Int
            if completeDays.isEmpty {
                averagePerDay = 0
            } else if metric.aggregationStrategy == .average {
                averagePerDay = weekTotal
            } else {
                averagePerDay = weekTotal / completeDays.count
            }
            return WeeklyTrendsView.Week(startDate: startDate, days: completeDays, averagePerDay: averagePerDay)
        }

        // Sort weeks by start date (most recent first)
        return weeks.sorted { $0.startDate > $1.startDate }
    }

    func weekLabel(for week: WeeklyTrendsView.Week) -> String {
        weekFormatter.string(from: week.startDate)
    }

    func formatValue(_ value: Int) -> String {
        valueFormatter.format(value: value, context: .compact)
    }

    func previousWeek(for week: WeeklyTrendsView.Week) -> WeeklyTrendsView.Week? {
        guard let weekIndex = weeks.firstIndex(where: { $0.startDate == week.startDate }),
              weekIndex < weeks.count - 1 else {
            return nil
        }
        return weeks[weekIndex + 1]
    }
}

private struct DayCell: View {
    let day: DataPoint
    let week: WeeklyTrendsView.Week
    let previousWeek: WeeklyTrendsView.Week?
    let maxValue: Int
    let metric: SiteMetric
    let formatter: WeeklyTrendsViewModel
    let calendar: Calendar

    @State private var showingPopover = false

    private var value: Int { day.value }

    private var intensity: Double {
        guard maxValue > 0 else {
            return 0
        }
        return min(1.0, Double(value) / Double(maxValue))
    }

    var body: some View {
        HeatmapCellView(
            value: value,
            metric: metric,
            maxValue: maxValue
        )
        .onTapGesture {
            showingPopover = true
        }
        .popover(isPresented: $showingPopover) {
            WeeklyTrendsTooltipView(
                day: day,
                week: week,
                previousWeek: previousWeek,
                metric: metric,
                calendar: calendar,
                formatter: formatter
            )
            .modifier(PopoverPresentationModifier())
        }
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.calendar = calendar

        let dateString = dateFormatter.string(from: day.date)
        let valueString = formatter.formatValue(value)

        return "\(dateString), \(valueString) \(metric.localizedTitle)"
    }
}

private struct WeeklyTrendsTooltipView: View {
    let day: DataPoint
    let week: WeeklyTrendsView.Week
    let previousWeek: WeeklyTrendsView.Week?
    let metric: SiteMetric
    let calendar: Calendar
    let formatter: WeeklyTrendsViewModel

    private var weekTotal: Int? {
        week.days.isEmpty ? nil : DataPoint.getTotalValue(for: week.days, metric: metric)
    }

    private var previousWeekTotal: Int? {
        guard let previousWeek else { return nil }
        return previousWeek.days.isEmpty ? nil : DataPoint.getTotalValue(for: previousWeek.days, metric: metric)
    }

    private var averagePerDay: Int {
        week.averagePerDay
    }

    private var trendViewModel: TrendViewModel? {
        guard let weekTotal,
              let previousWeekTotal else {
            return nil
        }
        return TrendViewModel(
            currentValue: weekTotal,
            previousValue: previousWeekTotal,
            metric: metric,
            context: .regular
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date header
            Text(formattedDate)
                .font(.subheadline)
                .fontWeight(.semibold)

            // Day value
            HStack(spacing: 6) {
                Circle()
                    .fill(metric.primaryColor)
                    .frame(width: 8, height: 8)
                Text(formatter.formatValue(day.value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(metric.localizedTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Week stats
            VStack(alignment: .leading, spacing: 4) {
                // Week total
                if let weekTotal {
                    HStack(spacing: 4) {
                        Text(Strings.PostDetails.weekTotal)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatter.formatValue(weekTotal))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                // Average per day
                HStack(spacing: 4) {
                    Text(Strings.PostDetails.dailyAverage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatter.formatValue(averagePerDay))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                // Week-over-week change
                if let trendViewModel,
                   let weekTotal,
                   let previousWeekTotal,
                   weekTotal != previousWeekTotal {
                    HStack(spacing: 4) {
                        Text(Strings.PostDetails.weekOverWeek)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(trendViewModel.tooltipFormattedTrend)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(trendViewModel.sentiment.foregroundColor)
                    }
                }
            }
        }
        .padding()
    }

    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateFormatter.calendar = calendar
        return dateFormatter.string(from: day.date)
    }
}

private extension TrendViewModel {
    /// A completed formatted trend with the absolute change and the percentage change.
    var tooltipFormattedTrend: String {
        "\(iconSign) \(formattedPercentage)  \(formattedChange)"
    }
}

// MARK: - Mock Data

extension WeeklyTrendsViewModel {
    @MainActor
    static let mock = WeeklyTrendsViewModel(dataPoints: mockDataPoints(), calendar: .demo)
}

private func mockDataPoints(weeks: Int = 4) -> [DataPoint] {
    let calendar = Calendar.demo
    let today = Date()
    var dataPoints: [DataPoint] = []

    for weekOffset in 0..<weeks {
        let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today)!
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)!.start

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!

            // Generate realistic view counts with patterns
            let baseViews = Int.random(in: 20...150)
            let isWeekend = calendar.isDateInWeekend(date)
            let weekendMultiplier = isWeekend ? 0.7 : 1.0
            let randomVariation = Double.random(in: 0.8...1.2)
            let viewsCount = Int(Double(baseViews) * weekendMultiplier * randomVariation)

            dataPoints.append(DataPoint(date: date, value: max(0, viewsCount)))
        }
    }

    return dataPoints
}

private func mockHighTrafficDataPoints(weeks: Int = 4) -> [DataPoint] {
    mockDataPoints(weeks: weeks).map { dataPoint in
        DataPoint(date: dataPoint.date, value: Int.random(in: 150...250))
    }
}

private func mockEmptyDataPoints(weeks: Int = 4) -> [DataPoint] {
    mockDataPoints(weeks: weeks).map { dataPoint in
        DataPoint(date: dataPoint.date, value: 0)
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: Constants.step2) {
            WeeklyTrendsView(
                viewModel: WeeklyTrendsViewModel(
                    dataPoints: mockDataPoints(),
                    calendar: StatsContext.demo.calendar,
                    metric: .views
                )
            )
            .padding(Constants.step2)
            .cardStyle()

            WeeklyTrendsView(
                viewModel: WeeklyTrendsViewModel(
                    dataPoints: mockHighTrafficDataPoints(),
                    calendar: StatsContext.demo.calendar,
                    metric: .views
                )
            )
            .padding(Constants.step2)
            .cardStyle()

            WeeklyTrendsView(
                viewModel: WeeklyTrendsViewModel(
                    dataPoints: mockEmptyDataPoints(),
                    calendar: StatsContext.demo.calendar,
                    metric: .views
                )
            )
            .padding(Constants.step2)
            .cardStyle()
        }
    }
    .background(Constants.Colors.background)
}
