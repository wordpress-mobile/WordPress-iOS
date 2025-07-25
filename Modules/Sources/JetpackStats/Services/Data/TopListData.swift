import Foundation

struct TopListData: Sendable {
    let items: [any TopListItem]
}

protocol TopListItem: Codable, Sendable, Identifiable {
    var metrics: SiteMetricsSet { get set }
    var id: String { get }
}

protocol TopListExpandableItem: TopListItem {
    associatedtype ItemType: TopListItem
    var items: [ItemType] { get }
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

        var id: String { postID ?? title }
    }

    struct Referrer: Codable, TopListItem {
        let name: String
        let domain: String?
        var metrics: SiteMetricsSet

        var id: String { domain ?? name }
    }

    struct Location: Codable, TopListItem {
        let country: String
        let flag: String?
        let countryCode: String?
        var metrics: SiteMetricsSet

        var id: String { countryCode ?? country }
    }

    struct Author: Codable, TopListItem {
        let name: String
        let userId: String
        let role: String?
        var metrics: SiteMetricsSet
        var avatarURL: URL?

        var id: String { userId }
    }

    struct ExternalLink: Codable, TopListItem {
        let url: String
        let title: String?
        var metrics: SiteMetricsSet

        var id: String { url }
    }

    struct FileDownload: Codable, TopListItem {
        let fileName: String
        let filePath: String?
        var metrics: SiteMetricsSet

        var id: String { filePath ?? fileName }
    }

    struct SearchTerm: Codable, TopListItem {
        let term: String
        var metrics: SiteMetricsSet

        var id: String { term }
    }

    struct Video: Codable, TopListItem {
        let title: String
        let postId: String
        let videoUrl: URL?
        var metrics: SiteMetricsSet

        var id: String { postId }
    }

    struct ArchiveItem: Codable, TopListItem {
        let href: String
        let value: String
        var metrics: SiteMetricsSet

        var id: String { href }
    }

    struct ArchiveSection: Codable, TopListExpandableItem {
        let sectionName: String
        var items: [ArchiveItem]
        var metrics: SiteMetricsSet

        var id: String { sectionName }

        var displayName: String {
            switch sectionName.lowercased() {
            case "author":
                return Strings.ArchiveSections.author
            case "other":
                return Strings.ArchiveSections.other
            default:
                return sectionName.capitalized
            }
        }
    }
}
