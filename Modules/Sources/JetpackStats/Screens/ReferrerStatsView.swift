import SwiftUI
import WordPressUI

struct ReferrerStatsView: View {
    let referrer: TopListData.Referrer

    private let imageSize: CGFloat = 28

    @Environment(\.context) private var context
    @Environment(\.router) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.step3) {
                headerCard
                if !referrer.children.isEmpty {
                    childrenCard
                }
            }
            .padding(.vertical, Constants.step1)
        }
        .background(Constants.Colors.background)
        .navigationTitle(Strings.ReferrerDetails.title)
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
            referrerInfoRow
            Divider()
            markAsSpamButton
        }
        .padding(Constants.step2)
        .cardStyle()
    }
    
    var referrerInfoRow: some View {
        HStack(spacing: Constants.step1) {
            referrerIcon
            
            referrerDetails
            
            Spacer()
            
            viewsCount
        }
    }
    
    @ViewBuilder
    var referrerIcon: some View {
        if let iconURL = referrer.iconURL {
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
    
    var referrerDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(referrer.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let domain = referrer.domain, let url = URL(string: "https://\(domain)") {
                Link(domain, destination: url)
                    .font(.subheadline)
            } else if let domain = referrer.domain {
                Text(domain)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    var viewsCount: some View {
        if let views = referrer.metrics.views {
            VStack(alignment: .trailing, spacing: 0) {
                Text(StatsValueFormatter.formatNumber(views))
                    .font(Font.make(.recoleta, textStyle: .title2, weight: .medium))
                    .foregroundColor(.primary)
                Text(SiteMetric.views.localizedTitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    var markAsSpamButton: some View {
        if referrer.isSpam == true {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.subheadline)
                Text(Strings.ReferrerDetails.markedAsSpam)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
        } else {
            Button(role: .destructive) {
                // TODO: Implement mark as spam functionality
            } label: {
                Label(Strings.ReferrerDetails.markAsSpam, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }
    
    var childrenCard: some View {
        VStack(alignment: .leading, spacing: Constants.step2) {
            Text(Strings.ReferrerDetails.referralSources)
                .font(.headline)
                .foregroundColor(.primary)

            TopListItemsView(
                data: childrenChartData,
                itemLimit: referrer.children.count,
                dateRange: context.calendar.makeDateRange(for: .thisYear), // Not used
                isNavigationDisabled: true
            )

        }
        .padding(Constants.step2)
        .cardStyle()
    }
    
    private var childrenChartData: TopListChartData {
        let maxValue = referrer.children
            .compactMap { $0.metrics.views }
            .max() ?? 1
        
        return TopListChartData(
            item: .referrers,
            metric: .views,
            items: referrer.children,
            maxValue: maxValue
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ReferrerStatsView(referrer: .mock)
    }
    .tint(Constants.Colors.blue)
}

private extension TopListData.Referrer {
    static let mock = TopListData.Referrer(
        name: "Google Search",
        domain: "google.com",
        iconURL: URL(string: "https://www.google.com/favicon.ico"),
        isSpam: false,
        children: [
            TopListData.Referrer(
                name: "wordpress development tutorial",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                isSpam: false,
                children: [],
                metrics: SiteMetricsSet(views: 850)
            ),
            TopListData.Referrer(
                name: "swift programming blog",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                isSpam: false,
                children: [],
                metrics: SiteMetricsSet(views: 750)
            ),
            TopListData.Referrer(
                name: "ios app development best practices",
                domain: "google.com",
                iconURL: URL(string: "https://www.google.com/favicon.ico"),
                isSpam: false,
                children: [],
                metrics: SiteMetricsSet(views: 600)
            )
        ],
        metrics: SiteMetricsSet(views: 2200)
    )
}
