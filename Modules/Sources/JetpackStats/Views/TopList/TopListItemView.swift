import SwiftUI
import DesignSystem

struct TopListItemView: View {
    let item: any TopListItem
    let previousValue: Int?
    let metric: SiteMetric
    let maxValue: Int
    let dateRange: StatsDateRange

    @State private var isTapped = false

    @ScaledMetric(relativeTo: .callout) private var cellHeight = 52
    @ScaledMetric(relativeTo: .subheadline) private var minTrailingWidth = 84

    @Environment(\.router) var router
    @Environment(\.context) var context

    var body: some View {
        if hasDetails {
            Button {
                // Trigger animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTapped = true
                }
                
                // Reset after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isTapped = false
                    }
                    // Navigate after animation starts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        navigateToDetails()
                    }
                }
            } label: {
                content
                    .contentShape(Rectangle()) // Make the entire view tappable
                    .scaleEffect(isTapped ? 0.97 : 1.0)
                    .opacity(isTapped ? 0.85 : 1.0)
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    var content: some View {
        HStack(alignment: .center, spacing: 0) {
            // Content-specific view
            switch item {
            case let post as TopListData.Post:
                TopListPostRowView(item: post)
            case let author as TopListData.Author:
                TopListAuthorRowView(item: author)
            case let referrer as TopListData.Referrer:
                TopListReferrerRowView(item: referrer)
            case let location as TopListData.Location:
                TopListLocationRowView(item: location)
            case let link as TopListData.ExternalLink:
                TopListExternalLinkRowView(item: link)
            case let download as TopListData.FileDownload:
                TopListFileDownloadRowView(item: download)
            case let searchTerm as TopListData.SearchTerm:
                TopListSearchTermRowView(item: searchTerm)
            case let video as TopListData.Video:
                TopListVideoRowView(item: video)
            case let archiveItem as TopListData.ArchiveItem:
                TopListArchiveItemRowView(item: archiveItem)
            case let archiveSection as TopListData.ArchiveSection:
                TopListArchiveSectionRowView(item: archiveSection)
            default:
                let _ = assertionFailure("unsupported item: \(item)")
                EmptyView()
            }

            Spacer(minLength: 6)

            // Metrics view
            TopListMetricsView(
                currentValue: item.metrics[metric] ?? 0,
                previousValue: previousValue,
                metric: metric,
                showChevron: hasDetails
            )
            .frame(minWidth: previousValue == nil ? 20 : minTrailingWidth, alignment: .trailing)
            .padding(.trailing, -3)
        }
        .padding(.horizontal, Constants.step1)
        .frame(height: cellHeight)
        .contextMenu {
            contextMenuContent
        }
        .background(
            TopListItemBarBackground(
                value: item.metrics[metric] ?? 0,
                maxValue: maxValue,
                barColor: metric.primaryColor
            )
        )
    }
}

// MARK: - Private Methods

private extension TopListItemView {
    var hasDetails: Bool {
        switch item {
        case is TopListData.Post:
            return true
        case is TopListData.ArchiveItem:
            return true
        case is TopListData.ArchiveSection:
            return true
        case is TopListData.Author:
            return true
        case is TopListData.Referrer:
            return true
        case is TopListData.ExternalLink:
            return true
        default:
            return false
        }
    }

    func navigateToDetails() {
        switch item {
        case let post as TopListData.Post:
            let detailsView = PostStatsView(post: post, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView)
        case let archiveItem as TopListData.ArchiveItem:
            if let url = URL(string: archiveItem.href) {
                router.openURL(url)
            }
        case let author as TopListData.Author:
            let detailsView = AuthorStatsView(author: author, initialDateRange: dateRange, context: context)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView)
        case let referrer as TopListData.Referrer:
            let detailsView = ReferrerStatsView(referrer: referrer, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView)
        case let archiveSection as TopListData.ArchiveSection:
            let detailsView = ArchiveStatsView(archiveSection: archiveSection, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView)
        case let externalLink as TopListData.ExternalLink:
            let detailsView = ExternalLinkStatsView(externalLink: externalLink, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView)
        default:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            makePreviewItems()
        }
        .padding()
    }
}

