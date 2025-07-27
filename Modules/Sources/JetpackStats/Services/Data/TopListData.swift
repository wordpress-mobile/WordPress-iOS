import Foundation

final class TopListData {
    let item: TopListItemType
    let metric: SiteMetric
    let items: [any TopListItemProtocol]
    let previousItems: [TopListItemID: any TopListItemProtocol]
    let metrics: Metrics

    struct Metrics {
        let maxValue: Int
        let total: Int
        let previousTotal: Int
    }

    struct ListID: Hashable {
        let item: TopListItemType
        let metric: SiteMetric
    }

    var listID: ListID {
        ListID(item: item, metric: metric)
    }

    init(item: TopListItemType, metric: SiteMetric, items: [any TopListItemProtocol], previousItems: [TopListItemID: any TopListItemProtocol] = [:]) {
        self.item = item
        self.metric = metric
        self.items = items
        self.previousItems = previousItems

        // Precompute metrics
        let maxValue = items.compactMap { $0.metrics[metric] }.max() ?? 0
        let total = items.reduce(0) { $0 + ($1.metrics[metric] ?? 0) }
        let previousTotal = previousItems.values.reduce(0) { $0 + ($1.metrics[metric] ?? 0) }

        self.metrics = Metrics(
            maxValue: maxValue,
            total: total,
            previousTotal: previousTotal
        )
    }

    func previousItem(for currentItem: any TopListItemProtocol) -> (any TopListItemProtocol)? {
        previousItems[currentItem.id]
    }
}

// MARK: - Mock Data

extension TopListData {
    private struct CacheKey: Hashable {
        let itemType: TopListItemType
        let metric: SiteMetric
        let itemCount: Int
    }

    @MainActor
    private static var mockDataCache: [CacheKey: TopListData] = [:]

    @MainActor
    static func mock(
        for itemType: TopListItemType,
        metric: SiteMetric = .views,
        itemCount: Int = 6
    ) -> TopListData {
        let cacheKey = CacheKey(itemType: itemType, metric: metric, itemCount: itemCount)

        // Return cached data if available
        if let cachedData = mockDataCache[cacheKey] {
            return cachedData
        }

        let currentItems = mockItems(for: itemType, metric: metric)
            .prefix(itemCount)

        // Create previous items dictionary
        var previousItemsDict: [TopListItemID: any TopListItemProtocol] = [:]
        for item in currentItems {
            let previousItem = mockPreviousItem(from: item, metric: metric)
            previousItemsDict[item.id] = previousItem
        }

        let chartData = TopListData(
            item: itemType,
            metric: metric,
            items: Array(currentItems),
            previousItems: previousItemsDict
        )

        // Cache the generated data
        mockDataCache[cacheKey] = chartData

        return chartData
    }

    private static func mockItems(for item: TopListItemType, metric: SiteMetric) -> [any TopListItemProtocol] {
        switch item {
        case .postsAndPages: mockPosts(metric: metric)
        case .referrers: mockReferrers(metric: metric)
        case .locations: mockLocations(metric: metric)
        case .authors: mockAuthors(metric: metric)
        case .externalLinks: mockExternalLinks(metric: metric)
        case .fileDownloads: mockFileDownloads(metric: metric)
        case .searchTerms: mockSearchTerms(metric: metric)
        case .videos: mockVideos(metric: metric)
        case .archive: mockArchive(metric: metric)
        }
    }

