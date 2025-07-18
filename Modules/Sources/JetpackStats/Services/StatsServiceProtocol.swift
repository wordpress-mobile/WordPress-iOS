import Foundation

protocol StatsServiceProtocol: AnyObject, Sendable {
    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteStatsData
    func getTopListData(_ dataType: TopListItemType, range: DateInterval, granularity: DateRangeGranularity) async throws -> TopListData
    func getRealtimeTopListData(_ dataType: TopListItemType) async throws -> TopListData
}
