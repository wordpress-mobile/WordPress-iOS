import Foundation
import WordPressKit

protocol StatsServiceProtocol: AnyObject, Sendable {
    var supportedMetrics: [SiteMetric] { get }
    var supportedItems: [TopListItemType] { get }

    func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric]

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsData
    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity) async throws -> TopListData
    func getRealtimeTopListData(_ item: TopListItemType) async throws -> TopListData
    func getPostDetails(for postID: Int) async throws -> StatsPostDetails
}
