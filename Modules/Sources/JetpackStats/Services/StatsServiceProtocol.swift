import Foundation

protocol StatsServiceProtocol: AnyObject, Sendable {
    var supportedMetrics: [SiteMetric] { get }
    var supportedItems: [TopListItemType] { get }

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsData
    func getTopListData(_ dataType: TopListItemType, interval: DateInterval, granularity: DateRangeGranularity) async throws -> TopListData
    func getRealtimeTopListData(_ dataType: TopListItemType) async throws -> TopListData
}
