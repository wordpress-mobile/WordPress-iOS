import SwiftUI
import WordPressKit
import DesignSystem

struct AuthorStatsView: View {
    let author: TopListData.Author
    
    @State private var dateRange: StatsDateRange
    @StateObject private var viewModel: TopListCardViewModel
    
    @Environment(\.context) private var context
    @ScaledMetric private var avatarSize = 80
    
    init(author: TopListData.Author, initialDateRange: StatsDateRange? = nil, context: StatsContext) {
        self.author = author
        let calendar = Calendar.current
        let range = initialDateRange ?? calendar.makeDateRange(for: .last30Days)
        self._dateRange = State(initialValue: range)
        
        self._viewModel = StateObject(wrappedValue: TopListCardViewModel(
            selection: .init(item: .authors, metric: .views),
            dateRange: range,
            service: context.service,
            fetchLimit: 100
        ))
    }
    
    var body: some View {
        let authorPosts = extractAuthorPosts()
        
        ScrollView {
            VStack(spacing: Constants.step2) {
                // Author header
                authorHeader
                    .cardStyle()
                
                // Posts list
                if !authorPosts.isEmpty {
                    postsSection(posts: authorPosts)
                        .cardStyle()
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding(.vertical, Constants.step4)
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                } else {
                    emptyPostsView
                        .cardStyle()
                }
            }
            .padding(.vertical, Constants.step1)
        }
        .background(Constants.Colors.background)
        .onAppear {
            viewModel.onAppear()
        }
        .onChange(of: dateRange) { newRange in
            viewModel.dateRange = newRange
        }
        .navigationTitle(Strings.AuthorDetails.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            LegacyFloatingDateControl(dateRange: $dateRange)
        }
    }
    
    private func extractAuthorPosts() -> [TopListData.Post] {
        guard let data = viewModel.matchedData else {
            return []
        }
        
        // Find the current author in the fetched data
        if let fetchedAuthor = data.items.compactMap({ $0 as? TopListData.Author }).first(where: { $0.userId == author.userId }),
           let posts = fetchedAuthor.posts {
            return posts
        } else {
            return []
        }
    }
    
    private var authorHeader: some View {
        VStack(spacing: Constants.step2) {
            HStack(spacing: Constants.step2) {
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
                
                // Name and views
                VStack(alignment: .leading, spacing: 4) {
                    Text(author.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    // Views with trend
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: SiteMetric.views.systemImage)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Text(SiteMetric.views.localizedTitle.uppercased())
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(StatsValueFormatter.formatNumber(author.metrics.views ?? 0, onlyLarge: true))
                            .font(Font.make(.recoleta, textStyle: .title2, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.step2)
    }
    
    
    private func postsSection(posts: [TopListData.Post]) -> some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            StatsCardTitleView(title: Strings.AuthorDetails.posts)
            
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
        .padding(Constants.step2)
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
    }
}

#Preview {
    NavigationStack {
        AuthorStatsView(
            author: TopListData.Author(
                name: "Alex Johnson",
                userId: "1",
                role: nil,
                metrics: SiteMetricsSet(
                    views: 5000
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
            ),
            context: StatsContext.demo
        )
    }
    .environment(\.context, StatsContext.demo)
}
