import Foundation
@preconcurrency import WordPressKit

protocol StatsServiceProtocol: AnyObject, Sendable, PostThumbnailService {
    var supportedMetrics: [SiteMetric] { get }
    var supportedItems: [TopListItemType] { get }

    func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric]

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse
    func getWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse
    func getWordAdsEarnings() async throws -> WordPressKit.StatsWordAdsEarningsResponse
    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, options: TopListItemOptions) async throws -> TopListResponse
    func getPostDetails(for postID: Int) async throws -> StatsPostDetails
    func getPostLikes(for postID: Int, count: Int) async throws -> PostLikesData
    func getEmailOpens(for postID: Int) async throws -> StatsEmailOpensData
    func invalidateTopListData(for item: TopListItemType) async
    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws
}

/// Resolves the featured images the Posts & Pages list draws.
///
/// Kept apart from the rest of ``StatsServiceProtocol`` because a featured image isn't
/// stats data – it comes from the site's own posts endpoint – and because it's the whole
/// of what ``PostThumbnailStore`` needs.
protocol PostThumbnailService: Sendable {
    /// Returns the featured image of each of the given posts that has one.
    ///
    /// Posts without a featured image are simply missing from the result, so the caller
    /// can tell "no image" apart from "not asked for yet".
    ///
    /// - warning: One call is one request, however many IDs it carries, so ask in batches.
    func getFeaturedImageURLs(forPostIDs postIDs: [Int]) async throws -> [Int: URL]
}
