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
    private var siteStatsCache: [SiteStatsCacheKey: CachedSiteStats] = [:]
    private let currentPeriodTTL: TimeInterval = 30 // 30 seconds for current period

    let supportedMetrics: [SiteMetric] = [
        .views, .visitors, .likes, .comments, .posts
    ]

    let supportedItems: [TopListItemType] = [
        .postsAndPages, .archive, .referrers, .locations, .authors, .externalLinks,
        .fileDownloads, .searchTerms, .videos
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

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsData {
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

        siteStatsCache[cacheKey] = CachedSiteStats(data: data, timestamp: Date(), ttl: ttl)

        return data
    }

    private func fetchSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsData {
        let interval = convertDateIntervalSiteToLocal(interval)

        if granularity == .hour {
            // Hourly data is available only for "Views", so the service has to
            // make a separate request to fetch the total metrics.
            async let hourlyResponseTask: WordPressKit.StatsSiteMetricsResponse = service.getData(interval: interval, unit: .init(granularity))
            async let dailyResponseTask: WordPressKit.StatsSiteMetricsResponse = service.getData(interval: interval, unit: .init(.day))

            let (hourlyResponse, dailyResponse) = try await (hourlyResponseTask, dailyResponseTask)

            var data = mapSiteMetricsResponse(hourlyResponse)
            data.total = mapSiteMetricsResponse(dailyResponse).total
            return data
        } else {
            let response: WordPressKit.StatsSiteMetricsResponse = try await service.getData(interval: interval, unit: .init(granularity))
            return mapSiteMetricsResponse(response)
        }
    }

    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity) async throws -> TopListData {
        do {
            return try await _getTopListData(item, metric: metric, interval: interval, granularity: granularity)
        } catch {
            // A workaround for an issue where `/stats` return `"summary": null`
            // when there are no recoreded periods (happens when the entire requested
            // period is _before_ the site creation).
            if let error = error as? StatsServiceRemoteV2.ResponseError,
               error == .emptySummary {
                return TopListData(items: [])
            }
            throw error
        }
    }

    private func _getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity) async throws -> TopListData {

        func getData<T: WordPressKit.StatsTimeIntervalData>(
            _ type: T.Type,
            parameters: [String: String]? = nil
        ) async throws -> T where T: Sendable {
            /// The `summarize: true` feature works correctly only with the `.day` granularity.
            let interval = convertDateIntervalSiteToLocal(interval)
            return try await service.getData(interval: interval, unit: .day, summarize: true, parameters: parameters)
        }

        switch item {
        case .postsAndPages:
            switch metric {
            case .views:
                let data = try await getData(StatsTopPostsTimeIntervalData.self, parameters: ["skip_archives": "1"])
                return mapPostsToTopListData(data)
            case .comments:
                fatalError()
            default:
                throw StatsServiceError.unavailable
            }

        case .referrers:
            let data = try await getData(StatsTopReferrersTimeIntervalData.self)
            return mapReferrersToTopListData(data)

        case .locations:
            let data = try await getData(StatsTopCountryTimeIntervalData.self)
            return mapCountriesToTopListData(data)

        case .authors:
            let data = try await getData(StatsTopAuthorsTimeIntervalData.self)
            return mapAuthorsToTopListData(data)

        case .externalLinks:
            switch metric {
            case .views:
                let data = try await getData(StatsTopClicksTimeIntervalData.self)
                return mapClicksToTopListData(data)
            default:
                throw StatsServiceError.unavailable
            }

        case .fileDownloads:
            switch metric {
            case .downloads:
                let data = try await getData(StatsFileDownloadsTimeIntervalData.self)
                return mapFileDownloadsToTopListData(data)
            default:
                throw StatsServiceError.unavailable
            }

        case .searchTerms:
            switch metric {
            case .views:
                let data = try await getData(StatsSearchTermTimeIntervalData.self)
                return mapSearchTermsToTopListData(data)
            default:
                throw StatsServiceError.unavailable
            }

        case .videos:
            switch metric {
            case .views:
                let data = try await getData(StatsTopVideosTimeIntervalData.self)
                return mapVideosToTopListData(data)
            default:
                throw StatsServiceError.unavailable
            }
            
        case .archive:
            switch metric {
            case .views:
                let data = try await getData(StatsArchiveTimeIntervalData.self)
                return mapArchiveToTopListData(data)
            default:
                throw StatsServiceError.unavailable
            }
        }
    }

    func getRealtimeTopListData(_ item: TopListItemType) async throws -> TopListData {
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
                        PostLikesData.PostLikeUser(
                            id: remoteLike.userID.intValue,
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
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)

        return interval.start <= endOfToday && interval.end >= startOfToday
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

    private func mapSiteMetricsResponse(_ response: WordPressKit.StatsSiteMetricsResponse) -> SiteMetricsData {
        var calendar = Calendar.current
        calendar.timeZone = siteTimeZone

        let now = Date.now

        func makeDataPoint(from data: WordPressKit.StatsSiteMetricsResponse.PeriodData, metric: WordPressKit.StatsSiteMetricsResponse.Metric) -> DataPoint? {
            guard let value = data[metric] else {
                return nil
            }
            let date: Date = {
                let components = calendar.dateComponents(in: TimeZone.current, from: data.date)
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
        return SiteMetricsData(total: total, metrics: metrics)
    }

    private func mapPostsToTopListData(_ data: StatsTopPostsTimeIntervalData, filterKind: StatsTopPost.Kind? = nil) -> TopListData {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = siteTimeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let posts = filterKind != nil ? data.topPosts.filter { $0.kind == filterKind } : data.topPosts
        let items = posts.map { post in
            TopListData.Post(
                title: post.title,
                postID: String(post.postID),
                postURL: post.postURL,
                date: post.date.flatMap(dateFormatter.date),
                type: post.kind.description,
                author: nil,
                metrics: SiteMetricsSet(views: post.viewsCount)
            )
        }
        return TopListData(items: items)
    }

    private func mapReferrersToTopListData(_ data: StatsTopReferrersTimeIntervalData) -> TopListData {
        let items = data.referrers.map { referrer in
            TopListData.Referrer(
                name: referrer.title,
                domain: referrer.url?.host,
                metrics: SiteMetricsSet(views: referrer.viewsCount)
            )
        }

        return TopListData(items: items)
    }

    private func mapCountriesToTopListData(_ data: StatsTopCountryTimeIntervalData) -> TopListData {
        let items = data.countries.map { country in
            TopListData.Location(
                country: country.name,
                flag: countryCodeToEmoji(country.code),
                countryCode: country.code,
                metrics: SiteMetricsSet(views: country.viewsCount)
            )
        }

        return TopListData(items: items)
    }

    private func mapAuthorsToTopListData(_ data: StatsTopAuthorsTimeIntervalData) -> TopListData {
        let items = data.topAuthors.map { author in
            TopListData.Author(
                name: author.name,
                userId: author.name, // NOTE: WordPressKit doesn't provide user ID
                role: nil,
                metrics: SiteMetricsSet(views: author.viewsCount),
                avatarURL: author.iconURL
            )
        }

        return TopListData(items: items)
    }

    private func countryCodeToEmoji(_ code: String) -> String? {
        let base: UInt32 = 127397
        var scalarView = String.UnicodeScalarView()
        for i in code.uppercased().unicodeScalars {
            guard let scalar = UnicodeScalar(base + i.value) else { return nil }
            scalarView.append(scalar)
        }
        return String(scalarView)
    }

    private func mapClicksToTopListData(_ data: StatsTopClicksTimeIntervalData) -> TopListData {
        let items = data.clicks.map { click in
            TopListData.ExternalLink(
                url: click.clickedURL?.absoluteString ?? "",
                title: click.title,
                metrics: SiteMetricsSet(
                    views: click.clicksCount
                )
            )
        }
        return TopListData(items: items)
    }

    private func mapFileDownloadsToTopListData(_ data: StatsFileDownloadsTimeIntervalData) -> TopListData {
        let items = data.fileDownloads.map { download in
            TopListData.FileDownload(
                fileName: URL(string: download.file)?.lastPathComponent ?? download.file,
                filePath: download.file,
                metrics: SiteMetricsSet(downloads: download.downloadCount)
            )
        }
        return TopListData(items: items)
    }

    private func mapSearchTermsToTopListData(_ data: StatsSearchTermTimeIntervalData) -> TopListData {
        let items = data.searchTerms.map { searchTerm in
            TopListData.SearchTerm(
                term: searchTerm.term,
                metrics: SiteMetricsSet(
                    views: searchTerm.viewsCount
                )
            )
        }
        return TopListData(items: items)
    }

    private func mapVideosToTopListData(_ data: StatsTopVideosTimeIntervalData) -> TopListData {
        let items = data.videos.map { video in
            TopListData.Video(
                title: video.title,
                postId: String(video.postID),
                videoUrl: video.videoURL,
                metrics: SiteMetricsSet(
                    views: video.playsCount
                )
            )
        }
        return TopListData(items: items)
    }
    
    private func mapArchiveToTopListData(_ data: StatsArchiveTimeIntervalData) -> TopListData {
        // Convert the summary dictionary into archive sections
        let sections = data.summary.compactMap { (sectionName, items) -> TopListData.ArchiveSection? in
            guard !items.isEmpty else { return nil }
            
            // Map archive items
            let archiveItems = items.map { item in
                TopListData.ArchiveItem(
                    href: item.href,
                    value: item.value,
                    metrics: SiteMetricsSet(views: item.views)
                )
            }
            
            // Calculate total views for the section
            let totalViews = items.reduce(0) { $0 + $1.views }
            
            return TopListData.ArchiveSection(
                sectionName: sectionName,
                items: archiveItems,
                metrics: SiteMetricsSet(views: totalViews)
            )
        }
        
        // Sort sections by total views
        let sortedSections = sections.sorted { ($0.metrics.views ?? 0) > ($1.metrics.views ?? 0) }
        
        return TopListData(items: sortedSections)
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

private struct CachedSiteStats {
    let data: SiteMetricsData
    let timestamp: Date
    let ttl: TimeInterval?

    var isExpired: Bool {
        guard let ttl else {
            return false // No TTL means it never expires
        }
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

// MARK: - Mapping

private extension WordPressKit.StatsPeriodUnit {
    init(_ granularity: DateRangeGranularity) {
        switch granularity {
        case .hour: self = .hour
        case .day: self = .day
        case .month: self = .month
        case .year: self = .year
        }
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
        parameters: [String: String]? = nil
    ) async throws -> TimeStatsType where TimeStatsType: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            // `period` is ignored if you pass `startDate`, but it's a required parameter
            getData(for: unit, unit: unit, startDate: interval.start, endingOn: interval.end, limit: 0, summarize: summarize, parameters: parameters) { (data: TimeStatsType?, error: Error?) in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: StatsServiceError.unknown)
                }
            }
        }
    }

    func getInsight<InsightType: StatsInsightData>(limit: Int = 10) async throws -> InsightType where InsightType: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            getInsight(limit: limit) { (insight: InsightType?, error: Error?) in
                if let error {
                    continuation.resume(throwing: error)
                } else if let insight {
                    continuation.resume(returning: insight)
                } else {
                    continuation.resume(throwing: StatsServiceError.unknown)
                }
            }
        }
    }

    func getDetails(forPostID postID: Int) async throws -> StatsPostDetails {
        try await withCheckedThrowingContinuation { continuation in
            getDetails(forPostID: postID) { (details: StatsPostDetails?, error: Error?) in
                if let error {
                    continuation.resume(throwing: error)
                } else if let details {
                    continuation.resume(returning: details)
                } else {
                    continuation.resume(throwing: StatsServiceError.unknown)
                }
            }
        }
    }

    func getInsight(limit: Int = 10) async throws -> StatsLastPostInsight {
        try await withCheckedThrowingContinuation { continuation in
            getInsight(limit: limit) { (insight: StatsLastPostInsight?, error: Error?) in
                if let error {
                    continuation.resume(throwing: error)
                } else if let insight {
                    continuation.resume(returning: insight)
                } else {
                    continuation.resume(throwing: StatsServiceError.unknown)
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
}
