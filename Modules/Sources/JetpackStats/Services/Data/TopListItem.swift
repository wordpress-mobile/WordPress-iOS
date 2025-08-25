import Foundation

struct TopListResponse: Sendable {
    let items: [any TopListItemProtocol]
}

struct TopListItem: Sendable {
    let items: [any TopListItemProtocol]
}

/// - warning: It's required for animations in ``TopListItemsView`` to work
/// well for IDs to be unique across the domains. If we were just to use
/// `String`, there would be collisions across domains, e.g. post and author
/// using the same String ID "1".
struct TopListItemID: Hashable {
    let type: TopListItemType
    let id: String
}

protocol TopListItemProtocol: Codable, Sendable, Identifiable {
    var metrics: SiteMetricsSet { get set }
    var id: TopListItemID { get }
}

extension TopListItem {
    struct Post: Codable, TopListItemProtocol {
        let title: String
        let postID: String?
        var postURL: URL?
        let date: Date?
        let type: String?
        let author: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .postsAndPages, id: postID ?? title)
        }
    }

    struct Referrer: Codable, TopListItemProtocol {
        let name: String
        let domain: String?
        let iconURL: URL?
        let children: [Referrer]
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .referrers, id: (domain ?? "–") + name)
        }
    }

    struct Location: Codable, TopListItemProtocol {
        let country: String
        let flag: String?
        let countryCode: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .locations, id: countryCode ?? country)
        }
    }

    struct Author: Codable, TopListItemProtocol {
        let name: String
        let userId: String
        let role: String?
        var metrics: SiteMetricsSet
        var avatarURL: URL?
        var posts: [Post]?

        var id: TopListItemID {
            TopListItemID(type: .authors, id: userId)
        }
    }

    struct ExternalLink: Codable, TopListItemProtocol {
        let url: String
        let title: String?
        let children: [ExternalLink]
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .externalLinks, id: url)
        }
    }

    struct FileDownload: Codable, TopListItemProtocol {
        let fileName: String
        let filePath: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .fileDownloads, id: filePath ?? fileName)
        }
    }

    struct SearchTerm: Codable, TopListItemProtocol {
        let term: String
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .searchTerms, id: term)
        }
    }

    struct Video: Codable, TopListItemProtocol {
        let title: String
        let postId: String
        let videoURL: URL?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .videos, id: postId)
        }
    }

    struct ArchiveItem: Codable, TopListItemProtocol {
        let href: String
        let value: String
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .archive, id: href)
        }
    }

    struct ArchiveSection: Codable, TopListItemProtocol {
        let sectionName: String
        var items: [ArchiveItem]
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .archive, id: sectionName)
        }

        var displayName: String {
            sectionName.capitalized
        }
    }
}
