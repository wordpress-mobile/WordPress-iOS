import SwiftUI

enum TopListItemType: String, Identifiable, CaseIterable, Sendable, Codable {
    case postsAndPages
    case authors
    case referrers
    case locations
    case videos
    case externalLinks
    case searchTerms
    case fileDownloads
    case archive

    var id: TopListItemType { self }

    var localizedTitle: String {
        switch self {
        case .postsAndPages: Strings.SiteDataTypes.postsAndPages
        case .authors: Strings.SiteDataTypes.authors
        case .referrers: Strings.SiteDataTypes.referrers
        case .locations: Strings.SiteDataTypes.locations
        case .externalLinks: Strings.SiteDataTypes.clicks
        case .fileDownloads: Strings.SiteDataTypes.fileDownloads
        case .searchTerms: Strings.SiteDataTypes.searchTerms
        case .videos: Strings.SiteDataTypes.videos
        case .archive: Strings.SiteDataTypes.archive
        }
    }

    var systemImage: String {
        switch self {
        case .postsAndPages: "text.page"
        case .referrers: "link"
        case .locations: "map"
        case .authors: "person"
        case .externalLinks: "cursorarrow.click"
        case .fileDownloads: "arrow.down.circle"
        case .searchTerms: "magnifyingglass"
        case .videos: "play.rectangle"
        case .archive: "folder"
        }
    }

    func getTitle(for metric: SiteMetric) -> String {
        switch metric {
        case .views: Strings.TopListTitles.mostViewed
        case .visitors: Strings.TopListTitles.mostVisitors
        case .comments: Strings.TopListTitles.mostCommented
        case .likes: Strings.TopListTitles.mostLiked
        case .posts: Strings.TopListTitles.mostPosts
        case .bounceRate: Strings.TopListTitles.highestBounceRate
        case .timeOnSite: Strings.TopListTitles.longestTimeOnSite
        case .downloads: Strings.TopListTitles.mostDownloadeded
        }
    }

    static let secondaryItems: Set<TopListItemType> = [
        .externalLinks, .fileDownloads, .searchTerms, .archive
    ]

    var documentationURL: URL? {
        URL(string: documentationPath)
    }

    private var documentationPath: String {
        switch self {
        case .postsAndPages, .archive:
            "https://wordpress.com/support/stats/analyze-content-performance/#view-posts-pages-traffic"
        case .authors:
            "https://wordpress.com/support/stats/analyze-content-performance/#check-author-performance"
        case .referrers:
            "https://wordpress.com/support/stats/understand-traffic-sources/#identify-referrers"
        case .searchTerms:
            "https://wordpress.com/support/stats/understand-traffic-sources/#analyze-search-terms"
        case .fileDownloads:
            "https://wordpress.com/support/stats/analyze-content-performance/#track-file-downloads"
        case .externalLinks:
            "https://wordpress.com/support/stats/analyze-content-performance/#analyze-clicks"
        case .locations:
            "https://wordpress.com/support/stats/audience-insights/"
        case .videos:
            "https://wordpress.com/support/stats/analyze-content-performance/#see-video-traffic"
        }
    }
}
