import Foundation

struct TopListData: Sendable {
    let items: [any TopListItem]
}

/// - warning: It's required for animations in ``TopListItemsView`` to work
/// well for IDs to be unique across the domains. If we were just to use
/// `String`, there would be collisions across domains, e.g. post and author
/// using the same String ID "1".
struct TopListItemID: Hashable {
    let type: TopListItemType
    let id: String
}

protocol TopListItem: Codable, Sendable, Identifiable {
    var metrics: SiteMetricsSet { get set }
    var id: TopListItemID { get }
}

protocol TopListExpandableItem: TopListItem {
    var children: [any TopListItem] { get }
    var displayName: String { get }
}

extension TopListData {
    struct Post: Codable, TopListItem {
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

    struct Referrer: Codable, TopListItem {
        let name: String
        let domain: String?
        let iconURL: URL?
        let children: [Referrer]
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .referrers, id: (domain ?? "–") + name)
        }
    }

    struct Location: Codable, TopListItem {
        let country: String
        let flag: String?
        let countryCode: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .locations, id: countryCode ?? country)
        }
    }

    struct Author: Codable, TopListItem {
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

    struct ExternalLink: Codable, TopListItem {
        let url: String
        let title: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .externalLinks, id: url)
        }
    }

    struct FileDownload: Codable, TopListItem {
        let fileName: String
        let filePath: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .fileDownloads, id: filePath ?? fileName)
        }
    }

    struct SearchTerm: Codable, TopListItem {
        let term: String
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .searchTerms, id: term)
        }
    }

    struct Video: Codable, TopListItem {
        let title: String
        let postId: String
        let videoUrl: URL?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .videos, id: postId)
        }
    }

    struct ArchiveItem: Codable, TopListItem {
        let href: String
        let value: String
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .archive, id: href)
        }
    }

    struct ArchiveSection: Codable, TopListExpandableItem {
        let sectionName: String
        var items: [ArchiveItem]
        var metrics: SiteMetricsSet

        var children: [any TopListItem] { items }

        var id: TopListItemID {
            TopListItemID(type: .archive, id: sectionName)
        }

        var displayName: String {
            switch sectionName.lowercased() {
            case "author": Strings.ArchiveSections.author
            case "other": Strings.ArchiveSections.other
            default: sectionName.capitalized
            }
        }
    }
}
