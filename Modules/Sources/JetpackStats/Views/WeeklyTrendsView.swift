import SwiftUI
import WordPressKit

struct WeeklyTrendsView: View {
    let weeks: [Week]
    let context: StatsContext
    
    private let cellSpacing: CGFloat = 4
    private let weekLabelWidth: CGFloat = 36
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    struct Week {
        struct Day {
            let date: Date
            let viewsCount: Int
        }
        
        let startDate: Date
        let days: [Day]
        
        static func make(from breakdown: StatsWeeklyBreakdown, using calendar: Calendar) -> Week? {
            guard let startDate = calendar.date(from: breakdown.startDay) else { return nil }
            
            let days = breakdown.days.compactMap { day -> Day? in
                guard let date = calendar.date(from: day.date) else { return nil }
                return Day(date: date, viewsCount: day.viewsCount)
            }
            
            return Week(startDate: startDate, days: days)
        }
        
        static func make(from breakdowns: [StatsWeeklyBreakdown], using calendar: Calendar) -> [Week] {
            breakdowns.compactMap { make(from: $0, using: calendar) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            StatsCardTitleView(title: Strings.PostDetails.recentWeeks)
            
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
                    // Show last 8 weeks, 7 days per week
                    ForEach(Array(weeks.prefix(8).enumerated()), id: \.offset) { weekIndex, week in
                        HStack(spacing: 8) {
                            // Week label
                            Text(weekLabel(for: week))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: weekLabelWidth, alignment: .trailing)
                            
                            HStack(spacing: cellSpacing) {
                                // Days in the week
                                ForEach(week.days, id: \.date) { day in
                                    DayCell(viewsCount: day.viewsCount)
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                }
                
                // Legend
                HStack(spacing: Constants.step1) {
                    Text(Strings.PostDetails.less)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { level in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(heatmapColor(for: Double(level) / 4.0))
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    Text(Strings.PostDetails.more)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, Constants.step1)
            }
        }
        .padding(Constants.step2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func weekLabel(for week: Week) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = context.timeZone
        
        return formatter.string(from: week.startDate)
    }
    
    private func heatmapColor(for intensity: Double) -> Color {
        Constants.heatmapColor(baseColor: Constants.Colors.blue, intensity: intensity)
    }
}

private struct DayCell: View {
    let viewsCount: Int
    
    // Define max views for normalization (can be adjusted based on data)
    private let maxViews = 200
    
    private var intensity: Double {
        min(1.0, Double(viewsCount) / Double(maxViews))
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(heatmapColor)
            .overlay(
                Text("\(viewsCount)")
                    .font(.caption2)
                    .foregroundColor(intensity > 0.6 ? .white : .primary)
                    .opacity(intensity > 0.3 ? 1 : 0)
            )
    }
    
    private var heatmapColor: Color {
        Constants.heatmapColor(baseColor: Constants.Colors.blue, intensity: intensity)
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
                let weekendMultiplier = (dayOffset == 5 || dayOffset == 6) ? 0.7 : 1.0
                let randomVariation = Double.random(in: 0.8...1.2)
                
                let viewsCount = Int(Double(baseViews) * weekendMultiplier * randomVariation)
                
                return WeeklyTrendsView.Week.Day(date: date, viewsCount: max(0, viewsCount))
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
                        viewsCount: Int.random(in: 150...250)
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
                    WeeklyTrendsView.Week.Day(date: day.date, viewsCount: 0)
                }
            )
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    WeeklyTrendsView(
        weeks: WeeklyTrendsView.Week.mockWeeks(),
        context: StatsContext.demo
    )
    .cardStyle()
    .padding()
}

#Preview("High Traffic") {
    WeeklyTrendsView(
        weeks: WeeklyTrendsView.Week.mockHighTraffic,
        context: StatsContext.demo
    )
    .cardStyle()
    .padding()
}

#Preview("Empty State") {
    WeeklyTrendsView(
        weeks: WeeklyTrendsView.Week.mockEmpty,
        context: StatsContext.demo
    )
    .cardStyle()
    .padding()
}
