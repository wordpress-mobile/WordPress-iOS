import Foundation

struct TopListData: Sendable {
    let items: [any TopListItem]
}

protocol TopListItem: Codable, Sendable, Identifiable {
    var metrics: TopListData.Metrics { get set }
    var id: String { get }
}

extension TopListData {
    struct Metrics: Codable {
        var views: Int?
        var visitors: Int?
        var likes: Int?
        var comments: Int?
        var bounceRate: Int?
        var timeOnSite: Int?

        subscript(metric: SiteMetric) -> Int? {
            switch metric {
            case .views: views
            case .visitors: visitors
            case .likes: likes
            case .comments: comments
            case .bounceRate: bounceRate
            case .timeOnSite: timeOnSite
            }
        }
    }

    struct Post: Codable, TopListItem {
        let title: String
        let postId: String?
        let pageId: String?
        let type: String?
        let author: String?
        var metrics: Metrics

        var id: String { postId ?? pageId ?? title }
    }

    struct Referrer: Codable, TopListItem {
        let name: String
        let domain: String?
        var metrics: Metrics

        var id: String { domain ?? name }
    }

    struct Location: Codable, TopListItem {
        let country: String
        let flag: String?
        let countryCode: String?
        var metrics: Metrics

        var id: String { countryCode ?? country }
    }

    struct Author: Codable, TopListItem {
        let name: String
        let userId: String
        let role: String?
        var metrics: Metrics
        var avatarURL: URL?

        var id: String { userId }
    }

    struct ExternalLink: Codable, TopListItem {
        let url: String
        let title: String?
        var metrics: Metrics

        var id: String { url }
    }
}
