@preconcurrency import WordPressKit

extension WordPressKit.StatsServiceRemoteV2 {
    /// A modern variant of `WordPressKit.StatsTimeIntervalData` API that supports
    /// custom date periods.
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

    /// A legacy variant of `WordPressKit.StatsTimeIntervalData` API that supports
    /// only support setting the target date and the quantity of periods to return.
    func getData<TimeStatsType: WordPressKit.StatsTimeIntervalData>(
        date: Date,
        unit: WordPressKit.StatsPeriodUnit,
        quantity: Int
    ) async throws -> TimeStatsType where TimeStatsType: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            // Call getData with date and quantity (quantity is passed as limit, which becomes maxCount in queryProperties)
            getData(for: unit, endingOn: date, limit: quantity) { (data: TimeStatsType?, error: Error?) in
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

extension WordPressKit.StatsPeriodUnit {
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

extension WordPressKit.StatsSiteMetricsResponse.Metric {
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

extension WordPressKit.StatsServiceRemoteV2.UTMParam {
    init(_ grouping: UTMParamGrouping) {
        switch grouping {
        case .sourceMedium: self = .sourceMedium
        case .campaignSourceMedium: self = .campaignSourceMedium
        case .source: self = .source
        case .medium: self = .medium
        case .campaign: self = .campaign
        }
    }
}
