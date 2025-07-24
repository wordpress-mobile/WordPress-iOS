import SwiftUI
import UIKit
import WordPressKit

struct PostStatsDetailsView: View {
    let post: TopListData.Post
    
    @Environment(\.context) private var context
    @State private var details: StatsPostDetails?
    @State private var postLikes: PostLikesData?
    @State private var dataPoints: [DataPoint] = []
    @State private var isLoading = true
    @State private var error: Error?

    private let initialDateRange: StatsDateRange

    init(post: TopListData.Post, dateRange: StatsDateRange) {
        self.post = post
        self.initialDateRange = dateRange
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step2) {
                contents
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

#warning("TEMP")

    @ViewBuilder
    private var contents: some View {
        headerView
            .cardStyle()

//        // Views Over Time Chart
//        if !dataPoints.isEmpty {
//            makeChartView(dataPoints: dataPoints)
//        } else if isLoading {
//            makeChartView(dataPoints: mockDataPoints)
//                .redacted(reason: .placeholder)
//        }

        if let details {
            // Peak Performance Card
//            if details.highestMonth != nil || details.highestDayAverage != nil || details.highestWeekAverage != nil {
//                PeakPerformanceCard(details: details)
//                    .cardStyle()
//            }

            // Weekly Trends Chart
            if !details.recentWeeks.isEmpty {
                WeeklyTrendsView(
                    weeks: WeeklyTrendsView.Week.make(from: details.recentWeeks, using: context.calendar),
                    context: context
                )
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
        }
    }

    private func makeChartView(dataPoints: [DataPoint]) -> some View {
        StandaloneChartCard(
            dataPoints: dataPoints,
            metric: .views,
            initialDateRange: initialDateRange,
            configuration: .init(minimumGranularity: .day)
        )
        .cardStyle()
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            postDetailsView

            if let postLikes {
                PostLikesStripView(likes: postLikes)
            } else if isLoading {
                PostLikesStripView(likes: .mock)
                    .redacted(reason: .placeholder)
            }

            Divider()

            if let metrics {
                PostStatsMetricsStripView(metrics: metrics)
            } else if isLoading {
                PostStatsMetricsStripView(metrics: .mock)
                    .redacted(reason: .placeholder)
            } else if let error {
                SimpleErrorView(error: error)
                    .frame(minHeight: 200)

            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: Constants.step2, leading: Constants.step2, bottom: Constants.step1, trailing: Constants.step2))
    }

    private var postDetailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            if let dateGMT = post.date ?? details?.post?.dateGMT {
                HStack(spacing: 6) {
                    Text(Strings.PostDetails.published(formatPublishedDate(dateGMT)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Permalink button
                    if let postURL = post.postURL ?? details?.post?.permalink.flatMap(URL.init) {
                        Link(destination: postURL) {
                            Image(systemName: "link")
                                .font(.footnote)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data

    private var metrics: SiteMetricsSet? {
        guard let details else {
            return nil
        }
        return SiteMetricsSet(
            views: details.totalViewsCount,
            likes: postLikes?.totalCount,
            comments: details.post?.commentCount.flatMap { Int($0) }
        )
    }

    private func formatPublishedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = context.timeZone
        return formatter.string(from: date)
    }

    private func loadPostDetails() async {
        guard let postId = post.postID, let postIdInt = Int(postId) else {
            self.error = URLError(.unknown, userInfo: [NSLocalizedDescriptionKey: Strings.Errors.generic])
            self.isLoading = false
            return
        }

        async let detailsTask = context.service.getPostDetails(for: postIdInt)
        async let likesTask: PostLikesData? = {
            try? await context.service.getPostLikes(for: postIdInt, count: 20)
        }()

        do {
            let (details, likes) = try await (detailsTask, likesTask)
            withAnimation(.spring) {
                self.details = details
                self.postLikes = likes
                self.dataPoints = convertToDataPoints(from: details.data)
                self.isLoading = false
            }
        } catch {
            withAnimation(.spring) {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    private func convertToDataPoints(from data: [StatsPostViews]) -> [DataPoint] {
        // Convert DateComponents to Date using site timezone (similar to how StatsService does it)
        var calendar = context.calendar
        calendar.timeZone = context.timeZone

        // Convert StatsPostViews to DataPoints using the site timezone
        return data.compactMap { postView in
            guard let date = calendar.date(from: postView.date) else { return nil }
            return DataPoint(date: date, value: postView.viewsCount)
        }
    }

    private var mockDataPoints: [DataPoint] {
        ChartData.mock(
            metric: .views,
            granularity: initialDateRange.dateInterval.preferredGranularity,
            range: initialDateRange
        ).currentData
    }
}

private struct PostStatsMetricsStripView: View {
    let metrics: SiteMetricsSet

    var body: some View {
        HStack(spacing: Constants.step2) {
            ForEach([SiteMetric.views, .likes, .comments]) { metric in
                MetricView(metric: metric, value: metrics[metric])
            }
        }
    }

    struct MetricView: View {
        let metric: SiteMetric
        let value: Int?

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

                Text(formattedValue)
                    .contentTransition(.numericText())
                    .animation(.spring, value: value)
                    .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                    .foregroundColor(.primary)
            }
            .lineLimit(1)
            .frame(minWidth: 78, alignment: .leading)
        }

        var formattedValue: String {
            guard let value else {
                return "–"
            }
            return StatsValueFormatter(metric: metric).format(value: value)
        }
    }
}

private struct PostLikesStripView: View {
    let likes: PostLikesData
    
    private let avatarSize: CGFloat = 28
    private let maxVisibleAvatars = 6

    var body: some View {
        if likes.users.isEmpty {
            emptyStateView
        } else {
            HStack {
                avatars
                Spacer()
                viewMore
            }
        }
    }

    // Overlapping avatars
    private var avatars: some View {
        HStack(spacing: -8) {
            ForEach(likes.users.prefix(maxVisibleAvatars)) { user in
                AvatarView(name: user.name, imageURL: user.avatarURL, size: avatarSize, backgroundColor: Color(.secondarySystemBackground))
                    .overlay(
                        Circle()
                            .stroke(Color(UIColor.systemBackground), lineWidth: 1)
                    )
            }

            // Show additional count if there are more users
            if likes.totalCount > maxVisibleAvatars {
                Text("+\((likes.totalCount - maxVisibleAvatars).formatted(.number.notation(.compactName)))")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal, 4)
                    .frame(height: avatarSize + 2)
                    .frame(minWidth: avatarSize + 2)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.secondarySystemBackground))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(UIColor.systemBackground), lineWidth: 1)
                    )
            }
        }
    }

    private var viewMore: some View {
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

    private var emptyStateView: some View {
        HStack {
            HStack(spacing: -8) {
                ForEach(0...2, id: \.self) { _ in
                    Circle()
                        .frame(width: avatarSize, height: avatarSize)
                        .foregroundStyle(Color(.secondarySystemBackground))
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor.systemBackground), lineWidth: 1)
                        )
                }
            }
            Text(Strings.PostDetails.noLikesYet)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .lineLimit(1)
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
        Constants.heatmapColor(baseColor: Constants.Colors.blue, intensity: intensity)
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
        Constants.heatmapColor(baseColor: Constants.Colors.blue, intensity: intensity)
    }
}

#Preview {
    NavigationStack {
        PostStatsDetailsView(
            post: .init(
                title: "Matter Smart Home Protocol Still Doesn't Matter: A Year Later",
                postID: "12345",
                postURL: URL(string: "example.com"),
                date: .now,
                type: "post",
                author: nil,
                metrics: .init(views: 45892, likes: 26, comments: 487)
            ),
            dateRange: Calendar.demo.makeDateRange(for: .thisYear)
        )
        .environment(\.context, StatsContext.demo)
    }
}
