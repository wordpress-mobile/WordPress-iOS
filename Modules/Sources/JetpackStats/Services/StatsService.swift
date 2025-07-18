import Foundation
@preconcurrency import WordPressKit

final class StatsService: StatsServiceProtocol {
    private let siteID: Int
    private let api: WordPressComRestApi
    private let remoteService: StatsServiceRemoteV2

    init(siteID: Int, api: WordPressComRestApi, siteTimezone: TimeZone) {
        self.siteID = siteID
        self.api = api
        self.remoteService = StatsServiceRemoteV2(
            wordPressComRestApi: api,
            siteID: siteID,
            siteTimezone: siteTimezone
        )
    }

    /// - warning: The dates in StatsServiceRemoteV2 are represented in TimeZone.local
    /// despite it accepting `siteTimezone` as a parameter. The parameter was
    /// added later and is only used in a small subset of methods, which means
    /// thay we have to convert the dates from the local time zone to the
    /// site reporting time zone (as expected by the app).
    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteStatsData {
        let period = mapGranularityToPeriod(granularity)
        let endDate = interval.end
        let summaryData: StatsSummaryTimeIntervalData = try await remoteService.getData(for: period, endingOn: endDate)
        return mapToSiteStatsData(summaryData, interval: interval, granularity: granularity)
    }

    func getTopListData(_ dataType: TopListItemType, range: DateInterval, granularity: DateRangeGranularity) async throws -> TopListData {
        let period = mapGranularityToPeriod(granularity)
        let endDate = range.end

        switch dataType {
        case .postsAndPages:
            throw StatsServiceError.notImplemented("Not implemented")

        case .pages:
            throw StatsServiceError.notImplemented("Not implemented")

        case .posts:
            let data: StatsTopPostsTimeIntervalData = try await remoteService.getData(for: period, endingOn: endDate)
            return mapPostsToTopListData(data)

        case .referrers:
            let data: StatsTopReferrersTimeIntervalData = try await remoteService.getData(for: period, endingOn: endDate)
            return mapReferrersToTopListData(data)

        case .locations:
            let data: StatsTopCountryTimeIntervalData = try await remoteService.getData(for: period, endingOn: endDate)
            return mapCountriesToTopListData(data)

        case .authors:
            let data: StatsTopAuthorsTimeIntervalData = try await remoteService.getData(for: period, endingOn: endDate)
            return mapAuthorsToTopListData(data)

        case .externalLinks:
            throw StatsServiceError.notImplemented("Not implemented")
        }
    }

    func getRealtimeTopListData(_ dataType: TopListItemType) async throws -> TopListData {
        // NOTE: Realtime data requires different endpoints that are not yet available in WordPressKit
        throw StatsServiceError.notImplemented("Not implemented")
    }

    // MARK: - Private Helpers

    private func mapGranularityToPeriod(_ granularity: DateRangeGranularity) -> StatsPeriodUnit {
        switch granularity {
        case .hour:
#warning("Not implemented")
            return .day
        case .day:
            return .day
        case .month:
            return .month
        case .year:
            return .year
        }
    }

    private func mapToSiteStatsData(_ summaryData: StatsSummaryTimeIntervalData, interval: DateInterval, granularity: DateRangeGranularity) -> SiteStatsData {
        var metrics: [SiteMetric: [DataPoint]] = [:]

        // Map views
        metrics[.views] = summaryData.summaryData.map { summary in
            DataPoint(date: summary.periodStartDate, value: summary.viewsCount)
        }

        // Map visitors
        metrics[.visitors] = summaryData.summaryData.map { summary in
            DataPoint(date: summary.periodStartDate, value: summary.visitorsCount)
        }

        // Map likes
        metrics[.likes] = summaryData.summaryData.map { summary in
            DataPoint(date: summary.periodStartDate, value: summary.likesCount)
        }

        // Map comments
        metrics[.comments] = summaryData.summaryData.map { summary in
            DataPoint(date: summary.periodStartDate, value: summary.commentsCount)
        }

        // NOTE: Time on site and bounce rate not available in StatsSummaryData

        return SiteStatsData(metrics: metrics)
    }

    private func mapPostsToTopListData(_ data: StatsTopPostsTimeIntervalData) -> TopListData {
        let items = data.topPosts.map { post in
            TopListData.Post(
                title: post.title,
                postId: String(post.postID),
                pageId: nil,
                type: post.kind.description,
                author: nil,
                metrics: TopListData.Metrics(
                    views: post.viewsCount
                )
            )
        }

        return TopListData(items: items)
    }

    private func mapReferrersToTopListData(_ data: StatsTopReferrersTimeIntervalData) -> TopListData {
        let items = data.referrers.map { referrer in
            TopListData.Referrer(
                name: referrer.title,
                domain: referrer.url?.host,
                metrics: TopListData.Metrics(
                    views: referrer.viewsCount
                )
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
                metrics: TopListData.Metrics(
                    views: country.viewsCount
                )
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
                metrics: TopListData.Metrics(
                    views: author.viewsCount
                ),
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
}

// MARK: - Custom Errors

enum StatsServiceError: LocalizedError {
    case noData
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data received from the server"
        case .notImplemented(let feature):
            return "\(feature)"
        }
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

// MARK: - StatsServiceRemoteV2 Async Extensions

private extension StatsServiceRemoteV2 {
    func getData<TimeStatsType: StatsTimeIntervalData>(
        interval: DateInterval,
        unit: StatsPeriodUnit,
        limit: Int = 10
    ) async throws -> TimeStatsType where TimeStatsType: Sendable  {
        try await withCheckedThrowingContinuation { continuation in
            // `period` is ignored if you pass `startDate`, but it's a required parameter
            getData(for: unit, unit: unit, startDate: interval.start, endingOn: interval.end, limit: limit) { (data: TimeStatsType?, error: Error?) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: StatsServiceError.noData)
                }
            }
        }
    }

    func getInsight<InsightType: StatsInsightData,>(limit: Int = 10) async throws -> InsightType where InsightType: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            getInsight(limit: limit) { (insight: InsightType?, error: Error?) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let insight = insight {
                    continuation.resume(returning: insight)
                } else {
                    continuation.resume(throwing: StatsServiceError.noData)
                }
            }
        }
    }

    func getDetails(forPostID postID: Int) async throws -> StatsPostDetails {
        try await withCheckedThrowingContinuation { continuation in
            getDetails(forPostID: postID) { (details: StatsPostDetails?, error: Error?) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let details = details {
                    continuation.resume(returning: details)
                } else {
                    continuation.resume(throwing: StatsServiceError.noData)
                }
            }
        }
    }

    func getInsight(limit: Int = 10) async throws -> StatsLastPostInsight {
        try await withCheckedThrowingContinuation { continuation in
            getInsight(limit: limit) { (insight: StatsLastPostInsight?, error: Error?) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let insight = insight {
                    continuation.resume(returning: insight)
                } else {
                    continuation.resume(throwing: StatsServiceError.noData)
                }
            }
        }
    }

    func getData(
        for period: StatsPeriodUnit,
        endingOn: Date,
        limit: Int = 10
    ) async throws -> StatsPublishedPostsTimeIntervalData {
        try await withCheckedThrowingContinuation { continuation in
            getData(for: period, endingOn: endingOn, limit: limit) { (data: StatsPublishedPostsTimeIntervalData?, error: Error?) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: StatsServiceError.noData)
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

    func getData(
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
