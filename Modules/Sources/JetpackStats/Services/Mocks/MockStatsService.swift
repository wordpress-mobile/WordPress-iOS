import Foundation
import SwiftUI

actor MockStatsService: ObservableObject, StatsServiceProtocol {
    private var hourlyData: [SiteMetric: [DataPoint]] = [:]
    private var dailyTopListData: [TopListItemType: [Date: [any TopListItem]]] = [:]
    private let calendar: Calendar

    let supportedMetrics = SiteMetric.allCases
    let supportedItems = TopListItemType.allCases

    nonisolated func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        switch item {
        case .postsAndPages, .posts, .pages: [.views, .visitors, .comments, .likes]
        case .referrers: [.views, .visitors]
        case .locations: [.views, .visitors]
        case .authors: [.views, .comments, .likes]
        case .externalLinks: [.views, .visitors]
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
        await generateTopListMockData()
    }

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsData {
        await generateDataIfNeeded()

        var total = SiteMetricsSet()
        var output: [SiteMetric: [DataPoint]] = [:]

        for (metric, dataPoints) in hourlyData {
            // This isn't efficient by any means but it will do for the mocking purposes
            let filteredDataPoints = dataPoints.filter {
                interval.start <= $0.date && $0.date < interval.end
            }
            let dataPoints = aggregateData(filteredDataPoints, granularity: granularity, range: interval, metric: metric)
            output[metric] = dataPoints
            total[metric] = DataPoint.getTotalValue(for: dataPoints, metric: metric)
        }

        try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))

        return SiteMetricsData(total: total, metrics: output)
    }

    func getTopListData(_ dataType: TopListItemType, interval: DateInterval, granularity: DateRangeGranularity) async throws -> TopListData {
        await generateDataIfNeeded()

        guard let typeData = dailyTopListData[dataType] else {
            fatalError("data not configured for data type: \(dataType)")
        }

        // Filter data within the date range
        let filteredData = typeData.filter { date, _ in
            interval.start <= date && date < interval.end
        }

        // Aggregate all items across the date range
        var aggregatedItems: [String: (any TopListItem, Int)] = [:] // Store item and aggregated metrics

        for (_, dailyItems) in filteredData {
            for item in dailyItems {
                let key = item.id
                if let (existingItem, existingViews) = aggregatedItems[key] {
                    // Aggregate views
                    aggregatedItems[key] = (existingItem, existingViews + (item.metrics.views ?? 0))
                } else {
                    aggregatedItems[key] = (item, item.metrics.views ?? 0)
                }
            }
        }

        // Convert to array with updated views and sort
        let sortedItems = aggregatedItems.values
            .map { (item, totalViews) -> any TopListItem in
                // Create a mutable copy and update the aggregated views
                var mutableItem = item
                mutableItem.metrics.views = totalViews
                return mutableItem
            }
            .sorted { ($0.metrics.views ?? 0) > ($1.metrics.views ?? 0) }

        try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))

        return TopListData(items: Array(sortedItems.prefix(20)))
    }

    func getRealtimeTopListData(_ dataType: TopListItemType) async throws -> TopListData {
        // Load base items from JSON
        let baseItems = loadRealtimeBaseItems(for: dataType)

        // Add dynamic variations to simulate real-time changes
        let realtimeItems = baseItems.map { item -> any TopListItem in
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

            return mutableItem
        }

        // Sort by views and take top 10
        let sortedItems = realtimeItems
            .sorted { ($0.metrics.views ?? 0) > ($1.metrics.views ?? 0) }

        let topItems = Array(sortedItems.prefix(10))

        return TopListData(
            items: topItems
        )
    }

    private func loadRealtimeBaseItems(for dataType: TopListItemType) -> [any TopListItem] {
        let fileName: String
        switch dataType {
        case .posts:
            fileName = "posts"
        case .pages:
            fileName = "pages"
        case .postsAndPages:
            // Load both posts and pages
            let posts = loadRealtimeBaseItems(for: .posts)
            let pages = loadRealtimeBaseItems(for: .pages)
            return posts + pages
        case .referrers:
            fileName = "referrers"
        case .locations:
            fileName = "locations"
        case .authors:
            fileName = "authors"
        case .externalLinks:
            // Return empty array for now as we're not implementing mocks yet
            return []
        }

        // Load from JSON file
        guard let url = Bundle.module.url(forResource: "realtime-\(fileName)", withExtension: "json") else {
            print("Failed to find \(fileName).json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            // Decode based on data type
            switch dataType {
            case .posts, .pages:
                let posts = try decoder.decode([TopListData.Post].self, from: data)
                return posts
            case .referrers:
                let referrers = try decoder.decode([TopListData.Referrer].self, from: data)
                return referrers
            case .locations:
                let locations = try decoder.decode([TopListData.Location].self, from: data)
                return locations
            case .authors:
                let authors = try decoder.decode([TopListData.Author].self, from: data)
                return authors.map {
                    var copy = $0
                    copy.avatarURL = Bundle.module.path(forResource: "author\($0.userId)", ofType: "jpg").map {
                        URL(filePath: $0)
                    }
                    return copy
                }
            case .postsAndPages, .externalLinks:
                return [] // Already handled above
            }
        } catch {
            print("Failed to load \(fileName).json: \(error)")
            return []
        }
    }

    // MARK: - Data Aggregation

    /// Aggregates raw data into data points based on granularity
    private func aggregateData(_ dataPoints: [DataPoint], granularity: DateRangeGranularity, range: DateInterval, metric: SiteMetric) -> [DataPoint] {
        let aggregator = StatsDataAggregator(calendar: calendar)

        // Step 1: Perform aggregation
        let aggregatedData = aggregator.aggregate(dataPoints, granularity: granularity)

        // Step 2: Normalize data for metrics that need averaging
        let normalizedData = aggregator.normalizeForMetric(aggregatedData, metric: metric)

        // Step 3: Generate complete data points
        let dateSequence = aggregator.generateDateSequence(dateInterval: range, by: granularity.component)

        // Map dates to data points, using 0 for missing values
        return dateSequence.map { date in
            let aggregationDate = aggregator.makeAggegationDate(for: date, granularity: granularity)
            return DataPoint(date: date, value: normalizedData[aggregationDate ?? date] ?? 0)
        }
    }

    /// Loads historical items from JSON files based on the data type
    private func loadHistoricalItems(for dataType: TopListItemType) -> [any TopListItem] {
        let fileName: String
        switch dataType {
        case .posts:
            fileName = "historical-posts"
        case .pages:
            fileName = "historical-pages"
        case .postsAndPages:
            // Load both posts and pages
            let posts = loadHistoricalItems(for: .posts)
            let pages = loadHistoricalItems(for: .pages)
            return posts + pages
        case .referrers:
            fileName = "historical-referrers"
        case .locations:
            fileName = "historical-locations"
        case .authors:
            fileName = "historical-authors"
        case .externalLinks:
            // Return empty array for now as we're not implementing mocks yet
            return []
        }

        // Load from JSON file
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "json") else {
            print("Failed to find \(fileName).json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            // Decode based on data type
            switch dataType {
            case .posts, .pages:
                let posts = try decoder.decode([TopListData.Post].self, from: data)
                return posts
            case .referrers:
                let referrers = try decoder.decode([TopListData.Referrer].self, from: data)
                return referrers
            case .locations:
                let locations = try decoder.decode([TopListData.Location].self, from: data)
                return locations
            case .authors:
                let authors = try decoder.decode([TopListData.Author].self, from: data)
                return authors.map {
                    var copy = $0
                    copy.avatarURL = Bundle.module.path(forResource: "author\($0.userId)", ofType: "jpg").map {
                        URL(filePath: $0)
                    }
                    return copy
                }
            case .postsAndPages, .externalLinks:
                return [] // Already handled above
            }
        } catch {
            print("Failed to load \(fileName).json: \(error)")
            return []
        }
    }

    // MARK: - Data Generation

    /// Mutates item metrics based on growth factors and variations
    private func mutateItemMetrics(_ item: any TopListItem, growthFactor: Double, seasonalFactor: Double, weekendFactor: Double, randomFactor: Double) -> any TopListItem {
        let combinedFactor = growthFactor * seasonalFactor * weekendFactor * randomFactor

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
            item.metrics.bounceRate = min(100, max(0, Int(Double(bounceRate) * bounceVariation)))
        }
        if let timeOnSite = item.metrics.timeOnSite {
            let timeVariation = Double.random(in: 0.85...1.15)
            item.metrics.timeOnSite = Int(Double(timeOnSite) * timeVariation)
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

    private func generateRealisticValue(for metric: SiteMetric, at date: Date) -> Int {
        let hour = calendar.component(.hour, from: date)
        let dayOfWeek = calendar.component(.weekday, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        // Base values and growth factors
        let yearsSince2011 = year - 2011
        let growthFactor = 1.0 + (Double(yearsSince2011) * 0.15) // 15% yearly growth

        // Seasonal factor (higher in fall/winter)
        let seasonalFactor = 1.0 + 0.2 * sin(2.0 * .pi * (Double(month - 3) / 12.0))

        // Day of week factor (lower on weekends)
        let weekendFactor = (dayOfWeek == 1 || dayOfWeek == 7) ? 0.7 : 1.0

        // Hour of day factor (peak at 2pm, lowest at 3am)
        let hourFactor = 0.5 + 0.5 * sin(2.0 * .pi * (Double(hour - 9) / 24.0))

        // Random variation
        let randomFactor = Double.random(in: 0.8...1.2)

        switch metric {
        case .views:
            let baseValue = 1000.0
            return Int(baseValue * growthFactor * seasonalFactor * weekendFactor * hourFactor * randomFactor)

        case .visitors:
            let baseValue = 400.0
            return Int(baseValue * growthFactor * seasonalFactor * weekendFactor * hourFactor * randomFactor)

        case .likes:
            let baseValue = 10.0
            return Int(baseValue * growthFactor * seasonalFactor * weekendFactor * randomFactor)

        case .comments:
            let baseValue = 3.0
            return Int(baseValue * growthFactor * seasonalFactor * weekendFactor * randomFactor)

        case .posts:
            let baseValue = 1.0
            return Int(baseValue * growthFactor * seasonalFactor * weekendFactor * randomFactor)

        case .timeOnSite:
            // Time in seconds - doesn't follow same patterns
            return Int(170 + Double.random(in: -40...40))

        case .bounceRate:
            // Percentage - inverse relationship with engagement
            let engagementFactor = growthFactor * seasonalFactor
            return Int(75 - (5 * engagementFactor) + Double.random(in: -5...5))
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
            var typeData: [Date: [any TopListItem]] = [:]

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
                let seasonalFactor = 1.0 + 0.15 * sin(2.0 * .pi * (Double(month - 3) / 12.0))
                let weekendFactor = (dayOfWeek == 1 || dayOfWeek == 7) ? 0.7 : 1.0
                let randomFactor = Double.random(in: 0.8...1.2)

                // Apply mutations to each item for this day
                let dailyItems = baseItems.map { item in
                    mutateItemMetrics(item, growthFactor: growthFactor, seasonalFactor: seasonalFactor, weekendFactor: weekendFactor, randomFactor: randomFactor)
                }

                let startOfDay = calendar.startOfDay(for: currentDate)
                typeData[startOfDay] = dailyItems
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

            dailyTopListData[dataType] = typeData
        }
    }
}
