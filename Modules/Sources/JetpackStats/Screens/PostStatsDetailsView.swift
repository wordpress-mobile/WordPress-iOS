import SwiftUI
import UIKit
import WordPressKit

struct PostStatsDetailsView: View {
    let post: TopListData.Post
    
    @Environment(\.context) private var context
    @State private var details: StatsPostDetails?
    @State private var postLikes: PostLikes?
    @State private var dataPoints: [DataPoint] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    init(post: TopListData.Post) {
        self.post = post
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step2) {
                if let details {
                    PostHeaderCard(post: post, details: details, postLikes: postLikes, context: context)
                        .cardStyle()
                    
                    // Views Over Time Chart
                    if !dataPoints.isEmpty {
                        let calendar = Calendar.current
                        let dateRange = calendar.makeDateRange(for: .last7Days)
                        StandaloneChartCard(dataPoints: dataPoints, metric: .views, initialDateRange: dateRange)
                            .cardStyle()
                    }
                    
                    // Peak Performance Card
                    if details.highestMonth != nil || details.highestDayAverage != nil || details.highestWeekAverage != nil {
                        PeakPerformanceCard(details: details)
                            .cardStyle()
                    }
                    
                    // Weekly Trends Chart
                    if !details.recentWeeks.isEmpty {
                        WeeklyTrendsCard(weeks: details.recentWeeks, context: context)
                            .cardStyle()
                    }
                    
                    // Yearly Summary
                    if !details.yearlyTotals.isEmpty {
                        YearlySummaryCard(
                            yearlyTotals: details.yearlyTotals,
                            overallAverages: details.overallAverages,
                            monthlyBreakdown: details.monthlyBreakdown
                        )
                        .cardStyle()
                    }
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .cardStyle()
                } else if let error {
                    SimpleErrorView(error: error)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .cardStyle()
                }
            }
            .padding(.vertical, Constants.step1)
        }
        .background(Constants.Colors.statsBackground)
        .navigationTitle(Strings.PostDetails.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPostDetails()
        }
    }
    
    private func loadPostDetails() async {
        guard let postId = post.postId, let postIdInt = Int(postId) else { return }
        
        async let detailsTask = context.service.getPostDetails(for: postIdInt)
        async let likesTask: PostLikes? = {
            if (post.metrics.likes ?? 0) > 0 {
                return try? await context.service.getPostLikes(for: postIdInt, count: 20)
            }
            return nil
        }()
        
        do {
            let (details, likes) = try await (detailsTask, likesTask)
            self.details = details
            self.postLikes = likes
            
            // Convert data to DataPoints using site timezone
            self.dataPoints = convertToDataPoints(from: details.data)
            
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }
    
    private func convertToDataPoints(from data: [StatsPostViews]) -> [DataPoint] {
        // Convert StatsPostViews to DataPoints using the site timezone
        return data.compactMap { postView in
            // Convert DateComponents to Date using site timezone (similar to how StatsService does it)
            var calendar = context.calendar
            calendar.timeZone = context.timeZone
            
            guard let date = calendar.date(from: postView.date) else { return nil }
            return DataPoint(date: date, value: postView.viewsCount)
        }
    }
}

private struct PostHeaderCard: View {
    let post: TopListData.Post
    let details: StatsPostDetails
    let postLikes: PostLikes?
    let context: StatsContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                if let dateGMT = details.post?.dateGMT {
                    HStack(spacing: 6) {
                        Text(Strings.PostDetails.published(formatPublishedDate(dateGMT)))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Permalink button
                        if let permalink = details.post?.permalink, let url = URL(string: permalink) {
                            Button(action: {
                                UIApplication.shared.open(url)
                            }) {
                                Image(systemName: "link")
                                    .font(.footnote)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }

                // Likes strip
                if let postLikes, !postLikes.users.isEmpty {
                    PostLikesStrip(likes: postLikes)
                        .padding(.top, Constants.step2)
                }
            }

            Divider()

            // Metrics with visual separation
            HStack(spacing: Constants.step3) {
                MetricView(metric: .views, value: details.totalViewsCount)
                if let likesCount = post.metrics.likes {
                    MetricView(metric: .likes, value: likesCount)
                }
                if let commentCount = details.post?.commentCount, let count = Int(commentCount) {
                    MetricView(metric: .comments, value: count)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: Constants.step2, leading: Constants.step2, bottom: Constants.step1, trailing: Constants.step2))
    }
    
    private func formatPublishedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = context.timeZone
        return formatter.string(from: date)
    }
}

