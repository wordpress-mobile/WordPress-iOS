import Foundation
import WordPressKit

extension TopListData.Post {
    init(_ post: WordPressKit.StatsTopPost, dateFormatter: DateFormatter) {
        self.init(
            title: post.title,
            postID: String(post.postID),
            postURL: post.postURL,
            date: post.date.flatMap(dateFormatter.date),
            type: post.kind.description,
            author: nil,
            metrics: SiteMetricsSet(views: post.viewsCount)
        )
    }
}

extension TopListData.Referrer {
    init(_ referrer: WordPressKit.StatsReferrer) {
        self.init(
            name: referrer.title,
            domain: referrer.url?.host,
            iconURL: referrer.iconURL,
            children: referrer.children.map { TopListData.Referrer($0) },
            metrics: SiteMetricsSet(views: referrer.viewsCount)
        )
    }
}

extension TopListData.Location {
    init(_ country: WordPressKit.StatsCountry) {
        self.init(
            country: country.name,
            flag: Self.countryCodeToEmoji(country.code),
            countryCode: country.code,
            metrics: SiteMetricsSet(views: country.viewsCount)
        )
    }

    private static func countryCodeToEmoji(_ code: String) -> String? {
        let base: UInt32 = 127397
        var scalarView = String.UnicodeScalarView()
        for i in code.uppercased().unicodeScalars {
            guard let scalar = UnicodeScalar(base + i.value) else { return nil }
            scalarView.append(scalar)
        }
        return String(scalarView)
    }
}

extension TopListData.Author {
    init(_ author: WordPressKit.StatsTopAuthor, dateFormatter: DateFormatter) {
        self.init(
            name: author.name,
            userId: author.name, // NOTE: WordPressKit doesn't provide user ID
            role: nil,
            metrics: SiteMetricsSet(views: author.viewsCount),
            avatarURL: author.iconURL,
            posts: author.posts.map { TopListData.Post($0, dateFormatter: dateFormatter) }
        )
    }
}

extension TopListData.ExternalLink {
    init(_ click: WordPressKit.StatsClick) {
        self.init(
            url: click.clickedURL?.absoluteString ?? "",
            title: click.title,
            metrics: SiteMetricsSet(views: click.clicksCount)
        )
    }
}

extension TopListData.FileDownload {
    init(_ download: WordPressKit.StatsFileDownload) {
        self.init(
            fileName: URL(string: download.file)?.lastPathComponent ?? download.file,
            filePath: download.file,
            metrics: SiteMetricsSet(downloads: download.downloadCount)
        )
    }
}

extension TopListData.SearchTerm {
    init(_ searchTerm: WordPressKit.StatsSearchTerm) {
        self.init(
            term: searchTerm.term,
            metrics: SiteMetricsSet(views: searchTerm.viewsCount)
        )
    }
}

extension TopListData.Video {
    init(_ video: WordPressKit.StatsVideo) {
        self.init(
            title: video.title,
            postId: String(video.postID),
            videoURL: video.videoURL,
            metrics: SiteMetricsSet(views: video.playsCount)
        )
    }
}

extension TopListData.ArchiveItem {
    init(_ item: WordPressKit.StatsArchiveItem) {
        self.init(
            href: item.href,
            value: item.value,
            metrics: SiteMetricsSet(views: item.views)
        )
    }
}

extension TopListData.ArchiveSection {
    init(sectionName: String, items: [WordPressKit.StatsArchiveItem]) {
        let archiveItems = items.map { TopListData.ArchiveItem($0) }
        let totalViews = items.reduce(0) { $0 + $1.views }

        self.init(
            sectionName: sectionName,
            items: archiveItems,
            metrics: SiteMetricsSet(views: totalViews)
        )
    }
}

private extension StatsTopPost.Kind {
    var description: String {
        switch self {
        case .post: "post"
        case .page: "page"
        case .homepage: "homepage"
        case .unknown: "unknown"
        }
    }
}
