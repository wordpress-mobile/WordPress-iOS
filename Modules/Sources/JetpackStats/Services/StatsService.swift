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
    private var topListCache: [TopListCacheKey: CachedEntity<TopListResponse>] = [:]
    private let currentPeriodTTL: TimeInterval = 30 // 30 seconds for current period

    let supportedMetrics: [SiteMetric] = [
        .views, .visitors, .likes, .comments, .posts
    ]

    let supportedItems: [TopListItemType] = [
        .postsAndPages, .authors, .referrers, .locations,
        .externalLinks, .fileDownloads, .searchTerms, .videos, .archive
    ]

    nonisolated func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        switch item {
        case .postsAndPages: [.views]
        case .archive: [.views]
        case .referrers: [.views]
        case .locations: [.views]
        case .authors: [.views]
        case .externalLinks: [.views]
        case .fileDownloads: [.downloads]
        case .searchTerms: [.views]
        case .videos: [.views]
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

    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, locationLevel: LocationLevel?) async throws -> TopListResponse {
        // Check cache first
        let cacheKey = TopListCacheKey(item: item, metric: metric, locationLevel: locationLevel, interval: interval, granularity: granularity, limit: limit)
        if let cached = topListCache[cacheKey], !cached.isExpired {
            return cached.data
        }

        // Fetch fresh data
        do {
            let data = try await _getTopListData(item, metric: metric, interval: interval, granularity: granularity, limit: limit, locationLevel: locationLevel)

            // Cache the result
            // Historical data never expires (ttl = nil), current period data expires after 30 seconds
            let ttl = intervalContainsCurrentDate(interval) ? currentPeriodTTL : nil
            topListCache[cacheKey] = CachedEntity(data: data, timestamp: Date(), ttl: ttl)

            return data
        } catch {
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

    private func _getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, locationLevel: LocationLevel?) async throws -> TopListResponse {

        func getData<T: WordPressKit.StatsTimeIntervalData>(
            _ type: T.Type,
            parameters: [String: String]? = nil
        ) async throws -> T where T: Sendable {
            /// The `summarize: true` feature works correctly only with the `.day` granularity.
            let interval = convertDateIntervalSiteToLocal(interval)
            return try await service.getData(interval: interval, unit: .day, summarize: true, limit: limit ?? 0, parameters: parameters)
        }

        // Helper function to sort items by metric value (descending) and then by itemID for stable ordering
        func sortItems(_ items: [any TopListItemProtocol]) -> [any TopListItemProtocol] {
            items.sorted { lhs, rhs in
                let lhsValue = lhs.metrics[metric] ?? 0
                let rhsValue = rhs.metrics[metric] ?? 0

                // First sort by metric value (descending)
                if lhsValue != rhsValue {
                    return lhsValue > rhsValue
                }

                // If values are equal, sort by itemID for stable ordering
                return lhs.id.id < rhs.id.id
            }
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
            let level = locationLevel ?? .cities
            switch level {
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

    private func mapSiteMetricsResponse(_ response: WordPressKit.StatsSiteMetricsResponse) -> SiteMetricsResponse {
        var calendar = Calendar.current
        calendar.timeZone = siteTimeZone

        let now = Date.now

        func makeDataPoint(from data: WordPressKit.StatsSiteMetricsResponse.PeriodData, metric: WordPressKit.StatsSiteMetricsResponse.Metric) -> DataPoint? {
            guard let value = data[metric] else {
                return nil
            }
            let date: Date = {
                var components = calendar.dateComponents(in: TimeZone.current, from: data.date)
                components.timeZone = siteTimeZone
                guard let output = calendar.date(from: components) else {
                    wpAssertionFailure("failed to convert date to site time zone", userInfo: ["date": data.date])
                    return data.date
                }
                return output
            }()
            guard date <= now else {
                return nil // Filter out future dates
            }
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

    var errorDescription: String? {
        Strings.Errors.generic
    }
}

// MARK: - Cache

private struct SiteStatsCacheKey: Hashable {
    let interval: DateInterval
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
    let locationLevel: LocationLevel?
    let interval: DateInterval
    let granularity: DateRangeGranularity
    let limit: Int?
}

// MARK: - Mapping

private extension WordPressKit.StatsPeriodUnit {
    init(_ granularity: DateRangeGranularity) {
        switch granularity {
        case .hour: self = .hour
        case .day: self = .day
        case .week: self = .week
        case .month: self = .month
        case .year: self = .year
        }
    }
}

private extension WordPressKit.StatsSiteMetricsResponse.Metric {
    init?(_ metric: SiteMetric) {
        switch metric {
        case .views: self = .views
        case .visitors: self = .visitors
        case .likes: self = .likes
        case .comments: self = .comments
        case .posts: self = .posts
        case .timeOnSite, .bounceRate, .downloads: return nil
        }
    }
}

// MARK: - StatsServiceRemoteV2 Async Extensions

private extension WordPressKit.StatsServiceRemoteV2 {
    func getData<TimeStatsType: WordPressKit.StatsTimeIntervalData>(
        interval: DateInterval,
        unit: WordPressKit.StatsPeriodUnit,
        summarize: Bool? = nil,
        limit: Int,
        parameters: [String: String]? = nil
    ) async throws -> TimeStatsType where TimeStatsType: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            // `period` is ignored if you pass `startDate`, but it's a required parameter
            getData(for: unit, unit: unit, startDate: interval.start, endingOn: interval.end, limit: limit, summarize: summarize, parameters: parameters) { (data: TimeStatsType?, error: Error?) in
               if let data {
                    continuation.resume(returning: data)
               } else {
                    continuation.resume(throwing: error ?? StatsServiceError.unknown)
                }
            }
        }
    }

    func getInsight<InsightType: StatsInsightData>(limit: Int = 10) async throws -> InsightType where InsightType: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            getInsight(limit: limit) { (insight: InsightType?, error: Error?) in
                if let insight {
                    continuation.resume(returning: insight)
                } else {
                    continuation.resume(throwing: error ?? StatsServiceError.unknown)
                }
            }
        }
    }

    func getDetails(forPostID postID: Int) async throws -> StatsPostDetails {
        try await withCheckedThrowingContinuation { continuation in
            getDetails(forPostID: postID) { (details: StatsPostDetails?, error: Error?) in
                if let details {
                    continuation.resume(returning: details)
                } else {
                    continuation.resume(throwing: error ?? StatsServiceError.unknown)
                }
            }
        }
    }

    func getInsight(limit: Int = 10) async throws -> StatsLastPostInsight {
        try await withCheckedThrowingContinuation { continuation in
            getInsight(limit: limit) { (insight: StatsLastPostInsight?, error: Error?) in
                if let insight {
                    continuation.resume(returning: insight)
                } else {
                    continuation.resume(throwing: error ?? StatsServiceError.unknown)
                }
            }
        }
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            toggleSpamState(for: referrerDomain, currentValue: currentValue, success: {
                continuation.resume()
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    func getEmailSummaryData(
        quantity: Int,
        sortField: StatsEmailsSummaryData.SortField = .opens,
        sortOrder: StatsEmailsSummaryData.SortOrder = .descending
    ) async throws -> StatsEmailsSummaryData {
        try await withCheckedThrowingContinuation { continuation in
            getData(quantity: quantity, sortField: sortField, sortOrder: sortOrder) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getEmailOpens(for postID: Int) async throws -> StatsEmailOpensData {
        try await withCheckedThrowingContinuation { continuation in
            getEmailOpens(for: postID) { (data, error) in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? StatsServiceError.unknown)
                }
            }
        }
    }
}
