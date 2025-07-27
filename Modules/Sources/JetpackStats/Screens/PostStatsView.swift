import SwiftUI
import UIKit
@preconcurrency import WordPressKit

public struct PostStatsView: View {
    public struct PostInfo {
        public let title: String
        public let postID: String
        public let postURL: URL?
        public let date: Date?

        public init(title: String, postID: String, postURL: URL? = nil, date: Date? = nil) {
            self.title = title
            self.postID = postID
            self.postURL = postURL
            self.date = date
        }

        init(from post: TopListItem.Post) {
            self.title = post.title
            self.postID = post.postID ?? ""
            self.postURL = post.postURL
            self.date = post.date
        }
    }

    private let post: PostInfo
    private let initialDateRange: StatsDateRange?

    @State private var data: PostDetailsData?
    @State private var likes: PostLikesData?
    @State private var isLoadingDetails = true
    @State private var isLoadingLikes = true
    @State private var error: Error?

    @Environment(\.context) private var context
    @Environment(\.router) private var router

    init(post: TopListItem.Post, dateRange: StatsDateRange) {
        self.post = PostInfo(from: post)
        self.initialDateRange = dateRange
    }

    init(post: PostInfo, dateRange: StatsDateRange) {
        self.post = post
        self.initialDateRange = dateRange
    }

