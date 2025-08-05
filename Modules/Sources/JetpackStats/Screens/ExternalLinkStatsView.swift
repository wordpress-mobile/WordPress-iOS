import SwiftUI
import WordPressUI
import DesignSystem

struct ExternalLinkStatsView: View {
    let externalLink: TopListItem.ExternalLink
    let dateRange: StatsDateRange

    private let imageSize: CGFloat = 28

    @Environment(\.context) private var context
    @Environment(\.router) private var router
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                headerCard
                    .dynamicTypeSize(...DynamicTypeSize.xLarge)
                if !externalLink.children.isEmpty {
                    childrenCard
                }
            }
            .padding(.vertical, Constants.step1)
            .padding(.horizontal, Constants.cardHorizontalInset(for: horizontalSizeClass))
            .frame(maxWidth: horizontalSizeClass == .regular ? Constants.maxHortizontalWidth : .infinity)
            .frame(maxWidth: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .background(Constants.Colors.background)
        .onAppear {
            context.tracker?.send(.externalLinkStatsScreenShown)
        }
        .navigationTitle(Strings.ExternalLinkDetails.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var placeholderIcon: some View {
        Image(systemName: "link.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.secondary.opacity(0.5))
    }

    var headerCard: some View {
        VStack(spacing: Constants.step2) {
            externalLinkInfoRow
            if let url = URL(string: externalLink.url) {
                Divider()
                openLinkButton(url: url)
            }
        }
        .padding(Constants.step2)
        .cardStyle()
    }

    var externalLinkInfoRow: some View {
        HStack(spacing: Constants.step1) {
            linkIcon
            linkDetails
            Spacer()
            viewsCount
        }
    }

    @ViewBuilder
    var linkIcon: some View {
        if let url = URL(string: externalLink.url),
           let host = url.host,
           let iconURL = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128") {
            CachedAsyncImage(url: iconURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                placeholderIcon
            }
            .frame(width: imageSize, height: imageSize)
        } else {
            placeholderIcon
                .frame(width: imageSize, height: imageSize)
        }
    }

    var linkDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(externalLink.title ?? externalLink.url)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)

            if let url = URL(string: externalLink.url), let host = url.host {
                Text(host)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    var viewsCount: some View {
        if let views = externalLink.metrics.views {
            StandaloneMetricView(metric: .views, value: views)
        }
    }

    func openLinkButton(url: URL) -> some View {
        Link(destination: url) {
            Label(Strings.ExternalLinkDetails.openLink, systemImage: "arrow.up.right.square")
                .foregroundColor(Constants.Colors.blue)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    var childrenCard: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            Text(Strings.ExternalLinkDetails.childLinks)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, Constants.step3)

            TopListItemsView(
                data: childrenChartData,
                itemLimit: externalLink.children.count,
                dateRange: dateRange
            )
        }
        .padding(.vertical, Constants.step2)
        .cardStyle()
    }

    private var childrenChartData: TopListData {
        return TopListData(
            item: .externalLinks,
            metric: .views,
            items: externalLink.children
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ExternalLinkStatsView(
            externalLink: .mock,
            dateRange: Calendar.demo.makeDateRange(for: .thisYear)
        )
    }
    .navigationViewStyle(.stack)
    .tint(Constants.Colors.jetpack)
}

private extension TopListItem.ExternalLink {
    static let mock = TopListItem.ExternalLink(
        url: "https://developer.apple.com",
        title: "Apple Developer",
        children: [
            TopListItem.ExternalLink(
                url: "https://developer.apple.com/documentation/swiftui",
                title: "SwiftUI Documentation",
                children: [],
                metrics: SiteMetricsSet(views: 850)
            ),
            TopListItem.ExternalLink(
                url: "https://developer.apple.com/documentation/uikit",
                title: "UIKit Documentation",
                children: [],
                metrics: SiteMetricsSet(views: 750)
            ),
            TopListItem.ExternalLink(
                url: "https://developer.apple.com/xcode",
                title: "Xcode",
                children: [],
                metrics: SiteMetricsSet(views: 600)
            )
        ],
        metrics: SiteMetricsSet(views: 2200)
    )
}
