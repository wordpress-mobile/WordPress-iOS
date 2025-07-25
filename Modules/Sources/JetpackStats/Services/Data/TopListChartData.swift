import Foundation

final class TopListChartData {
    let item: TopListItemType
    let metric: SiteMetric
    let items: [any TopListItem]
    let previousItems: [TopListItemID: any TopListItem]
    let maxValue: Int

    struct ListID: Hashable {
        let item: TopListItemType
        let metric: SiteMetric
    }

    var listID: ListID {
        ListID(item: item, metric: metric)
    }

    init(item: TopListItemType, metric: SiteMetric, items: [any TopListItem], previousItems: [TopListItemID: any TopListItem] = [:], maxValue: Int) {
        self.item = item
        self.metric = metric
        self.items = items
        self.previousItems = previousItems
        self.maxValue = maxValue
    }
    
    func previousItem(for currentItem: any TopListItem) -> (any TopListItem)? {
        previousItems[currentItem.id]
    }
}

// MARK: - Mock Data

extension TopListChartData {
    static func mock(
        for itemType: TopListItemType,
        metric: SiteMetric = .views,
        itemCount: Int = 6
    ) -> TopListChartData {
        let currentItems = mockItems(for: itemType, metric: metric, count: itemCount)
        
        // Create previous items dictionary
        var previousItemsDict: [TopListItemID: any TopListItem] = [:]
        for item in currentItems {
            let previousItem = mockPreviousItem(from: item, metric: metric)
            previousItemsDict[item.id] = previousItem
        }

        let maxValue = currentItems
            .compactMap { $0.metrics[metric] }
            .max() ?? 1

        return TopListChartData(
            item: itemType,
            metric: metric,
            items: currentItems,
            previousItems: previousItemsDict,
            maxValue: maxValue
        )
    }

    private static func mockItems(
        for item: TopListItemType,
        metric: SiteMetric,
        count: Int
    ) -> [any TopListItem] {
        switch item {
        case .postsAndPages:
            return mockPosts(metric: metric, count: count)
        case .referrers:
            return mockReferrers(metric: metric, count: count)
        case .locations:
            return mockLocations(metric: metric, count: count)
        case .authors:
            return mockAuthors(metric: metric, count: count)
        case .externalLinks:
            return mockExternalLinks(metric: metric, count: count)
        case .fileDownloads:
            return mockFileDownloads(metric: metric, count: count)
        case .searchTerms:
            return mockSearchTerms(metric: metric, count: count)
        case .videos:
            return mockVideos(metric: metric, count: count)
        case .archive:
            return mockArchive(metric: metric, count: count)
        }
    }

    private static func mockPosts(metric: SiteMetric, count: Int) -> [TopListData.Post] {
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

        return posts.prefix(count).enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.Post(
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

    private static func mockReferrers(metric: SiteMetric, count: Int) -> [TopListData.Referrer] {
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

        return referrers.prefix(count).enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.Referrer(
                name: data.0,
                domain: data.1,
                metrics: metrics
            )
        }
    }

    private static func mockLocations(metric: SiteMetric, count: Int) -> [TopListData.Location] {
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

        return locations.prefix(count).enumerated().map { index, data in
            let baseValue = data.3
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.Location(
                country: data.0,
                flag: data.2,
                countryCode: data.1,
                metrics: metrics
            )
        }
    }

    private static func mockAuthors(metric: SiteMetric, count: Int) -> [TopListData.Author] {
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

        return authors.prefix(count).enumerated().map { index, data in
            let baseValue = data.3
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.Author(
                name: data.0,
                userId: String(data.2),
                role: data.1,
                metrics: metrics,
                avatarURL: Bundle.module.path(forResource: "author\(data.2)", ofType: "jpg").map { URL(filePath: $0) }
            )
        }
    }

    private static func mockExternalLinks(metric: SiteMetric, count: Int) -> [TopListData.ExternalLink] {
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

        return links.prefix(count).enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.ExternalLink(
                url: data.1,
                title: data.0,
                metrics: metrics
            )
        }
    }

    private static func mockFileDownloads(metric: SiteMetric, count: Int) -> [TopListData.FileDownload] {
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

        return files.prefix(count).enumerated().map { index, data in
            let baseValue = data.2
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.FileDownload(
                fileName: data.0,
                filePath: data.1,
                metrics: metrics
            )
        }
    }

    private static func mockSearchTerms(metric: SiteMetric, count: Int) -> [TopListData.SearchTerm] {
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

        return terms.prefix(count).enumerated().map { index, data in
            let baseValue = data.1
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.SearchTerm(
                term: data.0,
                metrics: metrics
            )
        }
    }

    private static func mockVideos(metric: SiteMetric, count: Int) -> [TopListData.Video] {
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

        return videos.prefix(count).enumerated().map { index, data in
            let baseValue = data.3
            let metrics = createMetrics(baseValue: baseValue, metric: metric)
            return TopListData.Video(
                title: data.0,
                postId: data.1,
                videoUrl: URL(string: data.2),
                metrics: metrics
            )
        }
    }
    
    private static func mockArchive(metric: SiteMetric, count: Int) -> [any TopListItem] {
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
        
        return archiveSections.prefix(count).map { sectionData in
            let sectionName = sectionData.0
            let items = sectionData.1.map { itemData in
                let metrics = createMetrics(baseValue: itemData.1, metric: metric)
                return TopListData.ArchiveItem(
                    href: "https://example.com\(itemData.0)",
                    value: itemData.0,
                    metrics: metrics
                )
            }
            
            // Calculate total views for the section
            let totalViews = items.reduce(0) { $0 + ($1.metrics[metric] ?? 0) }
            
            return TopListData.ArchiveSection(
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

    private static func mockPreviousItem(from item: any TopListItem, metric: SiteMetric) -> any TopListItem {
        var item = item

        // Create previous value that's 70-130% of current value for realistic trends
        let trendFactor = Double.random(in: 0.7...1.3)
        let currentValue = item.metrics[metric] ?? 0
        item.metrics[metric] = Int(Double(currentValue) * trendFactor)
        
        // Special handling for archive sections - update child items too
        if var archiveSection = item as? TopListData.ArchiveSection {
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
