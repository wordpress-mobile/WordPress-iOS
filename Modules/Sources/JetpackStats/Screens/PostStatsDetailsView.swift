import SwiftUI
import UIKit
import WordPressKit

struct PostStatsDetailsView: View {
    let post: TopListData.Post

    @State private var details: StatsPostDetails?
    @State private var postLikes: PostLikesData?
    @State private var dataPoints: [DataPoint] = []
    @State private var isLoading = true
    @State private var error: Error?

    @Environment(\.context) private var context
    @Environment(\.router) private var router

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
        if !dataPoints.isEmpty {
            makeChartView(dataPoints: dataPoints)
        } else if isLoading {
            makeChartView(dataPoints: mockDataPoints)
                .redacted(reason: .placeholder)
        }

        if let details {
            // Weekly Trends Chart
            if !details.recentWeeks.isEmpty {
                VStack(alignment: .leading, spacing: Constants.step2) {
                    StatsCardTitleView(title: Strings.PostDetails.recentWeeks)

                    WeeklyTrendsView(
                        weeks: WeeklyTrendsView.Week.make(from: details.recentWeeks, using: context.calendar),
                        calendar: context.calendar,
                        timeZone: context.timeZone
                    )
                }
                .padding(Constants.step2)
                .cardStyle()
            }

            // Yearly Summary
            if !dataPoints.isEmpty {
                VStack(alignment: .leading, spacing: Constants.step2) {
                    StatsCardTitleView(title: Strings.PostDetails.monthlyActivity)

                    YearlyTrendsView(
                        viewModel: YearlyTrendsViewModel(
                            dataPoints: dataPoints,
                            calendar: context.calendar
                        )
                    )
                }
                .padding(Constants.step2)
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
                Button {
                    navigateToLikesList()
                } label: {
                    PostLikesStripView(likes: postLikes)
                        .contentShape(Rectangle())
                }
            } else if isLoading {
                PostLikesStripView(likes: .mock)
                    .redacted(reason: .placeholder)
            }

            Divider()

            if let metrics {
                PostStatsMetricsStripView(
                    metrics: metrics,
                    onLikesTapped: navigateToLikesList,
                    onCommentsTapped: navigateToCommentsList
                )
            } else if isLoading {
                PostStatsMetricsStripView(metrics: .mock, onLikesTapped: nil, onCommentsTapped: nil)
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
        guard let postID = Int(post.postID ?? "") else {
            self.error = URLError(.unknown, userInfo: [NSLocalizedDescriptionKey: Strings.Errors.generic])
            self.isLoading = false
            return
        }

        async let detailsTask = context.service.getPostDetails(for: postID)
        async let likesTask: PostLikesData? = {
            try? await context.service.getPostLikes(for: postID, count: 20)
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

    private func navigateToLikesList() {
        guard let postID = Int(post.postID ?? ""),
              let totalLikes = postLikes?.totalCount else {
            return
        }
        router.navigateToLikesList(siteID: context.siteID, postID: postID, totalLikes: totalLikes)
    }

    private func navigateToCommentsList() {
        guard let postID = Int(post.postID ?? "") else {
            return
        }
        router.navigateToCommentsList(siteID: context.siteID, postID: postID)
    }
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
