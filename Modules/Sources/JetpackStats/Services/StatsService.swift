import Foundation
import WordPressShared
@preconcurrency import WordPressKit

/// - warning: The dates in StatsServiceRemoteV2 are represented in TimeZone.local
/// despite it accepting `siteTimezone` as a parameter. The parameter was
/// added later and is only used in a small subset of methods, which means
/// thay we have to convert the dates from the local time zone to the
/// site reporting time zone (as expected by the app).
actor StatsService: StatsServiceProtocol {
    private let siteID: Int
    private let api: WordPressComRestApi
    private let service: StatsServiceRemoteV2
    private let siteTimeZone: TimeZone
    // Temporary
    private var mocks: MockStatsService

    // Cache
    private var siteStatsCache: [SiteStatsCacheKey: CachedEntity<SiteMetricsResponse>] = [:]
    private var wordAdsStatsCache: [WordAdsStatsCacheKey: CachedEntity<WordAdsMetricsResponse>] = [:]
    private var topListCache: [TopListCacheKey: CachedEntity<TopListResponse>] = [:]
    private let currentPeriodTTL: TimeInterval = 30 // 30 seconds for current period

    let supportedMetrics: [SiteMetric] = [
        .views, .visitors, .likes, .comments, .posts
    ]

    let supportedItems: [TopListItemType] = [
        .postsAndPages, .authors, .referrers, .locations, .devices,
        .externalLinks, .fileDownloads, .searchTerms, .videos, .archive, .utm
    ]

    nonisolated func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        switch item {
        case .postsAndPages: [.views]
        case .archive: [.views]
        case .referrers: [.views]
        case .locations: [.views]
        case .devices: [.views]
        case .authors: [.views]
        case .externalLinks: [.views]
        case .fileDownloads: [.downloads]
        case .searchTerms: [.views]
        case .videos: [.views]
        case .utm: [.views]
        }
    }

    init(siteID: Int, api: WordPressComRestApi, timeZone: TimeZone) {
        self.siteID = siteID
        self.api = api
        self.service = StatsServiceRemoteV2(
            wordPressComRestApi: api,
            siteID: siteID,
            siteTimezone: timeZone
        )
        self.siteTimeZone = timeZone
        self.mocks = MockStatsService(timeZone: timeZone)
    }

    // MARK: - StatsServiceProtocol

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse {
        // Check cache first
        let cacheKey = SiteStatsCacheKey(interval: interval, granularity: granularity)

        if let cached = siteStatsCache[cacheKey], !cached.isExpired {
            return cached.data
        }

        // Fetch fresh data
        let data = try await fetchSiteStats(interval: interval, granularity: granularity)

        // Cache the result
        // Historical data never expires (ttl = nil), current period data expires after 30 seconds
        let ttl = intervalContainsCurrentDate(interval) ? currentPeriodTTL : nil

        siteStatsCache[cacheKey] = CachedEntity(data: data, timestamp: Date(), ttl: ttl)

        return data
    }

    private func fetchSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse {
        let interval = convertDateIntervalSiteToLocal(interval)

        if granularity == .hour {
            // Hourly data is available only for "Views", so the service has to
            // make a separate request to fetch the total metrics.
            async let hourlyResponseTask: WordPressKit.StatsSiteMetricsResponse = service.getData(interval: interval, unit: .init(granularity), limit: 0)
            async let dailyResponseTask: WordPressKit.StatsSiteMetricsResponse = service.getData(interval: interval, unit: .init(.day), limit: 0)

            let (hourlyResponse, dailyResponse) = try await (hourlyResponseTask, dailyResponseTask)

            var data = mapSiteMetricsResponse(hourlyResponse)
            data.total = mapSiteMetricsResponse(dailyResponse).total
            return data
        } else {
            let response: WordPressKit.StatsSiteMetricsResponse = try await service.getData(interval: interval, unit: .init(granularity), limit: 0)
            return mapSiteMetricsResponse(response)
        }
    }

    func getWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse {
        // Check cache first
        let cacheKey = WordAdsStatsCacheKey(date: date, granularity: granularity)

        if let cached = wordAdsStatsCache[cacheKey], !cached.isExpired {
            return cached.data
        }

        // Fetch fresh data
        let data = try await fetchWordAdsStats(date: date, granularity: granularity)

        // Cache the result
        // Historical data never expires (ttl = nil), current period data expires after 30 seconds
        let ttl = dateIsToday(date) ? currentPeriodTTL : nil

        wordAdsStatsCache[cacheKey] = CachedEntity(data: data, timestamp: Date(), ttl: ttl)

        return data
    }

    func getWordAdsEarnings() async throws -> WordPressKit.StatsWordAdsEarningsResponse {
        try await service.getWordAdsEarnings()
    }

    private func fetchWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse {
        let localDate = convertDateSiteToLocal(date)

        let response: WordPressKit.StatsWordAdsResponse = try await service.getData(
            date: localDate,
            unit: .init(granularity),
            quantity: granularity.preferredQuantity
        )

        return mapWordAdsResponse(response)
    }

    private func mapWordAdsResponse(_ response: WordPressKit.StatsWordAdsResponse) -> WordAdsMetricsResponse {
        var calendar = Calendar.current
        calendar.timeZone = siteTimeZone

        let now = Date.now

        func makeDataPoint(from data: WordPressKit.StatsWordAdsResponse.PeriodData, metric: WordPressKit.StatsWordAdsResponse.Metric) -> DataPoint? {
            guard let value = data[metric] else {
                return nil
            }
            let date = convertDateToSiteTimezone(data.date, using: calendar)
            guard date <= now else {
                return nil // Filter out future dates
            }
            // Store revenue and CPM in cents to use Int for DataPoint.
            // The revenue is always in US dollars.
            let intValue = metric == .impressions ? Int(value) : Int(value * 100)
            return DataPoint(date: date, value: intValue)
        }

        var total = WordAdsMetricsSet()
        var metrics: [WordAdsMetric: [DataPoint]] = [:]

        // Map WordPressKit metrics to WordAdsMetric
        let metricMapping: [(WordAdsMetric, WordPressKit.StatsWordAdsResponse.Metric)] = [
            (.impressions, .impressions),
            (.cpm, .cpm),
            (.revenue, .revenue)
        ]

        for (wordAdsMetric, wpKitMetric) in metricMapping {
            let dataPoints = response.data.compactMap {
                makeDataPoint(from: $0, metric: wpKitMetric)
            }
            metrics[wordAdsMetric] = dataPoints
            total[wordAdsMetric] = DataPoint.getTotalValue(for: dataPoints, metric: wordAdsMetric)
        }

        return WordAdsMetricsResponse(total: total, metrics: metrics)
    }

    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, options: TopListItemOptions) async throws -> TopListResponse {
        // Check cache first
        let cacheKey = TopListCacheKey(item: item, metric: metric, options: options, interval: interval, granularity: granularity, limit: limit)
        if let cached = topListCache[cacheKey], !cached.isExpired {
            return cached.data
        }

        // Fetch fresh data
        do {
            let data = try await _getTopListData(item, metric: metric, interval: interval, granularity: granularity, limit: limit, options: options)

            // Cache the result
            // Historical data never expires (ttl = nil), current period data expires after 30 seconds
            let ttl = intervalContainsCurrentDate(interval) ? currentPeriodTTL : nil
            topListCache[cacheKey] = CachedEntity(data: data, timestamp: Date(), ttl: ttl)

            return data
        } catch {
            if let error = StatsFeatureGateError.from(apiError: error, itemType: item) {
                throw error
            }
            // A workaround for an issue where `/stats` return `"summary": null`
            // when there are no recoreded periods (happens when the entire requested
            // period is _before_ the site creation).
            if let error = error as? StatsServiceRemoteV2.ResponseError,
               error == .emptySummary {
                return TopListResponse(items: [])
            }
            throw error
        }
    }

    private func _getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, options: TopListItemOptions) async throws -> TopListResponse {

        func getData<T: WordPressKit.StatsTimeIntervalData>(
            _ type: T.Type,
            parameters: [String: String]? = nil
        ) async throws -> T where T: Sendable {
            /// The `summarize: true` feature works correctly only with the `.day` granularity.
            let interval = convertDateIntervalSiteToLocal(interval)
            return try await service.getData(interval: interval, unit: .day, summarize: true, limit: limit ?? 0, parameters: parameters)
        }

        // Helper function to sort items by metric value (descending), then by displayName, and then by itemID for stable ordering
        func sortItems(_ items: [any TopListItemProtocol]) -> [any TopListItemProtocol] {
            items.sorted(using: [
                KeyPathComparator(\.metrics[metric], order: .reverse),
                KeyPathComparator(\.displayName, comparator: .localizedStandard),
                KeyPathComparator(\.id.id)
            ])
        }

        switch item {
        case .postsAndPages:
            switch metric {
            case .views:
                let data = try await getData(StatsTopPostsTimeIntervalData.self, parameters: ["skip_archives": "1"])
                let dateFormatter = makeHourlyDateFormatter()
                let items = data.topPosts.map {
                    TopListItem.Post($0, dateFormatter: dateFormatter)
                }
                return TopListResponse(items: sortItems(items))
            default:
                throw StatsServiceError.unavailable
            }

        case .referrers:
            let data = try await getData(StatsTopReferrersTimeIntervalData.self)
            let items = data.referrers.map(TopListItem.Referrer.init)
            return TopListResponse(items: sortItems(items))

        case .locations:
            switch options.locationLevel {
            case .countries:
                let data = try await getData(StatsTopCountryTimeIntervalData.self)
                let items = data.countries.map(TopListItem.Location.init)
                return TopListResponse(items: sortItems(items))
            case .regions:
                let data = try await getData(StatsTopRegionTimeIntervalData.self)
                let items = data.regions.map(TopListItem.Location.init)
                return TopListResponse(items: sortItems(items))
            case .cities:
                let data = try await getData(StatsTopCityTimeIntervalData.self)
                let items = data.cities.map(TopListItem.Location.init)
                return TopListResponse(items: sortItems(items))
            }

        case .devices:
            let breakdown: WordPressKit.StatsServiceRemoteV2.DeviceBreakdown
            let deviceBreakdown = options.deviceBreakdown
            switch deviceBreakdown {
            case .screensize: breakdown = .screensize
            case .platform: breakdown = .platform
            case .browser: breakdown = .browser
            }

            let convertedInterval = convertDateIntervalSiteToLocal(interval)
            let data = try await service.getDeviceStats(breakdown: breakdown, startDate: convertedInterval.start, endDate: convertedInterval.end)

            // TEMPORARY WORKAROUND (CMM-1168):
            // The screensize breakdown returns percentages (e.g., 73.8 for 73.8%), but SiteMetricsSet
            // only supports Int values. We multiply by 100 to convert percentages to integers (73.8 → 7380)
            // while preserving precision. This allows us to display the data correctly until proper
            // percentage metric support is implemented.
            let items = data.items.map { item in
                let value: Int
                if deviceBreakdown == .screensize {
                    // Convert percentage to integer by multiplying by 100
                    value = Int(item.value * 100)
                } else {
                    // Platform and browser breakdowns return counts, not percentages
                    value = Int(item.value)
                }
                return TopListItem.Device(
                    name: item.name,
                    breakdown: deviceBreakdown,
                    metrics: SiteMetricsSet(views: value)
                )
            }
            return TopListResponse(items: sortItems(items))

        case .authors:
            let data = try await getData(StatsTopAuthorsTimeIntervalData.self)
            let dateFormatter = makeHourlyDateFormatter()
            let items = data.topAuthors.map {
                TopListItem.Author($0, dateFormatter: dateFormatter)
            }
            return TopListResponse(items: sortItems(items))

        case .externalLinks:
            switch metric {
            case .views:
                let data = try await getData(StatsTopClicksTimeIntervalData.self)
                let items = data.clicks.map(TopListItem.ExternalLink.init)
                return TopListResponse(items: sortItems(items))
            default:
                throw StatsServiceError.unavailable
            }

        case .fileDownloads:
            switch metric {
            case .downloads:
                let data = try await getData(StatsFileDownloadsTimeIntervalData.self)
                let items = data.fileDownloads.map(TopListItem.FileDownload.init)
                return TopListResponse(items: sortItems(items))
            default:
                throw StatsServiceError.unavailable
            }

        case .searchTerms:
            switch metric {
            case .views:
                let data = try await getData(StatsSearchTermTimeIntervalData.self)
                let items = data.searchTerms.map(TopListItem.SearchTerm.init)
                return TopListResponse(items: sortItems(items))
            default:
                throw StatsServiceError.unavailable
            }

        case .videos:
            switch metric {
            case .views:
                let data = try await getData(StatsTopVideosTimeIntervalData.self)
                let items = data.videos.map(TopListItem.Video.init)
                return TopListResponse(items: sortItems(items))
            default:
                throw StatsServiceError.unavailable
            }

        case .archive:
            switch metric {
            case .views:
                let data = try await getData(StatsArchiveTimeIntervalData.self)
                let sections = data.summary.compactMap { (sectionName, items) -> TopListItem.ArchiveSection? in
                    guard !items.isEmpty else { return nil }
                    return TopListItem.ArchiveSection(sectionName: sectionName, items: items)
                }
                // Sort sections by total views
                let sortedSections = sections.sorted { ($0.metrics.views ?? 0) > ($1.metrics.views ?? 0) }
                return TopListResponse(items: sortedSections)
            default:
                throw StatsServiceError.unavailable
            }

        case .utm:
            switch metric {
            case .views:
                let convertedInterval = convertDateIntervalSiteToLocal(interval)
                let utmParam = WordPressKit.StatsServiceRemoteV2.UTMParam(options.utmParamGrouping)
                let data = try await service.getUTMStats(
                    utmParam: utmParam,
                    startDate: convertedInterval.start,
                    endDate: convertedInterval.end,
                    maxResults: limit ?? 0
                )
                let dateFormatter = makeHourlyDateFormatter()
                let items = data.utmMetrics.map {
                    TopListItem.UTMMetric($0, dateFormatter: dateFormatter)
                }
                return TopListResponse(items: sortItems(items))
            default:
                throw StatsServiceError.unavailable
            }
        }
    }

    func getRealtimeTopListData(_ item: TopListItemType) async throws -> TopListResponse {
        try await mocks.getRealtimeTopListData(item)
    }

    func getPostDetails(for postID: Int) async throws -> StatsPostDetails {
        try await service.getDetails(forPostID: postID)
    }

    func getPostLikes(for postID: Int, count: Int) async throws -> PostLikesData {
        // Create PostServiceRemoteREST instance
        let postService = PostServiceRemoteREST(
            wordPressComRestApi: api,
            siteID: NSNumber(value: siteID)
        )

        // Fetch likes using the REST API
        let result = try await withCheckedThrowingContinuation { continuation in
            postService.getLikesForPostID(
                NSNumber(value: postID),
                count: NSNumber(value: count),
                before: nil,
                excludeUserIDs: nil,
                success: { users, found in
                    let likeUsers = users.map { remoteLike in
                        wpAssert(remoteLike.userID != nil, "user id must not be nil")

                        return PostLikesData.PostLikeUser(
                            id: remoteLike.userID?.intValue ?? 0,
                            name: remoteLike.displayName ?? remoteLike.username ?? "",
                            avatarURL: remoteLike.avatarURL.flatMap(URL.init)
                        )
                    }
                    let postLikes = PostLikesData(users: likeUsers, totalCount: found.intValue)
                    continuation.resume(returning: postLikes)
                },
                failure: { error in
                    continuation.resume(throwing: error ?? StatsServiceError.unknown)
                }
            )
        }

        return result
    }

    func getEmailOpens(for postID: Int) async throws -> StatsEmailOpensData {
        try await service.getEmailOpens(for: postID)
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws {
        try await service.toggleSpamState(for: referrerDomain, currentValue: currentValue)
    }

    // MARK: - Dates

    /// Convert from the site timezone (used in JetpackState) to the local
    /// timezone (expected by WordPressKit) while preserving the date components.
    ///
    /// For .hour unit, WPKit will send "2025-01-01 – 2025-01-07" (inclusive).
    /// For other unit, it will send "2025-01-01 00:00:00 – 2025-01-07 23:59:59".
    private func convertDateIntervalSiteToLocal(_ dateInterval: DateInterval) -> DateInterval {
        let start = convertDateSiteToLocal(dateInterval.start)
        let end = convertDateSiteToLocal(dateInterval.end.addingTimeInterval(-1))
        return DateInterval(start: start, end: end)
    }

    /// Checks if the date interval contains the current date in the site's timezone
    private func intervalContainsCurrentDate(_ interval: DateInterval) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = siteTimeZone
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return false
        }
        return interval.end >= startOfToday && interval.start < endOfToday
    }

    /// Checks if the given date is today in the site's timezone
    private func dateIsToday(_ date: Date) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = siteTimeZone
        return calendar.isDateInToday(date)
    }

    /// Convert from the site timezone (used in JetpackState) to the local
    /// timezone (expected by WordPressKit) while preserving the date components.
    private func convertDateSiteToLocal(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: siteTimeZone, from: date)
        components.timeZone = nil
        components.nanosecond = nil
        guard let output = calendar.date(from: components) else {
            wpAssertionFailure("failed to convert date to local time zone", userInfo: ["date": date])
            return date
        }
        return output
    }

    // MARK: - Mapping (WordPressKit -> JetpackStats)

    private func makeHourlyDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = siteTimeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }

    /// Converts a date from local timezone to site timezone while preserving date components.
    /// - Parameters:
    ///   - date: The date to convert
    ///   - calendar: The calendar to use for conversion (should have siteTimeZone set)
    /// - Returns: The converted date in site timezone
    private func convertDateToSiteTimezone(_ date: Date, using calendar: Calendar) -> Date {
        var components = calendar.dateComponents(in: TimeZone.current, from: date)
        components.timeZone = siteTimeZone
        guard let output = calendar.date(from: components) else {
            wpAssertionFailure("failed to convert date to site time zone", userInfo: ["date": date])
            return date
        }
        return output
    }

    private func mapSiteMetricsResponse(_ response: WordPressKit.StatsSiteMetricsResponse) -> SiteMetricsResponse {
        var calendar = Calendar.current
        calendar.timeZone = siteTimeZone

        let now = Date.now

        func makeDataPoint(from data: WordPressKit.StatsSiteMetricsResponse.PeriodData, metric: WordPressKit.StatsSiteMetricsResponse.Metric) -> DataPoint? {
            guard let value = data[metric] else {
                return nil
            }
            guard data.date <= now else {
                // Filter out future dates (the presentation layer doesn't exect them)
                return nil
            }
            let date = convertDateToSiteTimezone(data.date, using: calendar)
            return DataPoint(date: date, value: value)
        }

        var total = SiteMetricsSet()
        var metrics: [SiteMetric: [DataPoint]] = [:]
        for metric in supportedMetrics {
            if let mappedMetric = WordPressKit.StatsSiteMetricsResponse.Metric(metric) {
                let dataPoints = response.data.compactMap {
                    makeDataPoint(from: $0, metric: mappedMetric)
                }
                metrics[metric] = dataPoints
                total[metric] = DataPoint.getTotalValue(for: dataPoints, metric: metric)
            }
        }
        return SiteMetricsResponse(total: total, metrics: metrics)
    }
}

enum StatsServiceError: LocalizedError {
    case unknown
    case unavailable
    case invalidServiceType

    var errorDescription: String? {
        Strings.Errors.generic
    }
}

// MARK: - Cache

private struct SiteStatsCacheKey: Hashable {
    let interval: DateInterval
    let granularity: DateRangeGranularity
}

private struct WordAdsStatsCacheKey: Hashable {
    let date: Date
    let granularity: DateRangeGranularity
}

private struct CachedEntity<T> {
    let data: T
    let timestamp: Date
    let ttl: TimeInterval?

    var isExpired: Bool {
        guard let ttl else {
            return false // No TTL means it never expires
        }
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

private struct TopListCacheKey: Hashable {
    let item: TopListItemType
    let metric: SiteMetric
    let options: TopListItemOptions
    let interval: DateInterval
    let granularity: DateRangeGranularity
    let limit: Int?
}