private struct MetricView: View {
    let metric: SiteMetric
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: metric.systemImage)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)

                Text(metric.localizedTitle.uppercased())
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }

            Text(StatsValueFormatter(metric: metric).format(value: value))
                .contentTransition(.numericText())
                .animation(.spring, value: value)
                .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                .foregroundColor(.primary)
        }
        .lineLimit(1)
        .frame(minWidth: 78, alignment: .leading)
    }
}

private struct PostLikesStrip: View {
    let likes: PostLikes
    
    private let avatarSize: CGFloat = 28
    private let maxVisibleAvatars = 5
    
    var body: some View {
        HStack {
            // Overlapping avatars
            HStack(spacing: -8) {
                ForEach(likes.users.prefix(maxVisibleAvatars)) { user in
                    AvatarView(name: user.name, imageURL: user.avatarURL, size: avatarSize)
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                        )
                }
                
                // Show additional count if there are more users
                if likes.totalCount > maxVisibleAvatars {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Text("+\(likes.totalCount - maxVisibleAvatars)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                        )
                }
            }
            
            Spacer()
            
            // Likes button
            Button(action: {
                // TODO: Navigate to likes detail screen
            }) {
                HStack(spacing: 4) {
                    Text(Strings.PostDetails.likesCount(likes.totalCount))
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary.opacity(0.66))
                }
            }
        }
    }
}

private struct PeakPerformanceCard: View {
    let details: StatsPostDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            StatsCardTitleView(title: Strings.PostDetails.peakPerformance)
            
