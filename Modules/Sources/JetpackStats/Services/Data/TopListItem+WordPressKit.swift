import Foundation
@preconcurrency import WordPressKit

extension TopListItem.Post {
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

extension TopListItem.Referrer {
    init(_ referrer: WordPressKit.StatsReferrer) {
        self.init(
            name: referrer.title,
            domain: referrer.url?.host,
            iconURL: referrer.iconURL,
            children: referrer.children.map { TopListItem.Referrer($0) },
            metrics: SiteMetricsSet(views: referrer.viewsCount)
        )
    }
}

extension TopListItem.Location {
    init(_ country: WordPressKit.StatsCountry) {
        self.init(
            name: country.name,
            flag: Self.countryCodeToEmoji(country.code),
            countryCode: country.code,
            metrics: SiteMetricsSet(views: country.viewsCount)
        )
    }

    init(_ region: WordPressKit.StatsTopRegionTimeIntervalData.Region) {
        self.init(
            name: region.name,
            flag: Self.countryCodeToEmoji(region.countryCode),
            countryCode: region.countryCode,
            metrics: SiteMetricsSet(views: region.viewsCount)
        )
    }

    init(_ city: WordPressKit.StatsTopCityTimeIntervalData.City) {
        self.init(
            name: city.name,
            flag: Self.countryCodeToEmoji(city.countryCode),
            countryCode: city.countryCode,
            metrics: SiteMetricsSet(views: city.viewsCount)
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

extension TopListItem.Author {
    init(_ author: WordPressKit.StatsTopAuthor, dateFormatter: DateFormatter) {
        self.init(
            name: author.name,
            userId: author.name, // NOTE: WordPressKit doesn't provide user ID
            role: nil,
            metrics: SiteMetricsSet(views: author.viewsCount),
            avatarURL: author.iconURL,
            posts: author.posts.map { TopListItem.Post($0, dateFormatter: dateFormatter) }
        )
    }
}

extension TopListItem.ExternalLink {
    init(_ click: WordPressKit.StatsClick) {
        self.init(
            url: click.clickedURL?.absoluteString ?? "",
            title: click.title,
            children: click.children.map { TopListItem.ExternalLink($0) },
            metrics: SiteMetricsSet(views: click.clicksCount)
        )
    }
}

extension TopListItem.FileDownload {
    init(_ download: WordPressKit.StatsFileDownload) {
        self.init(
            fileName: URL(string: download.file)?.lastPathComponent ?? download.file,
            filePath: download.file,
            metrics: SiteMetricsSet(downloads: download.downloadCount)
        )
    }
}

extension TopListItem.SearchTerm {
    init(_ searchTerm: WordPressKit.StatsSearchTerm) {
        self.init(
            term: searchTerm.term,
            metrics: SiteMetricsSet(views: searchTerm.viewsCount)
        )
    }
}

extension TopListItem.Video {
    init(_ video: WordPressKit.StatsVideo) {
        self.init(
            title: video.title,
            postId: String(video.postID),
            videoURL: video.videoURL,
            metrics: SiteMetricsSet(views: video.playsCount)
        )
    }
}

extension TopListItem.ArchiveItem {
    init(_ item: WordPressKit.StatsArchiveItem) {
        self.init(
            href: item.href,
            value: item.value,
            metrics: SiteMetricsSet(views: item.views)
        )
    }
}

extension TopListItem.ArchiveSection {
    init(sectionName: String, items: [WordPressKit.StatsArchiveItem]) {
        let archiveItems = items.map { TopListItem.ArchiveItem($0) }
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
