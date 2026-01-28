import Foundation
import SwiftUI
@preconcurrency import WordPressKit

actor MockStatsService: ObservableObject, StatsServiceProtocol {
    private var hourlyData: [SiteMetric: [DataPoint]] = [:]
    private var wordAdsHourlyData: [WordAdsMetric: [DataPoint]] = [:]
    private var dailyTopListData: [TopListItemType: [Date: [any TopListItemProtocol]]] = [:]
    private let calendar: Calendar

    let supportedMetrics = SiteMetric.allCases.filter {
        $0 != .downloads && $0 != .bounceRate && $0 != .timeOnSite
    }
    let supportedItems = TopListItemType.allCases

    private var delaysDisabled = false

    nonisolated func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        switch item {
        case .postsAndPages: [.views, .visitors, .comments, .likes]
        case .archive: [.views]
        case .referrers: [.views, .visitors]
        case .locations: [.views, .visitors]
        case .authors: [.views, .comments, .likes]
        case .externalLinks: [.views, .visitors]
        case .fileDownloads: [.downloads]
        case .searchTerms: [.views, .visitors]
        case .videos: [.views, .likes]
        }
    }

    /// - parameter timeZone: The reporting time zone of a site.
    init(timeZone: TimeZone = .current) {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        self.calendar = calendar
    }

    private func generateDataIfNeeded() async {
        guard hourlyData.isEmpty else {
            return
        }
        await generateChartMockData()
        await generateWordAdsMockData()
        await generateTopListMockData()
    }

    func disableDelays() {
        delaysDisabled = true
    }

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse {
        await generateDataIfNeeded()

        var total = SiteMetricsSet()
        var output: [SiteMetric: [DataPoint]] = [:]

        let aggregator = StatsDataAggregator(calendar: calendar)

        for (metric, allDataPoints) in hourlyData {
            // Filter data points for the period
            let filteredDataPoints = allDataPoints.filter {
                interval.start <= $0.date && $0.date < interval.end
            }

            // Use processPeriod to aggregate and normalize the data
            let periodData = aggregator.processPeriod(
                dataPoints: filteredDataPoints,
                dateInterval: interval,
                granularity: granularity,
                metric: metric
            )
            output[metric] = periodData.dataPoints
            total[metric] = periodData.total
        }

        if !delaysDisabled {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))
        }

        return SiteMetricsResponse(total: total, metrics: output)
    }

    func getWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse {
        await generateDataIfNeeded()

        // Calculate interval: from (date - quantity*units) to date
        guard let startDate = calendar.date(byAdding: granularity.component, value: -granularity.preferredQuantity, to: date) else {
            throw URLError(.unknown)
        }
        let interval = DateInterval(start: startDate, end: date)

        var output: [WordAdsMetric: [DataPoint]] = [:]

        let aggregator = StatsDataAggregator(calendar: calendar)

        let wordAdsMetrics: [WordAdsMetric] = [.impressions, .cpm, .revenue]

        for metric in wordAdsMetrics {
            guard let allDataPoints = wordAdsHourlyData[metric] else { continue }

            // Filter data points for the period
            let filteredDataPoints = allDataPoints.filter {
                interval.start <= $0.date && $0.date < interval.end
            }

            // Use processPeriod to aggregate and normalize the data
            let periodData = aggregator.processPeriod(
                dataPoints: filteredDataPoints,
                dateInterval: interval,
                granularity: granularity,
                metric: metric
            )
            output[metric] = periodData.dataPoints
        }

        // Calculate totals as Int (values already stored in cents)
        let totalAdsServed = output[.impressions]?.reduce(0) { $0 + $1.value } ?? 0
        let totalRevenue = output[.revenue]?.reduce(0) { $0 + $1.value } ?? 0
        let cpmValues = output[.cpm]?.filter { $0.value > 0 }.map { $0.value } ?? []
        let averageCPM = cpmValues.isEmpty ? 0 : cpmValues.reduce(0, +) / cpmValues.count

        let total = WordAdsMetricsSet(
            impressions: totalAdsServed,
            cpm: averageCPM,
            revenue: totalRevenue
        )

        if !delaysDisabled {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))
        }

        return WordAdsMetricsResponse(total: total, metrics: output)
    }

    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, locationLevel: LocationLevel?) async throws -> TopListResponse {
        await generateDataIfNeeded()

        guard let typeData = dailyTopListData[item] else {
            fatalError("data not configured for data type: \(item)")
        }

        // Filter data within the date range
        let filteredData = typeData.filter { date, _ in
            interval.start <= date && date < interval.end
        }

        // Aggregate all items across the date range
        var aggregatedItems: [TopListItemID: (any TopListItemProtocol, Int)] = [:] // Store item and aggregated metrics

        for (_, dailyItems) in filteredData {
            for item in dailyItems {
                let key = item.id
                if let (existingItem, existingValue) = aggregatedItems[key] {
                    // Aggregate based on metric
                    let metricValue = item.metrics[metric] ?? 0
                    aggregatedItems[key] = (existingItem, existingValue + metricValue)
                } else {
                    aggregatedItems[key] = (item, item.metrics[metric] ?? 0)
                }
            }
        }

        // Convert to array with updated metric value and sort
        let sortedItems = aggregatedItems.values
            .map { (item, totalValue) -> any TopListItemProtocol in
                // Create a mutable copy and update the aggregated metric value
                var mutableItem = item
                mutableItem.metrics[metric] = totalValue
                return mutableItem
            }
            .sorted { ($0.metrics[metric] ?? 0) > ($1.metrics[metric] ?? 0) }

        try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))

        return TopListResponse(items: Array(sortedItems.prefix(limit ?? Int.max)))
    }

    func getRealtimeTopListData(_ dataType: TopListItemType) async throws -> TopListResponse {
        // Load base items from JSON
        let baseItems = loadRealtimeBaseItems(for: dataType)

        // Add dynamic variations to simulate real-time changes
        let realtimeItems = baseItems.map { item -> any TopListItemProtocol in
            let baseViews = item.metrics.views ?? 0

            // Use time-based seed for consistent gradual changes
            let now = Date()
            let timeInMinutes = now.timeIntervalSince1970 / 60.0

            // Get item identifier for seeding
            let itemId = item.id
            let itemSeed = itemId.hashValue

            // Gradual oscillation (changes slowly over time)
            let slowWave = sin(timeInMinutes / 5.0 + Double(itemSeed % 100) / 10.0) * 0.1 + 1.0

            // Small random variation (±5%)
            let smallVariation = Double.random(in: 0.95...1.05)

            // Very rare small spike (1% chance, max 20% increase)
            let rareSpikeChance = Double.random(in: 0.0...1.0)
            let rareSpike = rareSpikeChance < 0.01 ? Double.random(in: 1.1...1.2) : 1.0

            let realtimeViews = Int(Double(baseViews) * slowWave * smallVariation * rareSpike)
            let cappedViews = min(realtimeViews, 500) // Cap at 500

            // Apply variations to create new item with updated values
            var mutableItem = item
            mutableItem.metrics.views = cappedViews

            if let comments = mutableItem.metrics.comments {
                mutableItem.metrics.comments = Int(Double(comments) * slowWave * smallVariation * rareSpike * 0.8)
            }
            if let likes = mutableItem.metrics.likes {
                mutableItem.metrics.likes = Int(Double(likes) * slowWave * smallVariation * rareSpike * 0.9)
            }
            if let visitors = mutableItem.metrics.visitors {
                mutableItem.metrics.visitors = Int(Double(visitors) * slowWave * smallVariation * rareSpike)
            }
            if let bounceRate = mutableItem.metrics.bounceRate {
                let bounceVariation = slowWave > 1.0 ? 0.95 : 1.05
                mutableItem.metrics.bounceRate = min(100, max(0, Int(Double(bounceRate) * bounceVariation * smallVariation)))
            }
            if let timeOnSite = mutableItem.metrics.timeOnSite {
                let timeVariation = Double.random(in: 0.85...1.15)
                mutableItem.metrics.timeOnSite = Int(Double(timeOnSite) * timeVariation)
            }
            if let downloads = mutableItem.metrics.downloads {
                mutableItem.metrics.downloads = Int(Double(downloads) * slowWave * smallVariation * rareSpike)
            }

            return mutableItem
        }

        // Sort by views and take top 10
        let sortedItems = realtimeItems
            .sorted { ($0.metrics.views ?? 0) > ($1.metrics.views ?? 0) }

        let topItems = Array(sortedItems.prefix(10))

        return TopListResponse(items: topItems)
    }

    private func loadRealtimeBaseItems(for dataType: TopListItemType) -> [any TopListItemProtocol] {
        let fileName: String
        switch dataType {
        case .postsAndPages:
            fileName = "postsAndPages"
        case .archive:
            fileName = "archive"
        case .referrers:
            fileName = "referrers"
        case .locations:
            fileName = "locations"
        case .authors:
            fileName = "authors"
        case .externalLinks:
            fileName = "external-links"
        case .fileDownloads:
            fileName = "file-downloads"
        case .searchTerms:
            fileName = "search-terms"
        case .videos:
            fileName = "videos"
        }

        // Load from JSON file
        guard let url = Bundle.module.url(forResource: "realtime-\(fileName)", withExtension: "json") else {
            print("Failed to find \(fileName).json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Decode based on data type
            switch dataType {
            case .referrers:
                let referrers = try decoder.decode([TopListItem.Referrer].self, from: data)
                return referrers
            case .locations:
                let locations = try decoder.decode([TopListItem.Location].self, from: data)
                return locations
            case .authors:
                let authors = try decoder.decode([TopListItem.Author].self, from: data)
                return authors.map {
                    var copy = $0
                    copy.avatarURL = Bundle.module.path(forResource: "author\($0.userId)", ofType: "jpg").map {
                        URL(filePath: $0)
                    }
                    return copy
                }
            case .externalLinks:
                let links = try decoder.decode([TopListItem.ExternalLink].self, from: data)
                return links
            case .fileDownloads:
                let downloads = try decoder.decode([TopListItem.FileDownload].self, from: data)
                return downloads
            case .searchTerms:
                let terms = try decoder.decode([TopListItem.SearchTerm].self, from: data)
                return terms
            case .videos:
                let videos = try decoder.decode([TopListItem.Video].self, from: data)
                return videos
            case .postsAndPages:
                let posts = try decoder.decode([TopListItem.Post].self, from: data)
                return posts
            case .archive:
                let sections = try decoder.decode([TopListItem.ArchiveSection].self, from: data)
                return sections
            }
        } catch {
            print("Failed to load \(fileName).json: \(error)")
            return []
        }
    }

    func getPostDetails(for postID: Int) async throws -> StatsPostDetails {
        // Load from JSON file in Mocks/Misc directory
        guard let url = Bundle.module.url(forResource: "post-details", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }

        let data = try Data(contentsOf: url)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: AnyObject]

        // Simulate network delay
        if !delaysDisabled {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))
        }

        guard let details = StatsPostDetails(jsonDictionary: jsonObject) else {
            throw URLError(.cannotParseResponse)
        }

        return details
    }

    func getPostLikes(for postID: Int, count: Int) async throws -> PostLikesData {
        // Simulate network delay
        if !delaysDisabled {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))
        }

        func makeUser(id: Int, name: String) -> PostLikesData.PostLikeUser {
            PostLikesData.PostLikeUser(
                id: id,
                name: name,
                avatarURL: Bundle.module.path(forResource: "author\(id)", ofType: "jpg").map { URL(filePath: $0) }
            )
        }

        let mockUsers = [
            makeUser(id: 1, name: "Sarah Chen"),
            makeUser(id: 2, name: "Marcus Johnson"),
            makeUser(id: 3, name: "Emily Rodriguez"),
            makeUser(id: 4, name: "Alex Thompson"),
            makeUser(id: 5, name: "Nina Patel"),
            makeUser(id: 6, name: "James Wilson")
        ]

        let requestedCount = min(count, mockUsers.count)
        let selectedUsers = Array(mockUsers.prefix(requestedCount))

        return PostLikesData(users: selectedUsers, totalCount: 26)
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws {
        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))

        // Mock implementation - randomly succeed or fail for testing
        let shouldSucceed = Double.random(in: 0...1) > 0.1 // 90% success rate
        if !shouldSucceed {
            throw URLError(.networkConnectionLost)
        }
    }

    func getEmailOpens(for postID: Int) async throws -> StatsEmailOpensData {
        // Simulate network delay
        if !delaysDisabled {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))
        }

        // Generate realistic random data
        let totalSends = Int.random(in: 500...5000)
        let uniqueOpens = Int.random(in: 100...min(totalSends, 2000))
        let totalOpens = Int.random(in: uniqueOpens...min(totalSends * 2, uniqueOpens * 3))
        let opensRate = Double(uniqueOpens) / Double(totalSends)

        return StatsEmailOpensData(
            totalSends: totalSends,
            uniqueOpens: uniqueOpens,
            totalOpens: totalOpens,
            opensRate: opensRate
        )
    }

    func getWordAdsEarnings() async throws -> WordPressKit.StatsWordAdsEarningsResponse {
        // Simulate network delay
        if !delaysDisabled {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))
        }

        // Generate mock earnings data for the last 12 months
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        var wordadsDict: [String: [String: Any]] = [:]
        var totalEarnings: Double = 0
        var totalAmountOwed: Double = 0

        // Generate earnings for last 12 months
        for monthsAgo in 0..<12 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthsAgo, to: now) else {
                continue
            }

            let period = dateFormatter.string(from: monthDate)

            // Generate realistic earnings that increase over time
            let baseAmount = Double.random(in: 2000...5000)
            let growthFactor = 1.0 + (Double(12 - monthsAgo) * 0.08) // More recent months earn more
            let amount = baseAmount * growthFactor

            totalEarnings += amount

            // Months older than 2 months are paid, recent months are outstanding
            let isPaid = monthsAgo > 2
            let status = isPaid ? "1" : "0"

            if !isPaid {
                totalAmountOwed += amount
            }

            // Generate realistic pageviews
            let basePageviews = Int.random(in: 50...500)
            let pageviewsGrowth = 1.0 + (Double(12 - monthsAgo) * 0.1)
            let pageviews = Int(Double(basePageviews) * pageviewsGrowth)

            wordadsDict[period] = [
                "amount": amount,
                "status": status,
                "pageviews": String(pageviews)
            ]
        }

        let jsonDictionary: [String: Any] = [
            "ID": 238291108,
            "name": "Mock Site",
            "URL": "https://mocksite.wordpress.com",
            "earnings": [
                "total_earnings": String(format: "%.2f", totalEarnings),
                "total_amount_owed": String(format: "%.2f", totalAmountOwed),
                "wordads": wordadsDict,
                "sponsored": [],
                "adjustment": []
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary)
        let response = try JSONDecoder().decode(WordPressKit.StatsWordAdsEarningsResponse.self, from: jsonData)

        return response
    }

    // MARK: - Data Loading

    /// Loads historical items from JSON files based on the data type
    private func loadHistoricalItems(for dataType: TopListItemType) -> [any TopListItemProtocol] {
        let fileName: String
        switch dataType {
        case .postsAndPages:
            fileName = "historical-postsAndPages"
        case .archive:
            fileName = "historical-archive"
        case .referrers:
            fileName = "historical-referrers"
        case .locations:
            fileName = "historical-locations"
        case .authors:
            fileName = "historical-authors"
        case .externalLinks:
            fileName = "historical-external-links"
        case .fileDownloads:
            fileName = "historical-file-downloads"
        case .searchTerms:
            fileName = "historical-search-terms"
        case .videos:
            fileName = "historical-videos"
        }

        // Load from JSON file
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "json") else {
            print("Failed to find \(fileName).json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Decode based on data type
            switch dataType {
            case .referrers:
                let referrers = try decoder.decode([TopListItem.Referrer].self, from: data)
                return referrers
            case .locations:
                let locations = try decoder.decode([TopListItem.Location].self, from: data)
                return locations
            case .authors:
                let authors = try decoder.decode([TopListItem.Author].self, from: data)
                return authors.map {
                    var copy = $0
                    copy.avatarURL = Bundle.module.path(forResource: "author\($0.userId)", ofType: "jpg").map {
                        URL(filePath: $0)
                    }
                    return copy
                }
            case .externalLinks:
                let links = try decoder.decode([TopListItem.ExternalLink].self, from: data)
                return links
            case .fileDownloads:
                let downloads = try decoder.decode([TopListItem.FileDownload].self, from: data)
                return downloads
            case .searchTerms:
                let terms = try decoder.decode([TopListItem.SearchTerm].self, from: data)
                return terms
            case .videos:
                let videos = try decoder.decode([TopListItem.Video].self, from: data)
                return videos
            case .postsAndPages:
                let posts = try decoder.decode([TopListItem.Post].self, from: data)
                return posts
            case .archive:
                let sections = try decoder.decode([TopListItem.ArchiveSection].self, from: data)
                return sections
            }
        } catch {
            print("Failed to load \(fileName).json: \(error)")
            return []
        }
    }

    // MARK: - Data Generation

    /// Calculates a recency boost factor for the given date
    private func calculateRecentBoost(for date: Date) -> Double {
        // NOT using Calendar as it's pretty slow and we don't need the precision
        let isRecent = abs(date.timeIntervalSinceNow) < 86400 * 7
        return isRecent ? Double.random(in: 1.05...1.30) : 1.0
    }

    /// Mutates item metrics based on growth factors and variations
    private func mutateItemMetrics(_ item: any TopListItemProtocol, growthFactor: Double, recentBoost: Double, seasonalFactor: Double, weekendFactor: Double, randomFactor: Double) -> any TopListItemProtocol {
        let combinedFactor = growthFactor * recentBoost * seasonalFactor * weekendFactor * randomFactor

        var item = item
        if let views = item.metrics.views {
            item.metrics.views = Int(Double(views) * combinedFactor)
        }
        if let comments = item.metrics.comments {
            item.metrics.comments = Int(Double(comments) * combinedFactor * 0.8)
        }
        if let likes = item.metrics.likes {
            item.metrics.likes = Int(Double(likes) * combinedFactor * 0.9)
        }
        if let visitors = item.metrics.visitors {
            item.metrics.visitors = Int(Double(visitors) * combinedFactor)
        }
        if let bounceRate = item.metrics.bounceRate {
            let bounceVariation = randomFactor > 1.0 ? 0.95 : 1.05
            item.metrics.bounceRate = min(100, max(0, Int(Double(bounceRate) * bounceVariation / recentBoost)))
        }
        if let timeOnSite = item.metrics.timeOnSite {
            let timeVariation = Double.random(in: 0.85...1.15)
            item.metrics.timeOnSite = Int(Double(timeOnSite) * recentBoost * timeVariation)
        }
        if let downloads = item.metrics.downloads {
            item.metrics.downloads = Int(Double(downloads) * combinedFactor)
        }
        return item
    }

    private func generateChartMockData() async {
        let endDate = Date()

        // Create a date for Nov 1, 2011
        var dateComponents = DateComponents()
        dateComponents.year = 2011
        dateComponents.month = 11
        dateComponents.day = 1

        let startDate = calendar.date(from: dateComponents)!

        for dataType in SiteMetric.allCases {
            var dataPoints: [DataPoint] = []

            var currentDate = startDate
            let nowDate = Date()
            while currentDate <= endDate && currentDate <= nowDate {
                let value = generateRealisticValue(for: dataType, at: currentDate)
                let dataPoint = DataPoint(date: currentDate, value: value)
                dataPoints.append(dataPoint)
                currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
            }

            hourlyData[dataType] = dataPoints
        }
    }

    private func generateWordAdsMockData() async {
        let endDate = Date()

        // Create a date for Nov 1, 2011
        var dateComponents = DateComponents()
        dateComponents.year = 2011
        dateComponents.month = 11
        dateComponents.day = 1

        let startDate = calendar.date(from: dateComponents)!

        var adsServedPoints: [DataPoint] = []
        var revenuePoints: [DataPoint] = []
        var cpmPoints: [DataPoint] = []

        var currentDate = startDate
        let nowDate = Date()
        while currentDate <= endDate && currentDate <= nowDate {
            let components = calendar.dateComponents([.year, .month, .weekday, .hour], from: currentDate)
            let hour = components.hour!
            let dayOfWeek = components.weekday!
            let month = components.month!
            let year = components.year!

            // Base values and growth factors
            let yearsSince2011 = year - 2011
            let growthFactor = 1.0 + (Double(yearsSince2011) * 0.15)

            // Recent period boost
            let recentBoost = calculateRecentBoost(for: currentDate)

            // Seasonal factor
            let seasonalFactor = 1.0 + 0.2 * sin(2.0 * .pi * (Double(month - 3) / 12.0))

            // Day of week factor
            let weekendFactor = (dayOfWeek == 1 || dayOfWeek == 7) ? 0.7 : 1.0

            // Hour of day factor
            let hourFactor = 0.5 + 0.5 * sin(2.0 * .pi * (Double(hour - 9) / 24.0))

            // Random variation
            let randomFactor = Double.random(in: 0.8...1.2)

            let combinedFactor = growthFactor * recentBoost * seasonalFactor * weekendFactor * randomFactor * hourFactor

            // Ads Served (impressions)
            let adsServed = Int(200 * combinedFactor)
            adsServedPoints.append(DataPoint(date: currentDate, value: adsServed))

            // CPM (stored in cents)
            let baseCPM = 2.5 // $2.50
            let cpmVariation = Double.random(in: 0.7...1.3)
            let cpm = Int((baseCPM * growthFactor * cpmVariation) * 100)
            cpmPoints.append(DataPoint(date: currentDate, value: cpm))

            // Revenue (stored in cents, calculated from impressions and CPM)
            let revenue = Int(Double(adsServed) * (Double(cpm) / 100.0) / 1000.0 * 100)
            revenuePoints.append(DataPoint(date: currentDate, value: revenue))

            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
        }

        wordAdsHourlyData[WordAdsMetric.impressions] = adsServedPoints
        wordAdsHourlyData[WordAdsMetric.revenue] = revenuePoints
        wordAdsHourlyData[WordAdsMetric.cpm] = cpmPoints
    }

    private var memoizedDateComponents: [Date: DateComponents] = [:]

    private func generateRealisticValue(for metric: SiteMetric, at date: Date) -> Int {

        let components: DateComponents = {
            if let components = memoizedDateComponents[date] {
                return components
            }
            let components = calendar.dateComponents([.year, .month, .weekday, .hour], from: date)
            memoizedDateComponents[date] = components
            return components
        }()
        let hour = components.hour!
        let dayOfWeek = components.weekday!
        let month = components.month!
        let year = components.year!

        // Base values and growth factors
        let yearsSince2011 = year - 2011
        let growthFactor = 1.0 + (Double(yearsSince2011) * 0.15) // 15% yearly growth

        // Recent period boost
        let recentBoost = calculateRecentBoost(for: date)

        // Seasonal factor (higher in fall/winter)
        let seasonalFactor = 1.0 + 0.2 * sin(2.0 * .pi * (Double(month - 3) / 12.0))

        // Day of week factor (lower on weekends)
        let weekendFactor = (dayOfWeek == 1 || dayOfWeek == 7) ? 0.7 : 1.0

        // Hour of day factor (peak at 2pm, lowest at 3am)
        let hourFactor = 0.5 + 0.5 * sin(2.0 * .pi * (Double(hour - 9) / 24.0))

        // Random variation
        let randomFactor = Double.random(in: 0.8...1.2)

        let combinedFactor = growthFactor * recentBoost * seasonalFactor * weekendFactor * randomFactor * hourFactor

        switch metric {
        case .views:
            return Int(1000 * combinedFactor)

        case .visitors:
            return Int(400 * combinedFactor)

        case .likes:
            return Int(10 * combinedFactor)

        case .comments:
            return Int(3 * combinedFactor)

        case .posts:
            return Int(1 * combinedFactor)

        case .timeOnSite:
            let baseTime = 170.0
            return Int((baseTime * recentBoost) + Double.random(in: -40...40))

        case .bounceRate:
            let engagementFactor = growthFactor * seasonalFactor
            return Int((75 - (5 * engagementFactor)) / recentBoost + Double.random(in: -5...5))

        case .downloads:
            return Int(50 * combinedFactor)
        }
    }

    private func generateTopListMockData() async {
        let endDate = Date()

        var dateComponents = DateComponents()
        dateComponents.year = 2011
        dateComponents.month = 11
        dateComponents.day = 1

        let startDate = calendar.date(from: dateComponents)!

        // Generate daily data for each type
        for dataType in TopListItemType.allCases {
            var typeData: [Date: [any TopListItemProtocol]] = [:]

            // Load base items from JSON files
            let baseItems = loadHistoricalItems(for: dataType)

            // Skip if no items to process
            if baseItems.isEmpty {
                dailyTopListData[dataType] = typeData
                continue
            }

            var currentDate = startDate
            let nowDate = Date()
            while currentDate <= endDate && currentDate <= nowDate {
                let dayOfWeek = calendar.component(.weekday, from: currentDate)
                let month = calendar.component(.month, from: currentDate)
                let year = calendar.component(.year, from: currentDate)

                // Calculate daily variations
                let yearsSince2011 = year - 2011
                let growthFactor = 1.0 + (Double(yearsSince2011) * 0.12)

                // Recent period boost
                let recentBoost = calculateRecentBoost(for: currentDate)

                let seasonalFactor = 1.0 + 0.15 * sin(2.0 * .pi * (Double(month - 3) / 12.0))
                let weekendFactor = (dayOfWeek == 1 || dayOfWeek == 7) ? 0.7 : 1.0
                let randomFactor = Double.random(in: 0.8...1.2)

                // Apply mutations to each item for this day
                let dailyItems = baseItems.map { item in
                    var mutatedItem = mutateItemMetrics(item, growthFactor: growthFactor, recentBoost: recentBoost, seasonalFactor: seasonalFactor, weekendFactor: weekendFactor, randomFactor: randomFactor)

                    // If it's an Author with posts, mutate the posts too
                    if let author = mutatedItem as? TopListItem.Author, let posts = author.posts {
                        var mutatedAuthor = author
                        mutatedAuthor.posts = posts.map { post in
                            var mutatedPost = post
                            // Apply similar mutation factors to post metrics
                            let postRandomFactor = Double.random(in: 0.9...1.1) // Slight variation per post
                            let postCombinedFactor = growthFactor * recentBoost * seasonalFactor * weekendFactor * randomFactor * postRandomFactor

                            if let views = post.metrics.views {
                                mutatedPost.metrics.views = Int(Double(views) * postCombinedFactor)
                            }
                            if let comments = post.metrics.comments {
                                mutatedPost.metrics.comments = Int(Double(comments) * postCombinedFactor * 0.8)
                            }
                            if let likes = post.metrics.likes {
                                mutatedPost.metrics.likes = Int(Double(likes) * postCombinedFactor * 0.9)
                            }
                            if let visitors = post.metrics.visitors {
                                mutatedPost.metrics.visitors = Int(Double(visitors) * postCombinedFactor)
                            }
                            return mutatedPost
                        }
                        mutatedItem = mutatedAuthor
                    }

                    return mutatedItem
                }

                let startOfDay = calendar.startOfDay(for: currentDate)
                typeData[startOfDay] = dailyItems
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

            dailyTopListData[dataType] = typeData
        }
    }

}
