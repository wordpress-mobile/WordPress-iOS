import Foundation

/// Analytics events for tracking user interactions within the Stats module
///
/// IMPORTANT: Do not include personally identifiable information (PII) in analytics events.
/// This includes but is not limited to:
/// - User IDs, author IDs, or any unique identifiers
/// - Email addresses
/// - URLs that might contain sensitive information
/// - Post IDs or content identifiers
///
/// Instead, track only:
/// - Event types and categories
/// - Navigation sources
/// - UI states and configurations
/// - Aggregated metrics
public enum StatsEvent {
    // MARK: - Screen View Events

    /// Main stats screen shown
    case statsMainScreenShown

    /// Traffic tab shown
    case trafficTabShown

    /// Realtime tab shown
    case realtimeTabShown

    /// Subscribers tab shown
    case subscribersTabShown

    /// Ads tab shown
    case adsTabShown

    /// Post details screen shown
    case postDetailsScreenShown

    /// Author stats screen shown
    case authorStatsScreenShown

    /// Archive stats screen shown
    case archiveStatsScreenShown

    /// External link stats screen shown
    case externalLinkStatsScreenShown

    /// Referrer stats screen shown
    case referrerStatsScreenShown

    /// UTM metric stats screen shown
    case utmMetricStatsScreenShown

    // MARK: - Date Range Events

    /// Date range preset selected
    /// - Parameters:
    ///   - "selected_preset": The preset selected (e.g., "last_7_days", "last_28_days", "last_12_weeks", "last_365_days")
    case dateRangePresetSelected

    /// Custom date range selected
    /// - Parameters:
    ///   - "start_date": Start date in ISO format
    ///   - "end_date": End date in ISO format
    case customDateRangeSelected

    /// Date navigation button tapped (next/previous period)
    /// - Parameters:
    ///   - "direction": Direction of navigation ("next" or "previous")
    ///   - "current_period_type": Type of current period (preset name or "custom")
    case dateNavigationButtonTapped

    /// Comparison period changed
    /// - Parameters:
    ///   - "from_period": Previous comparison period ("previous_period" or "previous_year")
    ///   - "to_period": New comparison period
    case comparisonPeriodChanged

    // MARK: - Card Events

    /// Card shown on screen
    /// - Parameters:
    ///   - "card_type": Type of card (e.g., "chart", "top_list")
    ///   - "configuration": Card configuration details (e.g., metrics, item type)
    case cardShown

    /// Card added to dashboard
    /// - Parameters:
    ///   - "card_type": Type of card (e.g., "chart", "top_list")
    case cardAdded

    /// Card removed from dashboard
    /// - Parameters:
    ///   - "card_type": Type of card
    case cardRemoved

    /// Card moved to a new position
    /// - Parameters:
    ///   - "card_type": Type of card
    ///   - "action": Move action ("move_up", "move_down", "move_to_top", "move_to_bottom")
    ///   - "from_index": Original position index
    ///   - "to_index": New position index
    case cardMoved

    // MARK: - Chart Events

    /// Chart type changed
    /// - Parameters:
    ///   - "from_type": Previous chart type (e.g., "line", "bar")
    ///   - "to_type": New chart type
    case chartTypeChanged

    /// Chart granularity changed
    /// - Parameters:
    ///   - "from": Previous granularity (e.g., "day", "week", "automatic")
    ///   - "to": New granularity
    case chartGranularityChanged

    /// Chart metric selected
    /// - Parameters:
    ///   - "metric": The metric selected (e.g., "visitors", "views", "likes")
    case chartMetricSelected

    /// Chart bar selected for drill-down
    /// - Parameters:
    ///   - "from_granularity": The current granularity (e.g., "day", "month")
    ///   - "metric": The metric being viewed
    ///   - "value": The value of the selected bar
    case chartBarSelected

    /// Raw data view opened for a chart
    /// - Parameters:
    ///   - "card_type": Type of card showing the data
    ///   - "metric": The metric being viewed
    case rawDataViewed

    // MARK: - Today

    case todayCardTapped

    // MARK: - List Events

