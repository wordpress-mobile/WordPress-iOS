import SwiftUI

enum TopListItemType: String, Identifiable, CaseIterable, Sendable, Codable {
    case postsAndPages
    case authors
    case referrers
    case locations
    case devices
    case videos
    case externalLinks
    case searchTerms
    case fileDownloads
    case archive
    case utm

    var id: TopListItemType { self }

    var localizedTitle: String {
        switch self {
        case .postsAndPages: Strings.SiteDataTypes.postsAndPages
        case .authors: Strings.SiteDataTypes.authors
        case .referrers: Strings.SiteDataTypes.referrers
        case .locations: Strings.SiteDataTypes.locations
        case .devices: Strings.SiteDataTypes.devices
        case .externalLinks: Strings.SiteDataTypes.clicks
        case .fileDownloads: Strings.SiteDataTypes.fileDownloads
        case .searchTerms: Strings.SiteDataTypes.searchTerms
        case .videos: Strings.SiteDataTypes.videos
        case .archive: Strings.SiteDataTypes.archive
        case .utm: Strings.SiteDataTypes.utm
        }
    }

    var systemImage: String {
        switch self {
        case .postsAndPages: "text.page"
        case .referrers: "link"
        case .locations: "map"
        case .devices: "laptopcomputer.and.iphone"
        case .authors: "person"
        case .externalLinks: "cursorarrow.click"
        case .fileDownloads: "arrow.down.circle"
        case .searchTerms: "magnifyingglass"
        case .videos: "play.rectangle"
        case .archive: "folder"
        case .utm: "tag"
        }
    }

    var localizedColumnName: String {
        switch self {
        case .postsAndPages: Strings.TopListTitles.postsAndPages
        case .authors: Strings.TopListTitles.authors
        case .referrers: Strings.TopListTitles.referrers
        case .locations: Strings.TopListTitles.locations
        case .devices: Strings.TopListTitles.devices
        case .externalLinks: Strings.TopListTitles.clicks
        case .fileDownloads: Strings.TopListTitles.fileDownloads
        case .searchTerms: Strings.TopListTitles.searchTerms
        case .videos: Strings.TopListTitles.videos
        case .archive: Strings.TopListTitles.archive
        case .utm: Strings.TopListTitles.utm
        }
    }

    // MARK: - Item Grouping

    /// Content - What you published
    static let contentItems: [TopListItemType] = [
        .postsAndPages, .authors, .videos, .archive
    ]

    /// Traffic Sources - How they found you
    static let trafficSourceItems: [TopListItemType] = [
        .referrers, .searchTerms, .utm
    ]

    /// Audience & Engagement - Who visited & what they did
    static let audienceEngagementItems: [TopListItemType] = [
        .locations, .devices, .externalLinks, .fileDownloads
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
        case .locations, .devices:
            "https://wordpress.com/support/stats/audience-insights/"
        case .videos:
            "https://wordpress.com/support/stats/analyze-content-performance/#see-video-traffic"
        case .utm:
            "https://wordpress.com/support/stats/understand-traffic-sources/#use-utm-parameters"
        }
    }
}
