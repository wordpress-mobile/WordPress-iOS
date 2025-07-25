import SwiftUI

struct TopListItemView: View {
    let currentItem: any TopListItem
    let previousItem: (any TopListItem)?
    let metric: SiteMetric
    let maxValue: Int
    let dateRange: StatsDateRange

    @Environment(\.router) private var router
    @Environment(\.context) private var context

    var body: some View {
        if hasDetails {
            Button {
                navigateToDetails()
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    var content: some View {
        HStack(spacing: 0) {
            // Content-specific view
            switch currentItem {
            case let post as TopListData.Post:
                TopListPostRowView(item: post)
            case let referrer as TopListData.Referrer:
                TopListReferrerRowView(item: referrer)
            case let location as TopListData.Location:
                TopListLocationRowView(item: location)
            case let author as TopListData.Author:
                TopListAuthorRowView(item: author)
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
            default:
                let _ = assertionFailure("unsupported item: \(currentItem)")
                EmptyView()
            }

            Spacer(minLength: 6)

            // Metrics view
            ZStack(alignment: .trailing) {
                if previousItem != nil {
                    // Reserve space to avoid junky animations when changing period
                    Text("+4.8K (31.2%)")
                        .font(.caption.weight(.medium)).tracking(-0.33)
                        .opacity(0)
                }

                TopListMetricsView(
                    currentValue: currentItem.metrics[metric] ?? 0,
                    previousValue: previousItem?.metrics[metric],
                    metric: metric,
                    showChevron: hasDetails
                )
            }
        }
        .padding(.vertical, 7)
        .background(
            TopListItemBarBackground(
                value: currentItem.metrics[metric] ?? 0,
                maxValue: maxValue,
                barColor: metric.primaryColor
            )
            .padding(.horizontal, -(Constants.step2 / 2))
        )
    }
}

// MARK: - Private Methods

private extension TopListItemView {
    var hasDetails: Bool {
        switch currentItem {
        case is TopListData.Post:
            return true
        case is TopListData.ArchiveItem:
            return true
        case is TopListData.Author:
            return true
        case is TopListData.Referrer:
            return true
        default:
            return false
        }
    }

    func navigateToDetails() {
        switch currentItem {
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
            let detailsView = ReferrerStatsView(referrer: referrer)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView)
        default:
            break
        }
    }
}
