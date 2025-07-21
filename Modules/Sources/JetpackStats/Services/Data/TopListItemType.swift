import SwiftUI

enum TopListItemType: Identifiable, CaseIterable {
    case postsAndPages
    case posts
    case pages
    case authors
    case referrers
    case locations
    case externalLinks

    var id: TopListItemType { self }

    var localizedTitle: String {
        switch self {
        case .postsAndPages: Strings.SiteDataTypes.postsAndPages
        case .posts: Strings.SiteDataTypes.posts
        case .pages: Strings.SiteDataTypes.pages
        case .authors: Strings.SiteDataTypes.authors
        case .referrers: Strings.SiteDataTypes.referrers
        case .locations: Strings.SiteDataTypes.locations
        case .externalLinks: Strings.SiteDataTypes.externalLinks
        }
    }

    var systemImage: String {
        switch self {
        case .postsAndPages: "doc.on.doc"
        case .posts: "doc.text"
        case .pages: "doc"
        case .referrers: "link"
        case .locations: "map"
        case .authors: "person.2"
        case .externalLinks: "cursorarrow.click"
        }
    }

    var availableMetrics: [SiteMetric] {
        switch self {
        case .postsAndPages, .posts, .pages: [.views, .visitors, .comments, .likes]
        case .referrers: [.views, .views]
        case .locations: [.views, .views]
        case .authors: [.views, .comments, .likes]
        case .externalLinks: [.views, .visitors]
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
        }
    }
}
