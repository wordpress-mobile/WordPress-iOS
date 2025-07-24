import SwiftUI
import WordPressKit

struct WeeklyTrendsView: View {
    let viewModel: WeeklyTrendsViewModel
    
    private let cellSpacing: CGFloat = 4
    private let weekLabelWidth: CGFloat = 36
    
    @State private var selectedDay: Week.Day?
    @State private var selectedWeek: Week?
    
    init(weeks: [Week], calendar: Calendar, timeZone: TimeZone, metric: SiteMetric = .views) {
        self.viewModel = WeeklyTrendsViewModel(
            weeks: weeks,
            calendar: calendar,
            timeZone: timeZone,
            metric: metric
        )
    }
    
    struct Week {
        struct Day {
            let date: Date
            let value: Int
        }
        
        let startDate: Date
        let days: [Day]
        
        static func make(from breakdown: StatsWeeklyBreakdown, using calendar: Calendar) -> Week? {
            guard let startDate = calendar.date(from: breakdown.startDay) else { return nil }
            
            let days = breakdown.days.compactMap { day -> Day? in
                guard let date = calendar.date(from: day.date) else { return nil }
                return Day(date: date, value: day.viewsCount)
            }
            
            return Week(startDate: startDate, days: days)
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
        .accessibilityLabel(accessibilityLabel)
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
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HeatmapLegendView(metric: viewModel.metric, labelWidth: weekLabelWidth)
    }


    private var accessibilityLabel: String {
        let weeksCount = min(viewModel.weeks.count, 4)
        let totalValue = viewModel.weeks.prefix(4).flatMap { $0.days }.reduce(0) { $0 + $1.value }
        let formattedTotal = viewModel.formatValue(totalValue)

        return Strings.PostDetails.weeklyActivityAccessibility(weeksCount: weeksCount, metric: viewModel.metric.localizedTitle, total: formattedTotal)
    }
}

@MainActor
final class WeeklyTrendsViewModel: ObservableObject {
    let weeks: [WeeklyTrendsView.Week]
    let calendar: Calendar
    let timeZone: TimeZone
    let metric: SiteMetric

    private let valueFormatter: StatsValueFormatter
    private let weekFormatter: DateFormatter

    let dayLabels: [String]
    let maxValue: Int

    init(weeks: [WeeklyTrendsView.Week], calendar: Calendar, timeZone: TimeZone, metric: SiteMetric = .views) {
        self.weeks = weeks
        self.calendar = calendar
        self.timeZone = timeZone
        self.metric = metric

        // Initialize formatters
        self.valueFormatter = StatsValueFormatter(metric: metric)

        self.weekFormatter = DateFormatter()
        self.weekFormatter.dateFormat = "MMM d"
        self.weekFormatter.timeZone = timeZone

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

        // Calculate max value once
        self.maxValue = weeks.flatMap { $0.days }.map { $0.value }.max() ?? 1
    }

    func weekLabel(for week: WeeklyTrendsView.Week) -> String {
        weekFormatter.string(from: week.startDate)
    }

    func formatValue(_ value: Int) -> String {
        valueFormatter.format(value: value, context: .compact)
    }

    func heatmapColor(for intensity: Double) -> Color {
        Constants.heatmapColor(baseColor: metric.primaryColor, intensity: intensity)
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
    let day: WeeklyTrendsView.Week.Day
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
        .accessibilityLabel(accessibilityLabel)
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
    let day: WeeklyTrendsView.Week.Day
    let week: WeeklyTrendsView.Week
    let previousWeek: WeeklyTrendsView.Week?
    let metric: SiteMetric
    let calendar: Calendar
    let formatter: WeeklyTrendsViewModel
    
    private var weekTotal: Int {
        week.days.reduce(0) { $0 + $1.value }
    }
    
    private var previousWeekTotal: Int {
        previousWeek?.days.reduce(0) { $0 + $1.value } ?? 0
    }
    
    private var averagePerDay: Int {
        week.days.isEmpty ? 0 : weekTotal / week.days.count
    }
    
    private var trendViewModel: TrendViewModel {
        TrendViewModel(
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
                HStack(spacing: 4) {
                    Text(Strings.PostDetails.weekTotal)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatter.formatValue(weekTotal))
                        .font(.caption)
                        .fontWeight(.medium)
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
                if previousWeek != nil && (weekTotal != previousWeekTotal) {
                    HStack(spacing: 4) {
                        Text(Strings.PostDetails.weekOverWeek)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(trendViewModel.formattedTrendShort)
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

// MARK: - Mock Data

extension WeeklyTrendsView.Week {
    static func mockWeeks(count: Int = 8) -> [WeeklyTrendsView.Week] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<count).map { weekOffset in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today)!
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)!.start
            
            let days = (0..<7).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
                
                // Generate realistic view counts with patterns
                let baseViews = Int.random(in: 20...150)
                
                // Determine if this is a weekend based on the calendar
                let isWeekend = calendar.isDateInWeekend(date)
                let weekendMultiplier = isWeekend ? 0.7 : 1.0
                
                let randomVariation = Double.random(in: 0.8...1.2)
                let viewsCount = Int(Double(baseViews) * weekendMultiplier * randomVariation)
                
                return WeeklyTrendsView.Week.Day(date: date, value: max(0, viewsCount))
            }
            
            return WeeklyTrendsView.Week(startDate: startOfWeek, days: days)
        }.reversed()
    }
    
    static var mockHighTraffic: [WeeklyTrendsView.Week] {
        mockWeeks(count: 8).map { week in
            WeeklyTrendsView.Week(
                startDate: week.startDate,
                days: week.days.map { day in
                    WeeklyTrendsView.Week.Day(
                        date: day.date,
                        value: Int.random(in: 150...250)
                    )
                }
            )
        }
    }
    
    static var mockEmpty: [WeeklyTrendsView.Week] {
        mockWeeks(count: 8).map { week in
            WeeklyTrendsView.Week(
                startDate: week.startDate,
                days: week.days.map { day in
                    WeeklyTrendsView.Week.Day(date: day.date, value: 0)
                }
            )
        }
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: Constants.step2) {
            WeeklyTrendsView(
                weeks: WeeklyTrendsView.Week.mockWeeks(count: 4),
                calendar: StatsContext.demo.calendar,
                timeZone: StatsContext.demo.timeZone,
                metric: .views
            )
            .padding(Constants.step2)
            .cardStyle()

            WeeklyTrendsView(
                weeks: Array(WeeklyTrendsView.Week.mockHighTraffic.prefix(4)),
                calendar: StatsContext.demo.calendar,
                timeZone: StatsContext.demo.timeZone,
                metric: .views
            )
            .padding(Constants.step2)
            .cardStyle()

            WeeklyTrendsView(
                weeks: Array(WeeklyTrendsView.Week.mockEmpty.prefix(4)),
                calendar: StatsContext.demo.calendar,
                timeZone: StatsContext.demo.timeZone,
                metric: .views
            )
            .padding(Constants.step2)
            .cardStyle()
        }
    }
    .background(Constants.Colors.background)
}
