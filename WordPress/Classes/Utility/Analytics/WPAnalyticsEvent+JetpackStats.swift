import Foundation
import JetpackStats

extension StatsEvent {
    /// Maps JetpackStats events to WordPress analytics events
    var wpEvent: WPAnalyticsEvent {
        switch self {
        case .statsMainScreenShown: .jetpackStatsMainScreenShown
        case .trafficTabShown: .jetpackStatsTrafficTabShown
        case .realtimeTabShown: .jetpackStatsRealtimeTabShown
        case .subscribersTabShown: .jetpackStatsSubscribersTabShown
        case .postDetailsScreenShown: .jetpackStatsPostDetailsScreenShown
        case .authorStatsScreenShown: .jetpackStatsAuthorStatsScreenShown
        case .archiveStatsScreenShown: .jetpackStatsArchiveStatsScreenShown
        case .externalLinkStatsScreenShown: .jetpackStatsExternalLinkStatsScreenShown
        case .referrerStatsScreenShown: .jetpackStatsReferrerStatsScreenShown
        case .dateRangePresetSelected: .jetpackStatsDateRangePresetSelected
        case .customDateRangeSelected: .jetpackStatsCustomDateRangeSelected
        case .cardShown: .jetpackStatsCardShown
        case .cardAdded: .jetpackStatsCardAdded
        case .cardRemoved: .jetpackStatsCardRemoved
        case .chartTypeChanged: .jetpackStatsChartTypeChanged
        case .chartMetricSelected: .jetpackStatsChartMetricSelected
        case .chartBarSelected: .jetpackStatsChartBarSelected
        case .todayCardTapped: .jetpackStatsTodayCardTapped
        case .topListItemTapped: .jetpackStatsTopListItemTapped
        case .statsTabSelected: .jetpackStatsTabSelected
        case .errorEncountered: .jetpackStatsErrorEncountered
        }
    }
}

extension WPAnalyticsEvent {
    static let isNewStatsKey = "new_stats"
}
