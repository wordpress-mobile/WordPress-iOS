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

    // MARK: - Date Range Events

    /// Date range preset selected
    /// - Parameters:
    ///   - "selected_preset": The preset selected (e.g., "last_7_days", "last_28_days", "last_90_days", "last_365_days")
    case dateRangePresetSelected

    /// Custom date range selected
    /// - Parameters:
    ///   - "start_date": Start date in ISO format
    ///   - "end_date": End date in ISO format
    case customDateRangeSelected

    // MARK: - Card Events

    /// Card added to dashboard
    /// - Parameters:
    ///   - "card_type": Type of card (e.g., "chart", "top_list", "realtime_metrics")
    ///   - "configuration": Card configuration details
    case cardAdded

    /// Card removed from dashboard
    /// - Parameters:
    ///   - "card_type": Type of card
    case cardRemoved

    /// Card customization initiated
    /// - Parameters:
    ///   - "card_type": Type of card
    case cardCustomizationOpened

    /// Card configuration saved
    /// - Parameters:
    ///   - "card_type": Type of card
    ///   - "changes": Summary of changes made
    case cardConfigurationSaved

    /// Card shown on screen
    /// - Parameters:
    ///   - "card_type": Type of card (e.g., "chart", "top_list")
    ///   - "configuration": Card configuration details (e.g., metrics, item type)
    case cardShown

    /// Card edit menu opened
    /// - Parameters:
    ///   - "card_type": Type of card
    case cardEditMenuOpened

    // MARK: - Chart Events

    /// Chart type changed
    /// - Parameters:
    ///   - "from_type": Previous chart type (e.g., "line", "bar")
    ///   - "to_type": New chart type
    case chartTypeChanged

    /// Chart metric selected
    /// - Parameters:
    ///   - "metric": The metric selected (e.g., "visitors", "views", "likes")
    case chartMetricSelected

    /// Chart data point selected
    /// - Parameters:
    ///   - "metric": The metric being viewed
    ///   - "date": The date of the data point
    ///   - "value": The value at that point
    case chartDataPointSelected

    // MARK: - List Events

    /// Top list item tapped
    /// - Parameters:
    ///   - "item_type": Type of item (e.g., "posts_and_pages", "authors", "locations", "referrers")
    ///   - "metric": The metric being sorted by
    case topListItemTapped

    /// Top list filter applied
    /// - Parameters:
    ///   - "filter_type": Type of filter applied
    ///   - "filter_value": Value of the filter
    ///   - "list_type": Type of list being filtered
    case topListFilterApplied

    /// Top list sorted
    /// - Parameters:
    ///   - "sort_by": Metric used for sorting
    ///   - "list_type": Type of list being sorted
    case topListSorted

    // MARK: - Export Events

    /// Export completed
    /// - Parameters:
    ///   - "export_type": Type of export
    ///   - "data_type": What was exported
    ///   - "row_count": Number of rows exported
    case exportCompleted

    /// Export failed
    /// - Parameters:
    ///   - "export_type": Type of export
    ///   - "error_type": Type of error encountered
    case exportFailed

    // MARK: - Map Events

    /// Map interaction
    /// - Parameters:
    ///   - "interaction_type": Type of interaction (e.g., "tap", "zoom", "pan")
    ///   - "country_code": Country code if a country was selected
    case mapInteraction

    // MARK: - Navigation Events

    /// Stats tab selected
    /// - Parameters:
    ///   - "tab_name": Name of the tab selected
    ///   - "previous_tab": Name of the previous tab
    case statsTabSelected

    /// Back navigation
    /// - Parameters:
    ///   - "from_screen": Screen navigating from
    ///   - "to_screen": Screen navigating to
    case backNavigationTapped

    // MARK: - Action Events

    /// Refresh initiated
    case refreshInitiated

    /// Share action
    /// - Parameters:
    ///   - "content_type": What's being shared (e.g., "chart", "stats_summary")
    ///   - "share_method": How it's being shared (e.g., "copy", "email", "social")
    case shareActionPerformed

    /// Help accessed
    /// - Parameters:
    ///   - "help_topic": Topic of help accessed
    ///   - "source_screen": Where help was accessed from
    case helpAccessed

    // MARK: - Error Events

    /// Error encountered
    /// - Parameters:
    ///   - "error_type": Type of error (e.g., "network", "parsing", "permission")
    ///   - "error_code": Specific error code if available
    ///   - "screen": Where the error occurred
    case errorEncountered

    /// Error retry attempted
    /// - Parameters:
    ///   - "error_type": Type of error being retried
    ///   - "retry_count": Number of retry attempts
    case errorRetryAttempted
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
        case .last90Days: "last_90_days"
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
        case .videos: "videos"
        case .externalLinks: "external_links"
        case .searchTerms: "search_terms"
        case .fileDownloads: "file_downloads"
        case .archive: "archive"
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
