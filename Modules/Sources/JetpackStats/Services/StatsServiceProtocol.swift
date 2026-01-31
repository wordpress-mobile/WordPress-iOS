import Foundation
@preconcurrency import WordPressKit

protocol StatsServiceProtocol: AnyObject, Sendable {
    var supportedMetrics: [SiteMetric] { get }
    var supportedItems: [TopListItemType] { get }

    func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric]

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse
    func getWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse
    func getWordAdsEarnings() async throws -> WordPressKit.StatsWordAdsEarningsResponse
    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, options: TopListItemOptions) async throws -> TopListResponse
    func getRealtimeTopListData(_ item: TopListItemType) async throws -> TopListResponse
    func getPostDetails(for postID: Int) async throws -> StatsPostDetails
    func getPostLikes(for postID: Int, count: Int) async throws -> PostLikesData
    func getEmailOpens(for postID: Int) async throws -> StatsEmailOpensData
    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws
}
