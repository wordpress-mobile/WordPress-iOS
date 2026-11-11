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
    var displayName: String { get }
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

        var displayName: String {
            title
        }

        /// The ID the site's own REST API knows this post by.
        ///
        /// `nil` for the homepage, which stats reports with an ID of 0 and which has no
        /// featured image of its own to look up.
        var numericPostID: Int? {
            guard let postID, let value = Int(postID), value > 0 else {
                return nil
            }
            return value
        }

        /// The glyph that tells a post apart from a page.
        ///
        /// Only a post gets the post glyph; a page, the homepage and anything the stats
        /// API doesn't name get the page one. Old Stats split the same four types three
        /// ways instead: the homepage had a house glyph of its own, and a type stats
        /// couldn't name drew the post glyph. So a homepage row reads as a page here
        /// where it used to read as a home.
        var typeSystemImage: String {
            type?.lowercased() == "post" ? "text.page" : "doc"
        }
    }

    struct Referrer: Codable, TopListItemProtocol {
        let name: String
        let domain: String?
        let url: URL?
        let iconURL: URL?
        let children: [Referrer]
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .referrers, id: (domain ?? "–") + name)
        }

        var displayName: String {
            name
        }

        var spamDomain: String? {
            domain ?? children.first?.domain
        }

        var canMarkAsSpam: Bool {
            guard spamDomain != nil else { return false }
            if let url {
                return url.absoluteString.contains(name)
            }
            return name.contains(".")
        }
    }

    struct Location: Codable, TopListItemProtocol {
        let name: String
        let flag: String?
        let countryCode: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .locations, id: name)
        }

        var displayName: String {
            name
        }
    }

    struct Device: Codable, TopListItemProtocol {
        let name: String
        let breakdown: DeviceBreakdown
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .devices, id: name)
        }

        var displayName: String {
            name.capitalized
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

        var displayName: String {
            name
        }
    }

    struct ExternalLink: Codable, TopListItemProtocol {
        let url: String
        let title: String?
        /// The favicon of the site the link points to, when the stats API names one.
        var iconURL: URL?
        let children: [ExternalLink]
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .externalLinks, id: url + (title ?? ""))
        }

        var displayName: String {
            title ?? url
        }
    }

    struct FileDownload: Codable, TopListItemProtocol {
        let fileName: String
        let filePath: String?
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .fileDownloads, id: filePath ?? fileName)
        }

        var displayName: String {
            fileName
        }
    }

    struct SearchTerm: Codable, TopListItemProtocol {
        let term: String
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .searchTerms, id: term)
        }

        var displayName: String {
            term
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

        var displayName: String {
            title
        }
    }

    struct ArchiveItem: Codable, TopListItemProtocol {
        let href: String
        let value: String
        var metrics: SiteMetricsSet

        var id: TopListItemID {
            TopListItemID(type: .archive, id: href)
        }

        var displayName: String {
            value
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

    struct UTMMetric: Codable, TopListItemProtocol {
        let label: String
        let values: [String]
        var metrics: SiteMetricsSet
        var posts: [Post]?

        var id: TopListItemID {
            TopListItemID(type: .utm, id: label)
        }

        var displayName: String {
            label
        }
    }
}