    /// Top list item tapped
    /// - Parameters:
    ///   - "item_type": Type of item (e.g., "posts_and_pages", "authors", "locations", "referrers")
    ///   - "metric": The metric being sorted by
    case topListItemTapped

    /// Location level changed in location drill-down
    /// - Parameters:
    ///   - "from_level": Previous level ("country", "region", or "city")
    ///   - "to_level": New level
    case locationLevelChanged

    /// Device breakdown changed in device drill-down
    /// - Parameters:
    ///   - "from_breakdown": Previous breakdown ("screensize", "platform", or "browser")
    ///   - "to_breakdown": New breakdown
    case deviceBreakdownChanged

    /// UTM parameter grouping changed
    /// - Parameters:
    ///   - "from_grouping": Previous grouping ("sourceMedium", "campaignSourceMedium", etc.)
    ///   - "to_grouping": New grouping
    case utmParamGroupingChanged

    // MARK: - Navigation Events

    /// Stats tab selected
    /// - Parameters:
    ///   - "tab_name": Name of the tab selected
    ///   - "previous_tab": Name of the previous tab
    case statsTabSelected

    // MARK: - Error Events

    /// Error encountered
    /// - Parameters:
    ///   - "error_type": Type of error (e.g., "network", "parsing", "permission")
    ///   - "error_code": Specific error code if available
    ///   - "screen": Where the error occurred
    case errorEncountered
}

// MARK: - StatsTracker Protocol

/// Protocol for tracking analytics events in the Stats module
public protocol StatsTracker: Sendable {
    /// Send an analytics event
    /// - Parameters:
    ///   - event: The event to track
    ///   - properties: Additional properties for the event
    func send(_ event: StatsEvent, properties: [String: String])
}

// MARK: - StatsTracker Convenience

extension StatsTracker {
    /// Convenience method to send events without properties
    func send(_ event: StatsEvent) {
        send(event, properties: [:])
    }
}

// MARK: - Private Extensions

extension DateIntervalPreset {
    /// Analytics tracking name for the preset
    var analyticsName: String {
        switch self {
        case .today: "today"
        case .thisWeek: "this_week"
        case .thisMonth: "this_month"
        case .thisQuarter: "this_quarter"
        case .thisYear: "this_year"
        case .last7Days: "last_7_days"
        case .last28Days: "last_28_days"
        case .last30Days: "last_30_days"
        case .last12Weeks: "last_12_weeks"
        case .last6Months: "last_6_months"
        case .last12Months: "last_12_months"
        case .last3Years: "last_3_years"
        case .last10Years: "last_10_years"
        }
    }
}

extension TopListItemType {
    /// Analytics tracking name for the item type
    var analyticsName: String {
        switch self {
        case .postsAndPages: "posts_and_pages"
        case .authors: "authors"
        case .referrers: "referrers"
        case .locations: "locations"
        case .devices: "devices"
        case .videos: "videos"
        case .externalLinks: "external_links"
        case .searchTerms: "search_terms"
        case .fileDownloads: "file_downloads"
        case .archive: "archive"
        case .utm: "utm"
        }
    }
}

extension SiteMetric {
    /// Analytics tracking name for the metric
    var analyticsName: String {
        switch self {
        case .views: "views"
        case .visitors: "visitors"
        case .likes: "likes"
        case .comments: "comments"
        case .posts: "posts"
        case .timeOnSite: "time_on_site"
        case .bounceRate: "bounce_rate"
        case .downloads: "downloads"
        }
    }
}

extension DateRangeGranularity {
    /// Analytics tracking name for the granularity
    var analyticsName: String {
        switch self {
        case .hour: "hour"
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        }
    }
}

extension DateRangeComparisonPeriod {
    /// Analytics tracking name for the comparison period
    var analyticsName: String {
        switch self {
        case .precedingPeriod: "previous_period"
        case .samePeriodLastYear: "previous_year"
        case .off: "off"
        }
    }
}

extension MoveDirection {
    /// Analytics tracking name for the move direction
    var analyticsName: String {
        switch self {
        case .up: "move_up"
        case .down: "move_down"
        case .top: "move_to_top"
        case .bottom: "move_to_bottom"
        }
    }
}
