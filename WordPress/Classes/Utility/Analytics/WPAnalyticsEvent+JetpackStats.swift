import Foundation
import JetpackStats

extension StatsEvent {
    /// Maps JetpackStats events to WordPress analytics events
    var wpEvent: WPAnalyticsEvent {
        switch self {
        // Screen View Events
        case .statsMainScreenShown:
            return .jetpackStatsMainScreenShown
        case .trafficTabShown:
            return .jetpackStatsTrafficTabShown
        case .realtimeTabShown:
            return .jetpackStatsRealtimeTabShown
        case .subscribersTabShown:
            return .jetpackStatsSubscribersTabShown
        case .postDetailsScreenShown:
            return .jetpackStatsPostDetailsScreenShown
        case .authorStatsScreenShown:
            return .jetpackStatsAuthorStatsScreenShown
        case .archiveStatsScreenShown:
            return .jetpackStatsArchiveStatsScreenShown
        case .externalLinkStatsScreenShown:
            return .jetpackStatsExternalLinkStatsScreenShown
        case .referrerStatsScreenShown:
            return .jetpackStatsReferrerStatsScreenShown

        // Date Range Events
        case .dateRangePresetSelected:
            return .jetpackStatsDateRangePresetSelected
        case .customDateRangeSelected:
            return .jetpackStatsCustomDateRangeSelected

        // Card Events
        case .cardShown:
            return .jetpackStatsCardShown
        case .cardAdded:
            return .jetpackStatsCardAdded
        case .cardRemoved:
            return .jetpackStatsCardRemoved

        // Chart Events
        case .chartTypeChanged:
            return .jetpackStatsChartTypeChanged
        case .chartMetricSelected:
            return .jetpackStatsChartMetricSelected

        // List Events
        case .topListItemTapped:
            return .jetpackStatsTopListItemTapped

        // Navigation Events
        case .statsTabSelected:
            return .jetpackStatsTabSelected

        // Error Events
        case .errorEncountered:
            return .jetpackStatsErrorEncountered
        }
    }
}

extension WPAnalyticsEvent {
    static let isNewStatsKey = "new_stats"
}
