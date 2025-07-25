import SwiftUI
import WordPressUI

struct ReferrerStatsView: View {
    let referrer: TopListData.Referrer
    
    @Environment(\.router) private var router
    
    var body: some View {
            ScrollView {
                VStack(spacing: Constants.step2) {
                    headerCard
                    
                    if !referrer.children.isEmpty {
                        childrenCard
                    }
                }
                .padding(.horizontal, Constants.step2)
                .padding(.vertical, Constants.step1)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Strings.ReferrerStats.title)
            .navigationBarTitleDisplayMode(.inline)
    }
    
    private var placeholderIcon: some View {
        Image(systemName: "link.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.secondary.opacity(0.5))
    }
}

// MARK: - Subviews

private extension ReferrerStatsView {
    var headerCard: some View {
        VStack(spacing: Constants.step1) {
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
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholderIcon
                .frame(width: 48, height: 48)
        }
    }
    
    var referrerDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(referrer.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let domain = referrer.domain {
                Text(domain)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    var viewsCount: some View {
        if let views = referrer.metrics.views {
            VStack(alignment: .trailing, spacing: 4) {
                Text(StatsValueFormatter.formatNumber(views))
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                Text(SiteMetric.views.localizedTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var markAsSpamButton: some View {
        Button {
            // TODO: Implement mark as spam functionality
        } label: {
            Label(Strings.ReferrerStats.markAsSpam, systemImage: "exclamationmark.triangle")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    var childrenCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.ReferrerStats.referralSources)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, Constants.step2)
                .padding(.vertical, Constants.step1)
            
            Divider()
            
            ForEach(referrer.children, id: \.id) { child in
                childRow(for: child)
            }
        }
        .cardStyle()
    }
    
    func childRow(for child: TopListData.Referrer) -> some View {
        VStack(spacing: 0) {
            HStack {
                childInfo(for: child)
                
                Spacer()
                
                if let views = child.metrics.views {
                    Text(StatsValueFormatter.formatNumber(views))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, Constants.step2)
            .padding(.vertical, Constants.step1)
            
            if child.id != referrer.children.last?.id {
                Divider()
                    .padding(.leading, Constants.step2)
            }
        }
    }
    
    func childInfo(for child: TopListData.Referrer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(child.name)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            if let domain = child.domain, let url = URL(string: "https://\(domain)") {
                Button {
                    router.openURL(url)
                } label: {
                    Text(domain)
                        .font(.caption)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Strings

private extension Strings {
    enum ReferrerStats {
        static let title = NSLocalizedString(
            "stats.referrer.title",
            value: "Referrer Details",
            comment: "Title for the referrer details screen"
        )
        
        static let markAsSpam = NSLocalizedString(
            "stats.referrer.markAsSpam",
            value: "Mark as Spam",
            comment: "Button to mark a referrer as spam"
        )
        
        static let referralSources = NSLocalizedString(
            "stats.referrer.referralSources",
            value: "Referral Sources",
            comment: "Section title for the list of referral sources"
        )
    }
}

// MARK: - Preview

#Preview {
    ReferrerStatsView(referrer: .mock)
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