    public static func make(post: PostInfo, context: StatsContext, router: StatsRouter) -> some View {
        PostStatsView(
            post: post,
            dateRange: context.calendar.makeDateRange(for: .last30Days)
        )
        .environment(\.context, context)
        .environment(\.router, router)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Constants.step2) {
                contents
            }
            .padding(.vertical, Constants.step1)
        }
        .background(Constants.Colors.background)
        .navigationTitle(Strings.PostDetails.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPostDetails()
        }
    }

    @ViewBuilder
    private var contents: some View {
        headerView
            .cardStyle()

        // Views Over Time Chart
        if let data {
            makeChartView(dataPoints: data.dataPoints)
        } else if isLoadingDetails {
            makeChartView(dataPoints: mockDataPoints)
                .redacted(reason: .placeholder)
        }

        if let data {
            // Weekly Trends Chart
            VStack(alignment: .leading, spacing: Constants.step2) {
                StatsCardTitleView(title: Strings.PostDetails.recentWeeks)
                WeeklyTrendsView(viewModel: data.weeklyTrends)
            }
            .padding(Constants.step2)
            .cardStyle()

            // Yearly Summary
            VStack(alignment: .leading, spacing: Constants.step2) {
                StatsCardTitleView(title: Strings.PostDetails.monthlyActivity)
                YearlyTrendsView(viewModel: data.yearlyTrends)
            }
            .padding(Constants.step2)
            .cardStyle()
        }
    }

    private func makeChartView(dataPoints: [DataPoint]) -> some View {
        StandaloneChartCard(
            dataPoints: dataPoints,
            metric: .views,
            initialDateRange: dateRange,
            configuration: .init(minimumGranularity: .day)
        )
        .cardStyle()
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            postDetailsView

            if let likes {
                Button {
                    navigateToLikesList()
                } label: {
                    PostLikesStripView(likes: likes)
                        .contentShape(Rectangle())
                }
            } else if isLoadingLikes {
                PostLikesStripView(likes: .mock)
                    .redacted(reason: .placeholder)
            }

            Divider()

            if let error {
                SimpleErrorView(error: error)
                    .frame(minHeight: 210)
            } else {
                PostStatsMetricsStripView(
                    metrics: metrics ?? .mock,
                    onLikesTapped: navigateToLikesList,
                    onCommentsTapped: navigateToCommentsList
                )
                // Preserving view identity for better animations
                .redacted(reason: metrics == nil ? .placeholder : [])
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

            if let dateGMT = post.date ?? data?.post?.dateGMT {
                HStack(spacing: 6) {
                    Text(Strings.PostDetails.published(formatPublishedDate(dateGMT)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Permalink button
                    if let postURL = post.postURL ?? data?.post?.permalink.flatMap(URL.init) {
                        Link(destination: postURL) {
                            Image(systemName: "link")
                                .font(.footnote)
                                .foregroundColor(Constants.Colors.blue)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data

    private var dateRange: StatsDateRange {
        initialDateRange ?? context.calendar.makeDateRange(for: .last30Days)
    }

    private var metrics: SiteMetricsSet? {
        guard let data else {
            return nil
        }
        return SiteMetricsSet(
            views: data.views,
            likes: likes?.totalCount,
            comments: data.comments
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
        guard let postID = Int(post.postID) else {
            self.error = URLError(.unknown, userInfo: [NSLocalizedDescriptionKey: Strings.Errors.generic])
            self.isLoadingDetails = false
            return
        }

        // Load likes in parallel and ignore errors
        Task {
            do {
                self.likes = try await context.service.getPostLikes(for: postID, count: 10)
            } catch {
                // Do nothing
            }
            self.isLoadingLikes = false
        }

        do {
            let details = try await context.service.getPostDetails(for: postID)
            let data = await makeData(with: details, calendar: context.calendar)
            withAnimation(.spring) {
                self.data = data
                self.isLoadingDetails = false
            }
        } catch {
            withAnimation(.spring) {
                self.error = error
                self.isLoadingDetails = false
            }
        }
    }

    private var mockDataPoints: [DataPoint] {
        ChartData.mock(
            metric: .views,
            granularity: dateRange.dateInterval.preferredGranularity,
            range: dateRange
        ).currentData
    }

    private func navigateToLikesList() {
        guard let postID = Int(post.postID) else {
            return
        }
        router.navigateToLikesList(
            siteID: context.siteID,
            postID: postID,
            totalLikes: likes?.totalCount ?? 0
        )
    }

    private func navigateToCommentsList() {
        guard let postID = Int(post.postID) else {
            return
        }
        router.navigateToCommentsList(siteID: context.siteID, postID: postID)
    }
}

private struct PostDetailsData: @unchecked Sendable {
    let post: StatsPostDetails.Post?
    let views: Int?
    let comments: Int?
    let dataPoints: [DataPoint]
    let weeklyTrends: WeeklyTrendsViewModel
    let yearlyTrends: YearlyTrendsViewModel
}

private func makeData(with details: StatsPostDetails, calendar: Calendar) async -> PostDetailsData {
    let dataPoints: [DataPoint] = details.data.compactMap { postView in
        guard let date = calendar.date(from: postView.date) else { return nil }
        return DataPoint(date: date, value: postView.viewsCount)
    }

    let weeklyTrends = WeeklyTrendsViewModel(dataPoints: dataPoints, calendar: calendar)

    let yearlyTrends = YearlyTrendsViewModel(dataPoints: dataPoints, calendar: calendar)

    return PostDetailsData(
        post: details.post,
        views: details.totalViewsCount,
        comments: details.post?.commentCount.flatMap { Int($0) },
        dataPoints: dataPoints,
        weeklyTrends: weeklyTrends,
        yearlyTrends: yearlyTrends
    )
}

private struct PostStatsMetricsStripView: View {
    let metrics: SiteMetricsSet
    let onLikesTapped: (() -> Void)?
    let onCommentsTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: Constants.step2) {
            ForEach([SiteMetric.views, .likes, .comments]) { metric in
                MetricView(metric: metric, value: metrics[metric])
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switch metric {
                        case .likes:
                            onLikesTapped?()
                        case .comments:
                            onCommentsTapped?()
                        default:
                            break
                        }
                    }
            }
        }
    }

    struct MetricView: View {
        let metric: SiteMetric
        let value: Int?

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 2) {
                    Image(systemName: metric.systemImage)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)

                    Text(metric.localizedTitle.uppercased())
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)

                    if metric != .views && (value ?? 0) > 0 {
                        Image(systemName: "chevron.forward")
                            .font(.caption2.weight(.bold))
                            .scaleEffect(x: 0.7, y: 0.7)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 1)
                    }
                }

                HStack {
                    Text(formattedValue)
                        .contentTransition(.numericText())
                        .animation(.spring, value: value)
                        .font(Font.make(.recoleta, textStyle: .title, weight: .medium))
                        .foregroundColor(.primary)
                }
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
        HStack(spacing: 4) {
            Text(Strings.PostDetails.likesCount(likes.totalCount))
                .font(.subheadline)
                .foregroundColor(.primary)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary.opacity(0.66))
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

#Preview {
    NavigationStack {
        PostStatsView(
            post: .init(
                title: "Matter Smart Home Protocol Still Doesn't Matter: A Year Later",
                postID: "12345",
                postURL: URL(string: "example.com"),
                date: .now
            ),
            dateRange: Calendar.demo.makeDateRange(for: .last30Days)
        )
        .environment(\.context, StatsContext.demo)
    }
}
