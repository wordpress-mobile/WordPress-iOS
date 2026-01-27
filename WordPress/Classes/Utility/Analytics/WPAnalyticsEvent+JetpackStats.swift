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
        case .adsTabShown: .jetpackStatsAdsTabShown
        case .postDetailsScreenShown: .jetpackStatsPostDetailsScreenShown
        case .authorStatsScreenShown: .jetpackStatsAuthorStatsScreenShown
        case .archiveStatsScreenShown: .jetpackStatsArchiveStatsScreenShown
        case .externalLinkStatsScreenShown: .jetpackStatsExternalLinkStatsScreenShown
        case .referrerStatsScreenShown: .jetpackStatsReferrerStatsScreenShown
        case .dateRangePresetSelected: .jetpackStatsDateRangePresetSelected
        case .customDateRangeSelected: .jetpackStatsCustomDateRangeSelected
        case .dateNavigationButtonTapped: .jetpackStatsDateNavigationButtonTapped
        case .comparisonPeriodChanged: .jetpackStatsComparisonPeriodChanged
        case .cardShown: .jetpackStatsCardShown
        case .cardAdded: .jetpackStatsCardAdded
        case .cardRemoved: .jetpackStatsCardRemoved
        case .cardMoved: .jetpackStatsCardMoved
        case .chartTypeChanged: .jetpackStatsChartTypeChanged
        case .chartMetricSelected: .jetpackStatsChartMetricSelected
        case .chartBarSelected: .jetpackStatsChartBarSelected
        case .chartGranularityChanged: .jetpackStatsChartGranularityChanged
        case .rawDataViewed: .jetpackStatsRawDataViewed
        case .todayCardTapped: .jetpackStatsTodayCardTapped
        case .topListItemTapped: .jetpackStatsTopListItemTapped
        case .locationLevelChanged: .jetpackStatsLocationLevelChanged
        case .statsTabSelected: .jetpackStatsTabSelected
        case .errorEncountered: .jetpackStatsErrorEncountered
        }
    }
}

extension WPAnalyticsEvent {
    static let isNewStatsKey = "new_stats"
}
