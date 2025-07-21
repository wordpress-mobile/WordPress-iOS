import Foundation

struct TopListChartData {
    struct Item {
        let current: any TopListItem
        let previous: (any TopListItem)?
    }

    let item: TopListItemType
    let metric: SiteMetric
    let items: [Item]
    let maxValue: Int

    struct ListID: Hashable {
        let item: TopListItemType
        let metric: SiteMetric
    }

    var listID: ListID {
        ListID(item: item, metric: metric)
    }
}

// MARK: - Mock Data

extension TopListChartData {
    static func mock(
        for item: TopListItemType,
        metric: SiteMetric = .views,
        itemCount: Int = 6
    ) -> TopListChartData {
        let items = mockItems(for: item, metric: metric, count: itemCount)
        let matchedItems = items.map { item in
            // Create previous item with slightly different values
            let previousItem = mockPreviousItem(from: item, metric: metric)
            return Item(current: item, previous: previousItem)
        }

        let maxValue = items
            .compactMap { $0.metrics[metric] }
            .max() ?? 1

        return TopListChartData(
            item: item,
            metric: metric,
            items: matchedItems,
            maxValue: maxValue
        )
    }

    private static func mockItems(
        for item: TopListItemType,
        metric: SiteMetric,
        count: Int
    ) -> [any TopListItem] {
        switch item {
        case .postsAndPages, .posts, .pages:
            return mockPosts(metric: metric, count: count)
        case .referrers:
            return mockReferrers(metric: metric, count: count)
        case .locations:
            return mockLocations(metric: metric, count: count)
        case .authors:
            return mockAuthors(metric: metric, count: count)
        case .externalLinks:
            return mockExternalLinks(metric: metric, count: count)
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
                postId: "\(index + 1)",
                date: nil,
                pageId: nil,
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
            return SiteMetricsSet(comments: Int(Double(value) * postsRatio))
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

        return item
    }
}