@ViewBuilder
private func makePreviewItems() -> some View {
    // Posts & Pages
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.Post(
                title: "Getting Started with SwiftUI: A Comprehensive Guide",
                postID: "1234",
                postURL: URL(string: "https://example.com/swiftui-guide"),
                date: Date().addingTimeInterval(-86400),
                type: "post",
                author: "John Doe",
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 45000
        )

        makePreviewItem(
            TopListData.Post(
                title: "About Us",
                postID: "5678",
                postURL: nil,
                date: nil,
                type: "page",
                author: nil,
                metrics: SiteMetricsSet(views: 3421)
            ),
            previousValue: 3500
        )
    }

    // Authors
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.Author(
                name: "Sarah Johnson",
                userId: "100",
                role: nil, // Real API doesn't have roles
                metrics: SiteMetricsSet(views: 50000),
                avatarURL: Bundle.module.url(forResource: "author4", withExtension: "jpg"),
                posts: nil
            ),
            previousValue: 48000
        )

        makePreviewItem(
            TopListData.Author(
                name: "Michael Chen",
                userId: "101",
                role: nil,
                metrics: SiteMetricsSet(views: 23100),
                avatarURL: nil,
                posts: nil
            ),
            previousValue: nil
        )
    }

    // Referrers
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.Referrer(
                name: "Google Search",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                children: [],
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 42000
        )

        makePreviewItem(
            TopListData.Referrer(
                name: "Direct Traffic",
                domain: nil,
                iconURL: nil,
                children: [],
                metrics: SiteMetricsSet(views: 12300)
            ),
            previousValue: 15000
        )
    }

    // Locations
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.Location(
                country: "United States",
                flag: "🇺🇸",
                countryCode: "US",
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 47500
        )

        makePreviewItem(
            TopListData.Location(
                country: "United Kingdom",
                flag: "🇬🇧",
                countryCode: "GB",
                metrics: SiteMetricsSet(views: 15600)
            ),
            previousValue: nil
        )
    }

    // External Links
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.ExternalLink(
                url: "https://developer.apple.com/documentation/swiftui",
                title: "SwiftUI Documentation",
                children: [],
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 52000
        )

        makePreviewItem(
            TopListData.ExternalLink(
                url: "https://github.com/wordpress/wordpress-ios",
                title: nil,
                children: [],
                metrics: SiteMetricsSet(views: 1250)
            ),
            previousValue: 1100
        )
    }

    // File Downloads
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.FileDownload(
                fileName: "wordpress-guide-2024.pdf",
                filePath: "/downloads/guides/wordpress-guide-2024.pdf",
                metrics: SiteMetricsSet(downloads: 50000)
            ),
            previousValue: 46000,
            metric: .downloads
        )

        makePreviewItem(
            TopListData.FileDownload(
                fileName: "sample-theme.zip",
                filePath: nil,
                metrics: SiteMetricsSet(downloads: 1230)
            ),
            previousValue: nil,
            metric: .downloads
        )
    }

    // Search Terms
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.SearchTerm(
                term: "wordpress tutorial",
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 48500
        )

        makePreviewItem(
            TopListData.SearchTerm(
                term: "how to install plugins",
                metrics: SiteMetricsSet(views: 890)
            ),
            previousValue: 950
        )
    }

    // Videos
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.Video(
                title: "WordPress 6.0 Features Overview",
                postId: "9012",
                videoURL: URL(string: "https://example.com/videos/wp-6-features"),
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 44000
        )

        makePreviewItem(
            TopListData.Video(
                title: "Building Your First Theme",
                postId: "9013",
                videoURL: nil,
                metrics: SiteMetricsSet(views: 3210)
            ),
            previousValue: nil
        )
    }

    // Archive Items
    VStack(spacing: 8) {
        makePreviewItem(
            TopListData.ArchiveItem(
                href: "/2024/03/",
                value: "March 2024",
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 51000
        )

        makePreviewItem(
            TopListData.ArchiveItem(
                href: "/category/tutorials/",
                value: "Tutorials",
                metrics: SiteMetricsSet(views: 12300)
            ),
            previousValue: 11000
        )
    }
}

private func makePreviewItem(_ item: any TopListItem, previousValue: Int? = nil, metric: SiteMetric = .views) -> some View {
    TopListItemView(
        item: item,
        previousValue: previousValue,
        metric: metric,
        maxValue: 50000,
        dateRange: Calendar.demo.makeDateRange(for: .last7Days)
    )
    .padding(.horizontal)
}
