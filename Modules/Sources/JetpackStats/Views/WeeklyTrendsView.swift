import SwiftUI
import WordPressKit

struct WeeklyTrendsView: View {
    let weeks: [Week]
    let calendar: Calendar
    let timeZone: TimeZone
    let metric: SiteMetric = .views
    
    private let cellSpacing: CGFloat = 4
    private let weekLabelWidth: CGFloat = 36

    private var maxValue: Int {
        weeks.flatMap { $0.days }.map { $0.value }.max() ?? 1
    }
    
    private var dayLabels: [String] {
        // Get localized very short weekday symbols from Calendar
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? Locale.current
        
        // Get weekday symbols in the order defined by the calendar's firstWeekday
        let symbols = formatter.veryShortWeekdaySymbols ?? []
        let firstWeekday = calendar.firstWeekday
        
        // Reorder symbols to start with the calendar's first weekday
        let reorderedSymbols = Array(symbols[(firstWeekday - 1)...]) + Array(symbols[..<(firstWeekday - 1)])
        return reorderedSymbols
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
                // Day labels header
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: weekLabelWidth)
                    
                    HStack(spacing: cellSpacing) {
                        ForEach(dayLabels, id: \.self) { day in
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                // Heatmap grid
                VStack(spacing: cellSpacing) {
                    // Show last 4 weeks, 7 days per week
                    ForEach(Array(weeks.prefix(4).enumerated()), id: \.offset) { weekIndex, week in
                        HStack(spacing: 8) {
                            // Week label
                            Text(weekLabel(for: week))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: weekLabelWidth, alignment: .trailing)
                            
                            HStack(spacing: cellSpacing) {
                                // Days in the week
                                ForEach(week.days, id: \.date) { day in
                                    DayCell(
                                        value: day.value,
                                        maxValue: maxValue,
                                        metric: metric
                                    )
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                }
                
                // Legend
            legend
                .padding(.top, Constants.step1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legend: some View {
        HStack(spacing: Constants.step1) {
            Text(Strings.PostDetails.less)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Constants.heatmapColor(baseColor: metric.primaryColor, intensity: Double(level) / 4.0))
                        .frame(width: 16, height: 16)
                }
            }

            Text(Strings.PostDetails.more)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func weekLabel(for week: Week) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = timeZone
        return formatter.string(from: week.startDate)
    }
    
    private func heatmapColor(for intensity: Double) -> Color {
        Constants.heatmapColor(baseColor: metric.primaryColor, intensity: intensity)
    }
}

private struct DayCell: View {
    let value: Int
    let maxValue: Int
    let metric: SiteMetric
    
    private var intensity: Double {
        guard maxValue > 0 else {
            return 0
        }
        return min(1.0, Double(value) / Double(maxValue))
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(heatmapColor)
            .overlay {
                if value > 0 {
                    Text(formattedValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                        .foregroundColor(intensity > 0.75 ? Color(.systemBackground) : .primary)
                }
            }
    }

    private var formattedValue: String {
        StatsValueFormatter(metric: metric).format(value: value, context: .compact)
    }

    private var heatmapColor: Color {
        Constants.heatmapColor(baseColor: metric.primaryColor, intensity: intensity)
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
                timeZone: StatsContext.demo.timeZone
            )
            .padding(Constants.step2)
            .cardStyle()

            WeeklyTrendsView(
                weeks: Array(WeeklyTrendsView.Week.mockHighTraffic.prefix(4)),
                calendar: StatsContext.demo.calendar,
                timeZone: StatsContext.demo.timeZone
            )
            .padding(Constants.step2)
            .cardStyle()

            WeeklyTrendsView(
                weeks: Array(WeeklyTrendsView.Week.mockEmpty.prefix(4)),
                calendar: StatsContext.demo.calendar,
                timeZone: StatsContext.demo.timeZone
            )
            .padding(Constants.step2)
            .cardStyle()
        }
    }
    .background(Constants.Colors.background)
}
