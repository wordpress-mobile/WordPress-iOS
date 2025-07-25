import SwiftUI

struct TopListItemView: View {
    let currentItem: any TopListItem
    let previousItem: (any TopListItem)?
    let metric: SiteMetric
    let maxValue: Int
    let showDetails: Bool
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
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }

    var content: some View {
        HStack(spacing: 0) {
            // Content-specific view
            switch currentItem {
            case let post as TopListData.Post:
                TopListPostRowView(item: post, showDetails: showDetails)
            case let referrer as TopListData.Referrer:
                TopListReferrerRowView(item: referrer, showDetails: showDetails)
            case let location as TopListData.Location:
                TopListLocationRowView(item: location, showDetails: showDetails)
            case let author as TopListData.Author:
                TopListAuthorRowView(item: author, showDetails: showDetails)
            case let link as TopListData.ExternalLink:
                TopListExternalLinkRowView(item: link, showDetails: showDetails)
            case let download as TopListData.FileDownload:
                TopListFileDownloadRowView(item: download, showDetails: showDetails)
            case let searchTerm as TopListData.SearchTerm:
                TopListSearchTermRowView(item: searchTerm, showDetails: showDetails)
            case let video as TopListData.Video:
                TopListVideoRowView(item: video, showDetails: showDetails)
            case let archiveItem as TopListData.ArchiveItem:
                TopListArchiveItemRowView(item: archiveItem, showDetails: showDetails)
            default:
                let _ = assertionFailure("unsupported item: \(currentItem)")
                EmptyView()
            }

            Spacer(minLength: 4)

            // Metrics view
            TopListMetricsView(
                currentValue: currentItem.metrics[metric] ?? 0,
                previousValue: previousItem?.metrics[metric],
                metric: metric,
                showDetails: showDetails,
                showChevron: hasDetails
            )
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
            let detailsView = PostAuthorDetailsView(author: author, initialDateRange: dateRange, context: context)
                .environment(\.context, context)
                .environment(\.router, router)
            router.navigate(to: detailsView)
        default:
            break
        }
    }
}
