import SwiftUI
import DesignSystem

struct TopListItemView: View {
    static let defaultCellHeight: CGFloat = 52

    var index: Int?
    let item: any TopListItemProtocol
    let previousValue: Int?
    let metric: SiteMetric
    let maxValue: Int
    let dateRange: StatsDateRange

    @State private var isTapped = false

    /// .title scales the bets in this scenario
    @ScaledMetric(relativeTo: .title) private var cellHeight = TopListItemView.defaultCellHeight
    @ScaledMetric(relativeTo: .title) private var minTrailingWidth = 74

    @Environment(\.router) var router
    @Environment(\.context) var context

    var body: some View {
        if hasDetails {
            Button {
                // Track item tap
                trackItemTap()

                // Trigger animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTapped = true
                }

                // Reset after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isTapped = false
                    }
                }
                navigateToDetails()
            } label: {
                content
                    .contentShape(Rectangle()) // Make the entire view tappable
                    .scaleEffect(isTapped ? 0.97 : 1.0)
                    .opacity(isTapped ? 0.85 : 1.0)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Strings.Accessibility.viewMoreDetails)
        } else {
            content
        }
    }

    var content: some View {
        HStack(alignment: .center, spacing: 0) {
            if let index {
                Text("\(index + 1)")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .frame(width: 22, alignment: .center)
                    .lineLimit(1)
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .padding(.trailing, 8)
            }

            // Content-specific view
            switch item {
            case let post as TopListItem.Post:
                TopListPostRowView(item: post)
            case let author as TopListItem.Author:
                TopListAuthorRowView(item: author)
            case let referrer as TopListItem.Referrer:
                TopListReferrerRowView(item: referrer)
            case let location as TopListItem.Location:
                TopListLocationRowView(item: location)
            case let link as TopListItem.ExternalLink:
                TopListExternalLinkRowView(item: link)
            case let download as TopListItem.FileDownload:
                TopListFileDownloadRowView(item: download)
            case let searchTerm as TopListItem.SearchTerm:
                TopListSearchTermRowView(item: searchTerm)
            case let video as TopListItem.Video:
                TopListVideoRowView(item: video)
            case let archiveItem as TopListItem.ArchiveItem:
                TopListArchiveItemRowView(item: archiveItem)
            case let archiveSection as TopListItem.ArchiveSection:
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
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .padding(.horizontal, Constants.step1)
        .frame(height: cellHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
        case is TopListItem.Post:
            return true
        case is TopListItem.ArchiveItem:
            return true
        case is TopListItem.ArchiveSection:
            return true
        case is TopListItem.Author:
            return true
        case is TopListItem.Referrer:
            return true
        case is TopListItem.ExternalLink:
            return true
        default:
            return false
        }
    }

    func trackItemTap() {
        context.tracker?.send(.topListItemTapped, properties: [
            "item_type": item.id.type.analyticsName,
            "metric": metric.analyticsName
        ])
    }

    func navigateToDetails() {
        switch item {
        case let post as TopListItem.Post:
            let detailsView = PostStatsView(post: post, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView, title: Strings.PostDetails.title)
        case let archiveItem as TopListItem.ArchiveItem:
            if let url = URL(string: archiveItem.href) {
                router.openURL(url)
            }
        case let author as TopListItem.Author:
            let detailsView = AuthorStatsView(author: author, initialDateRange: dateRange, context: context)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView, title: Strings.AuthorDetails.title)
        case let referrer as TopListItem.Referrer:
            let detailsView = ReferrerStatsView(referrer: referrer, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView, title: Strings.ReferrerDetails.title)
        case let archiveSection as TopListItem.ArchiveSection:
            let detailsView = ArchiveStatsView(archiveSection: archiveSection, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView, title: archiveSection.displayName)
        case let externalLink as TopListItem.ExternalLink:
            let detailsView = ExternalLinkStatsView(externalLink: externalLink, dateRange: dateRange)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView, title: Strings.ExternalLinkDetails.title)
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
        .padding(Constants.step1)
    }
}

@MainActor @ViewBuilder
private func makePreviewItems() -> some View {
    // Posts & Pages
    VStack(spacing: 8) {
        makePreviewItem(
            TopListItem.Post(
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
            TopListItem.Post(
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
            TopListItem.Author(
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
            TopListItem.Author(
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
            TopListItem.Referrer(
                name: "Google Search",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                children: [],
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 42000
        )

        makePreviewItem(
            TopListItem.Referrer(
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
            TopListItem.Location(
                country: "United States",
                flag: "🇺🇸",
                countryCode: "US",
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 47500
        )

        makePreviewItem(
            TopListItem.Location(
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
            TopListItem.ExternalLink(
                url: "https://developer.apple.com/documentation/swiftui",
                title: "SwiftUI Documentation",
                children: [],
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 52000
        )

        makePreviewItem(
            TopListItem.ExternalLink(
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
            TopListItem.FileDownload(
                fileName: "wordpress-guide-2024.pdf",
                filePath: "/downloads/guides/wordpress-guide-2024.pdf",
                metrics: SiteMetricsSet(downloads: 50000)
            ),
            previousValue: 46000,
            metric: .downloads
        )

        makePreviewItem(
            TopListItem.FileDownload(
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
            TopListItem.SearchTerm(
                term: "wordpress tutorial",
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 48500
        )

        makePreviewItem(
            TopListItem.SearchTerm(
                term: "how to install plugins",
                metrics: SiteMetricsSet(views: 890)
            ),
            previousValue: 950
        )
    }

    // Videos
    VStack(spacing: 8) {
        makePreviewItem(
            TopListItem.Video(
                title: "WordPress 6.0 Features Overview",
                postId: "9012",
                videoURL: URL(string: "https://example.com/videos/wp-6-features"),
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 44000
        )

        makePreviewItem(
            TopListItem.Video(
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
            TopListItem.ArchiveItem(
                href: "/2024/03/",
                value: "March 2024",
                metrics: SiteMetricsSet(views: 50000)
            ),
            previousValue: 51000
        )

        makePreviewItem(
            TopListItem.ArchiveItem(
                href: "/category/tutorials/",
                value: "Tutorials",
                metrics: SiteMetricsSet(views: 12300)
            ),
            previousValue: 11000
        )
    }
}

@MainActor
private func makePreviewItem(_ item: any TopListItemProtocol, previousValue: Int? = nil, metric: SiteMetric = .views) -> some View {
    TopListItemView(
        item: item,
        previousValue: previousValue,
        metric: metric,
        maxValue: 50000,
        dateRange: Calendar.demo.makeDateRange(for: .last7Days)
    )
}
