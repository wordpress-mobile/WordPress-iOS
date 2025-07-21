import SwiftUI

struct TopListItemView: View {
    let currentItem: any TopListItem
    let previousItem: (any TopListItem)?
    let metric: SiteMetric
    let maxValue: Int
    let showDetails: Bool

    var body: some View {
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
            default:
                let _ = assertionFailure("unsupported item: \(currentItem)")
                EmptyView()
            }

            Spacer(minLength: 4)

            // Metrics view
            TopListMetricsView(
                currentValue: currentItem.metrics[metric] ?? 0,
                previousValue: previousItem?.metrics[metric] ?? 0,
                metric: metric,
                showDetails: showDetails
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
