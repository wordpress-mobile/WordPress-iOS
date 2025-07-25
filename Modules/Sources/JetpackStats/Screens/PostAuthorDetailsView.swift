import SwiftUI
import WordPressKit

struct PostAuthorDetailsView: View {
    let author: TopListData.Author
    
    @State private var dateRange: StatsDateRange
    
    @Environment(\.context) private var context
    @ScaledMetric private var avatarSize = 80
    
    init(author: TopListData.Author, initialDateRange: StatsDateRange? = nil) {
        self.author = author
        let calendar = Calendar.current
        self._dateRange = State(initialValue: initialDateRange ?? calendar.makeDateRange(for: .last30Days))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step2) {
                // Author header
                authorHeader
                    .padding(.horizontal, Constants.step2)
                    .padding(.top, Constants.step2)
                
                // Posts list
                if let posts = author.posts, !posts.isEmpty {
                    postsSection(posts: posts)
                        .padding(.horizontal, Constants.step2)
                } else {
                    emptyPostsView
                        .padding(.horizontal, Constants.step2)
                }
            }
            .padding(.bottom, Constants.step2)
        }
        .navigationTitle(Strings.AuthorDetails.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            LegacyFloatingDateControl(dateRange: $dateRange)
        }
    }
    
    private var authorHeader: some View {
        VStack(spacing: Constants.step1) {
            // Avatar
            AsyncImage(url: author.avatarURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.secondary)
            }
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
            
            // Name and role
            VStack(spacing: 4) {
                Text(author.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let role = author.role {
                    Text(role)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Metrics summary
            HStack(spacing: Constants.step3) {
                metricSummaryItem(
                    value: author.metrics.views ?? 0,
                    label: SiteMetric.views.localizedTitle
                )
                
                if let comments = author.metrics.comments {
                    metricSummaryItem(
                        value: comments,
                        label: SiteMetric.comments.localizedTitle
                    )
                }
                
                if let likes = author.metrics.likes {
                    metricSummaryItem(
                        value: likes,
                        label: SiteMetric.likes.localizedTitle
                    )
                }
            }
            .padding(.top, Constants.step1)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.step2)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func metricSummaryItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(StatsValueFormatter.formatNumber(value, onlyLarge: true))
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func postsSection(posts: [TopListData.Post]) -> some View {
        VStack(alignment: .leading, spacing: Constants.step1) {
            Text(Strings.AuthorDetails.posts)
                .font(.headline)
            
            let maxViews = posts.compactMap { $0.metrics.views }.max() ?? 0
            let topListData = TopListChartData(
                item: .postsAndPages,
                metric: .views,
                items: posts,
                previousItems: [:],
                maxValue: maxViews
            )
            
            TopListItemsView(
                data: topListData,
                itemLimit: 10,
                dateRange: dateRange,
                showDetails: true
            )
        }
    }
    
    
    private var emptyPostsView: some View {
        VStack(spacing: Constants.step1) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(Strings.AuthorDetails.noPosts)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.step4)
        .padding(.horizontal, Constants.step2)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        PostAuthorDetailsView(
            author: TopListData.Author(
                name: "Alex Johnson",
                userId: "1",
                role: "Editor-in-Chief",
                metrics: SiteMetricsSet(
                    views: 5000,
                    likes: 850,
                    comments: 280
                ),
                avatarURL: nil,
                posts: [
                    TopListData.Post(
                        title: "The Future of Technology: AI and Machine Learning",
                        postID: "1",
                        postURL: URL(string: "https://example.com/post1"),
                        date: Date(),
                        type: "post",
                        author: "Alex Johnson",
                        metrics: SiteMetricsSet(views: 1250)
                    ),
                    TopListData.Post(
                        title: "Understanding Climate Change",
                        postID: "2",
                        postURL: URL(string: "https://example.com/post2"),
                        date: Date(),
                        type: "post",
                        author: "Alex Johnson",
                        metrics: SiteMetricsSet(views: 980)
                    )
                ]
            )
        )
    }
    .environment(\.context, StatsContext.demo)
}