            VStack(spacing: Constants.step1) {
                if let highestMonth = details.highestMonth {
                    HStack {
                        Text(Strings.PostDetails.bestMonth)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(StatsValueFormatter.formatNumber(highestMonth))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                
                if let highestDayAverage = details.highestDayAverage {
                    HStack {
                        Text(Strings.PostDetails.bestDayAverage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(StatsValueFormatter.formatNumber(highestDayAverage))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                
                if let highestWeekAverage = details.highestWeekAverage {
                    HStack {
                        Text(Strings.PostDetails.bestWeekAverage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(StatsValueFormatter.formatNumber(highestWeekAverage))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(Constants.step2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WeeklyTrendsCard: View {
    let weeks: [StatsWeeklyBreakdown]
    let context: StatsContext
    
    private let cellSpacing: CGFloat = 4
    private let weekLabelWidth: CGFloat = 36
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
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
    
    private func weekLabel(for week: StatsWeeklyBreakdown) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.timeZone = context.timeZone
        
        guard let startDate = context.calendar.date(from: week.startDay) else { return "" }
        return formatter.string(from: startDate)
    }
    
    private func heatmapColor(for intensity: Double) -> Color {
        // Use ColorStudio blue gradient
        if intensity < 0.25 {
            return Constants.Colors.blue.opacity(0.2)
        } else if intensity < 0.5 {
            return Constants.Colors.blue.opacity(0.4)
        } else if intensity < 0.75 {
            return Constants.Colors.blue.opacity(0.6)
        } else {
            return Constants.Colors.blue.opacity(0.85)
        }
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
        if viewsCount == 0 {
            return Color(UIColor.systemGray6)
        }
        
        // Use ColorStudio blue gradient
        if intensity < 0.25 {
            return Constants.Colors.blue.opacity(0.2)
        } else if intensity < 0.5 {
            return Constants.Colors.blue.opacity(0.4)
        } else if intensity < 0.75 {
            return Constants.Colors.blue.opacity(0.6)
        } else {
            return Constants.Colors.blue.opacity(0.85)
        }
    }
}

private struct YearlySummaryCard: View {
    let yearlyTotals: [Int: Int]
    let overallAverages: [Int: Int]
    let monthlyBreakdown: [StatsPostViews]
    
    private let cellSpacing: CGFloat = 6
    private let monthNames = [
        ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
        ["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            StatsCardTitleView(title: Strings.PostDetails.monthlyActivity)
            
            // Year sections
            let sortedYears = yearlyTotals.keys.sorted(by: >).prefix(3)
            let maxMonthlyViews = monthlyBreakdown.map(\.viewsCount).max() ?? 5000
            
            VStack(spacing: Constants.step3) {
                ForEach(sortedYears, id: \.self) { year in
                    YearSection(
                        year: year,
                        monthlyData: getMonthlyData(for: year),
                        maxViews: maxMonthlyViews,
                        yearTotal: yearlyTotals[year] ?? 0,
                        previousYearTotal: yearlyTotals[year - 1]
                    )

                    if year != sortedYears.last {
                        Divider()
                    }
                }
            }
            
            // Legend
            HStack(spacing: Constants.step2) {
                HStack(spacing: Constants.step1) {
                    Text(Strings.PostDetails.less)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 3) {
                        ForEach(0..<5) { level in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(heatmapColor(for: Double(level) / 4.0))
                                .frame(width: 16, height: 16)
                        }
                    }
                    
                    Text(Strings.PostDetails.more)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, Constants.step1)
        }
        .padding(Constants.step2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getMonthlyData(for year: Int) -> [Int] {
        var monthlyViews = Array(repeating: 0, count: 12)
        
        for postView in monthlyBreakdown {
            if postView.date.year == year,
               let month = postView.date.month,
               month >= 1 && month <= 12 {
                monthlyViews[month - 1] = postView.viewsCount
            }
        }
        
        return monthlyViews
    }
    
    private func heatmapColor(for intensity: Double) -> Color {
        if intensity == 0 {
            return Color(.secondarySystemBackground)
        }
        
        // Use ColorStudio blue gradient
        if intensity < 0.25 {
            return Constants.Colors.blue.opacity(0.2)
        } else if intensity < 0.5 {
            return Constants.Colors.blue.opacity(0.4)
        } else if intensity < 0.75 {
            return Constants.Colors.blue.opacity(0.6)
        } else {
            return Constants.Colors.blue.opacity(0.85)
        }
    }
}

private struct YearSection: View {
    let year: Int
    let monthlyData: [Int]
    let maxViews: Int
    let yearTotal: Int
    let previousYearTotal: Int?
    
    private let cellSpacing: CGFloat = 6
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.step1) {
            // Year header with total and growth
            HStack(alignment: .center) {
                Text(String(year))
                    .font(.headline)

                Spacer()

                Text(StatsValueFormatter.formatNumber(yearTotal))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                

                if let previousTotal = previousYearTotal, previousTotal > 0 {
                    BadgeTrendIndicator(
                        trend: TrendViewModel(
                            currentValue: yearTotal,
                            previousValue: previousTotal,
                            metric: .views
                        )
                    )
                }
            }
            
            // Two-column grid
            VStack(spacing: cellSpacing) {
                // First row (Jan-Jun)
                HStack(spacing: cellSpacing) {
                    ForEach(0..<6) { index in
                        MonthCellExpanded(
                            month: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"][index],
                            viewsCount: monthlyData[index],
                            maxViews: maxViews
                        )
                    }
                }
                
                // Second row (Jul-Dec)
                HStack(spacing: cellSpacing) {
                    ForEach(6..<12) { index in
                        MonthCellExpanded(
                            month: ["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][index - 6],
                            viewsCount: monthlyData[index],
                            maxViews: maxViews
                        )
                    }
                }
            }
        }
    }
}

private struct MonthCellExpanded: View {
    let month: String
    let viewsCount: Int
    let maxViews: Int
    
    private var intensity: Double {
        min(1.0, Double(viewsCount) / Double(maxViews))
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(month)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(heatmapColor)
                .frame(height: 44)
                .overlay(
                    Text(StatsValueFormatter.formatNumber(viewsCount))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(intensity > 0.6 ? .white : .primary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    private var heatmapColor: Color {
        if viewsCount == 0 {
            return Color(UIColor.systemGray6)
        }
        
        // Use ColorStudio blue gradient
        if intensity < 0.25 {
            return Constants.Colors.blue.opacity(0.2)
        } else if intensity < 0.5 {
            return Constants.Colors.blue.opacity(0.4)
        } else if intensity < 0.75 {
            return Constants.Colors.blue.opacity(0.6)
        } else {
            return Constants.Colors.blue.opacity(0.85)
        }
    }
}




#Preview {
    NavigationStack {
        PostStatsDetailsView(
            post: .init(
                title: "Matter Smart Home Protocol Still Doesn't Matter: A Year Later",
                postId: "12345",
                date: .now,
                pageId: nil,
                type: "post",
                author: nil,
                metrics: .init(views: 45892, likes: 26, comments: 487)
            )
        )
        .environment(\.context, StatsContext.demo)
    }
}