    private static func mockPosts(metric: SiteMetric) -> [TopListItem.Post] {
        let posts = [
            ("Getting Started with SwiftUI", "John Doe", 3500),
            ("Understanding Async/Await in Swift", "Jane Smith", 2800),
            ("Building Better iOS Apps", "Mike Johnson", 2200),
            ("SwiftUI vs UIKit: A Comparison", "Sarah Wilson", 1900),
            ("Advanced Swift Techniques", "Tom Brown", 1600),
            ("iOS App Architecture Patterns", "Emma Davis", 1300),
            ("Swift Performance Tips", "Chris Miller", 1000),
            ("Debugging in Xcode", "Lisa Anderson", 850)
        ]

        return posts.enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.Post(
                title: data.0,
                postID: "\(index + 1)",
                postURL: nil,
                date: nil,
                type: nil,
                author: data.1,
                metrics: metrics
            )
        }
    }

    private static func mockReferrers(metric: SiteMetric) -> [TopListItem.Referrer] {
        let referrers = [
            ("Google", "google.com", 4200),
            ("Twitter", "twitter.com", 3100),
            ("Facebook", "facebook.com", 2400),
            ("LinkedIn", "linkedin.com", 1800),
            ("Reddit", "reddit.com", 1500),
            ("Stack Overflow", "stackoverflow.com", 1200),
            ("GitHub", "github.com", 900),
            ("Medium", "medium.com", 600)
        ]

        return referrers.enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.Referrer(
                name: data.0,
                domain: data.1,
                iconURL: nil,
                children: [
                    TopListItem.Referrer(
                        name: "wordpress development tutorial",
                        domain: "google.com",
                        iconURL: URL(string: "https://www.google.com/favicon.ico"),
                        children: [],
                        metrics: SiteMetricsSet(views: 850)
                    ),
                    TopListItem.Referrer(
                        name: "swift programming blog",
                        domain: "google.com",
                        iconURL: URL(string: "https://www.google.com/favicon.ico"),
                        children: [],
                        metrics: SiteMetricsSet(views: 750)
                    ),
                    TopListItem.Referrer(
                        name: "ios app development best practices",
                        domain: "google.com",
                        iconURL: URL(string: "https://www.google.com/favicon.ico"),
                        children: [],
                        metrics: SiteMetricsSet(views: 600)
                    )
                ],
                metrics: metrics
            )
        }
    }

    private static func mockLocations(metric: SiteMetric) -> [TopListItem.Location] {
        let locations = [
            ("United States", "US", "🇺🇸", 5600),
            ("United Kingdom", "GB", "🇬🇧", 3200),
            ("Canada", "CA", "🇨🇦", 2800),
            ("Germany", "DE", "🇩🇪", 2100),
            ("France", "FR", "🇫🇷", 1800),
            ("Japan", "JP", "🇯🇵", 1500),
            ("Australia", "AU", "🇦🇺", 1200),
            ("Netherlands", "NL", "🇳🇱", 900)
        ]

        return locations.enumerated().map { index, data in
            let baseValue = data.3
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.Location(
                country: data.0,
                flag: data.2,
                countryCode: data.1,
                metrics: metrics
            )
        }
    }

    private static func mockAuthors(metric: SiteMetric) -> [TopListItem.Author] {
        let authors = [
            ("Alex Thompson", "Editor", 1, 2400),
            ("Maria Garcia", "Contributor", 2, 2100),
            ("David Chen", "Editor", 3, 1800),
            ("Sophie Martin", "Author", 4, 1500),
            ("James Wilson", "Contributor", 5, 1200),
            ("Emma Johnson", "Editor", 6, 900),
            ("Michael Brown", "Author", 7, 600),
            ("Sarah Davis", "Contributor", 8, 400)
        ]

        return authors.enumerated().map { index, data in
            let baseValue = data.3
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.Author(
                name: data.0,
                userId: String(data.2),
                role: data.1,
                metrics: metrics,
                avatarURL: Bundle.module.path(forResource: "author\(data.2)", ofType: "jpg").map { URL(filePath: $0) }
            )
        }
    }

    private static func mockExternalLinks(metric: SiteMetric) -> [TopListItem.ExternalLink] {
        let links = [
            ("Apple Developer", "https://developer.apple.com", 1800),
            ("Swift.org", "https://swift.org", 1500),
            ("GitHub", "https://github.com", 1200),
            ("Stack Overflow", "https://stackoverflow.com", 1000),
            ("Ray Wenderlich", "https://raywenderlich.com", 800),
            ("NSHipster", "https://nshipster.com", 600),
            ("Hacking with Swift", "https://hackingwithswift.com", 450),
            ("SwiftUI Lab", "https://swiftui-lab.com", 300)
        ]

        return links.enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.ExternalLink(
                url: data.1,
                title: data.0,
                children: [],
                metrics: metrics
            )
        }
    }

    private static func mockFileDownloads(metric: SiteMetric) -> [TopListItem.FileDownload] {
        let files = [
            ("annual-report-2024.pdf", "/downloads/reports/annual-report-2024.pdf", 2500),
            ("swift-cheatsheet.pdf", "/downloads/docs/swift-cheatsheet.pdf", 2100),
            ("app-screenshots.zip", "/downloads/media/app-screenshots.zip", 1800),
            ("tutorial-video.mp4", "/downloads/videos/tutorial-video.mp4", 1500),
            ("code-samples.zip", "/downloads/code/code-samples.zip", 1200),
            ("whitepaper.pdf", "/downloads/docs/whitepaper.pdf", 900),
            ("presentation.pptx", "/downloads/presentations/presentation.pptx", 600),
            ("dataset.csv", "/downloads/data/dataset.csv", 400)
        ]

        return files.enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.FileDownload(
                fileName: data.0,
                filePath: data.1,
                metrics: metrics
            )
        }
    }

    private static func mockSearchTerms(metric: SiteMetric) -> [TopListItem.SearchTerm] {
        let terms = [
            ("swiftui tutorial", 3200),
            ("ios development guide", 2800),
            ("swift async await", 2400),
            ("xcode tips", 2000),
            ("swift performance", 1600),
            ("ios app architecture", 1200),
            ("swiftui animation", 800),
            ("swift best practices", 500)
        ]

        return terms.enumerated().map { index, data in
            let baseValue = data.1
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.SearchTerm(
                term: data.0,
                metrics: metrics
            )
        }
    }

    private static func mockVideos(metric: SiteMetric) -> [TopListItem.Video] {
        let videos = [
            ("Getting Started with SwiftUI", "101", "https://example.com/videos/swiftui-intro.mp4", 4500),
            ("iOS Development Best Practices", "102", "https://example.com/videos/best-practices.mp4", 3800),
            ("Advanced Swift Techniques", "103", "https://example.com/videos/advanced-swift.mp4", 3200),
            ("Building Custom Views", "104", "https://example.com/videos/custom-views.mp4", 2600),
            ("App Performance Optimization", "105", "https://example.com/videos/performance.mp4", 2000),
            ("Debugging Like a Pro", "106", "https://example.com/videos/debugging.mp4", 1500),
            ("SwiftUI Animations", "107", "https://example.com/videos/animations.mp4", 1000),
            ("Testing Strategies", "108", "https://example.com/videos/testing.mp4", 700)
        ]

        return videos.enumerated().map { index, data in
            let baseValue = data.3
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListItem.Video(
                title: data.0,
                postId: data.1,
                videoURL: URL(string: data.2),
                metrics: metrics
            )
        }
    }

    private static func mockArchive(metric: SiteMetric) -> [any TopListItemProtocol] {
        // Create mock archive sections
        let archiveSections = [
            ("pages", [
                ("/about/", 2500),
                ("/contact/", 1800),
                ("/privacy-policy/", 1200),
                ("/terms-of-service/", 800),
                ("/faq/", 600)
            ]),
            ("categories", [
                ("/category/technology/", 3200),
                ("/category/design/", 2800),
                ("/category/business/", 2400),
                ("/category/lifestyle/", 1600)
            ]),
            ("tags", [
                ("/tag/swift/", 2100),
                ("/tag/ios/", 1900),
                ("/tag/swiftui/", 1700),
                ("/tag/mobile/", 1400)
            ]),
            ("archives", [
                ("/2024/01/", 1500),
                ("/2023/12/", 1300),
                ("/2023/11/", 1100),
                ("/2023/10/", 900)
            ])
        ]

        return archiveSections.map { sectionData in
            let sectionName = sectionData.0
            let items = sectionData.1.map { itemData in
                let metrics = createMetrics(baseValue: itemData.1, metric: metric)
                return TopListItem.ArchiveItem(
                    href: "https://example.com\(itemData.0)",
                    value: itemData.0,
                    metrics: metrics
                )
            }

            // Calculate total views for the section
            let totalViews = items.reduce(0) { $0 + ($1.metrics[metric] ?? 0) }

            return TopListItem.ArchiveSection(
                sectionName: sectionName,
                items: items,
                metrics: SiteMetricsSet(views: totalViews)
            )
        }
    }

    private static func createMetrics(baseValue: Int, metric: SiteMetric) -> SiteMetricsSet {
        // Add some variation to make it more realistic
        let variation = Double.random(in: 0.8...1.2)
        let value = Int(Double(baseValue) * variation)

        switch metric {
        case .views:
            return SiteMetricsSet(views: value)
        case .visitors:
            // Visitors are typically 60-80% of views
            let visitorRatio = Double.random(in: 0.6...0.8)
            return SiteMetricsSet(visitors: Int(Double(value) * visitorRatio))
        case .likes:
            // Likes are typically 2-5% of views
            let likeRatio = Double.random(in: 0.02...0.05)
            return SiteMetricsSet(likes: Int(Double(value) * likeRatio))
        case .comments:
            // Comments are typically 0.5-2% of views
            let commentRatio = Double.random(in: 0.005...0.02)
            return SiteMetricsSet(comments: Int(Double(value) * commentRatio))
        case .posts:
            let postsRatio = Double.random(in: 0.002...0.005)
            return SiteMetricsSet(posts: Int(Double(value) * postsRatio))
        case .downloads:
            // Generic count metric (used for downloads, etc.)
            return SiteMetricsSet(downloads: value)
        case .timeOnSite:
            // Time on site not applicable for top list items
            return SiteMetricsSet(views: value)
        case .bounceRate:
            // Bounce rate not applicable for top list items
            return SiteMetricsSet(views: value)
        }
    }

    private static func mockPreviousItem(from item: any TopListItemProtocol, metric: SiteMetric) -> any TopListItemProtocol {
        var item = item

        // Create previous value that's 70-130% of current value for realistic trends
        let trendFactor = Double.random(in: 0.7...1.3)
        let currentValue = item.metrics[metric] ?? 0
        item.metrics[metric] = Int(Double(currentValue) * trendFactor)

        // Special handling for archive sections - update child items too
        if var archiveSection = item as? TopListItem.ArchiveSection {
            archiveSection.items = archiveSection.items.map { archiveItem in
                var mutableItem = archiveItem
                let itemCurrentValue = mutableItem.metrics[metric] ?? 0
                mutableItem.metrics[metric] = Int(Double(itemCurrentValue) * trendFactor)
                return mutableItem
            }
            return archiveSection
        }

        return item
    }
}
