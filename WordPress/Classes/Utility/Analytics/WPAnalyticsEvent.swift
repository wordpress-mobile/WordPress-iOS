import Foundation

// WPiOS-only events
@objc enum WPAnalyticsEvent: Int {

    case createSheetShown
    case createAnnouncementModalShown

    // Media Editor
    case mediaEditorShown
    case mediaEditorUsed
    case editorCreatedPage

    // Tenor
    case tenorAccessed
    case tenorSearched
    case tenorUploaded
    case mediaLibraryAddedPhotoViaTenor
    case editorAddedPhotoViaTenor

    // Settings and Prepublishing Nudges
    case editorPostPublishTap
    case editorPostScheduledChanged
    case editorPostVisibilityChanged
    case editorPostTagsChanged
    case editorPostPublishNowTapped
    case editorPostCategoryChanged
    case editorPostStatusChanged
    case editorPostFormatChanged
    case editorPostFeaturedImageChanged
    case editorPostStickyChanged
    case editorPostLocationChanged
    case editorPostSlugChanged
    case editorPostExcerptChanged
    case editorPostSiteChanged

    // App Settings
    case appSettingsAppearanceChanged

    // Gutenberg Features
    case gutenbergUnsupportedBlockWebViewShown
    case gutenbergUnsupportedBlockWebViewClosed
    case gutenbergSuggestionSessionFinished

    // Notifications Permissions
    case pushNotificationsPrimerSeen
    case pushNotificationsPrimerAllowTapped
    case pushNotificationsPrimerNoTapped
    case secondNotificationsAlertSeen
    case secondNotificationsAlertAllowTapped
    case secondNotificationsAlertNoTapped

    // Reader
    case selectInterestsShown
    case selectInterestsPicked
    case readerDiscoverShown
    case readerFollowingShown
    case readerSavedListShown
    case readerLikedShown
    case readerA8CShown
    case readerP2Shown
    case readerBlogPreviewed
    case readerDiscoverPaginated
    case readerPostCardTapped
    case readerPullToRefresh
    case readerDiscoverTopicTapped
    case postCardMoreTapped
    case followedBlogNotificationsReaderMenuOff
    case followedBlogNotificationsReaderMenuOn
    case readerArticleVisited
    case itemSharedReader
    case readerBlogBlocked
    case readerChipsMoreToggled
    case readerToggleFollowConversation
    case readerPostReported
    case readerArticleDetailMoreTapped
    case readerSharedItem
    case readerSuggestedSiteVisited
    case readerSuggestedSiteToggleFollow
    case readerDiscoverContentPresented
    case readerPostMarkSeen
    case readerPostMarkUnseen

    // What's New - Feature announcements
    case featureAnnouncementShown
    case featureAnnouncementButtonTapped
    // Stories
    case storyIntroShown
    case storyIntroDismissed
    case storyIntroCreateStoryButtonTapped

    // Jetpack
    case jetpackSettingsViewed
    case jetpackManageConnectionViewed
    case jetpackDisconnectTapped
    case jetpackDisconnectRequested
    case jetpackWhitelistedIpsViewed
    case jetpackWhitelistedIpsChanged
    case activitylogFilterbarSelectType
    case activitylogFilterbarResetType
    case activitylogFilterbarTypeButtonTapped
    case activitylogFilterbarRangeButtonTapped
    case activitylogFilterbarSelectRange
    case activitylogFilterbarResetRange
    case backupListOpened
    case backupFilterbarRangeButtonTapped
    case backupFilterbarSelectRange
    case backupFilterbarResetRange
    case restoreOpened
    case restoreConfirmed
    case restoreError
    case restoreNotifiyMeButtonTapped
    case backupDownloadOpened
    case backupDownloadConfirmed
    case backupFileDownloadError
    case backupNotifiyMeButtonTapped
    case backupFileDownloadTapped
    case backupDownloadShareLinkTapped

    // Jetpack Scan
    case jetpackScanAccessed
    case jetpackScanHistoryAccessed
    case jetpackScanHistoryFilter
    case jetpackScanThreatListItemTapped
    case jetpackScanRunTapped
    case jetpackScanIgnoreThreatDialogOpen
    case jetpackScanThreatIgnoreTapped
    case jetpackScanFixThreatDialogOpen
    case jetpackScanThreatFixTapped
    case jetpackScanAllThreatsOpen
    case jetpackScanAllthreatsFixTapped
    case jetpackScanError

    // Comments
    case commentViewed
    case commentApproved
    case commentUnApproved
    case commentLiked
    case commentUnliked
    case commentTrashed
    case commentSpammed
    case commentEditorOpened
    case commentEdited
    case commentRepliedTo

    /// A String that represents the event
    var value: String {
        switch self {
        case .createSheetShown:
            return "create_sheet_shown"
        case .createAnnouncementModalShown:
            return "create_announcement_modal_shown"
        // Media Editor
        case .mediaEditorShown:
            return "media_editor_shown"
        case .mediaEditorUsed:
            return "media_editor_used"
        case .editorCreatedPage:
            return "editor_page_created"
        // Tenor
        case .tenorAccessed:
            return "tenor_accessed"
        case .tenorSearched:
            return "tenor_searched"
        case .tenorUploaded:
            return "tenor_uploaded"
        case .mediaLibraryAddedPhotoViaTenor:
            return "media_library_photo_added"
        case .editorAddedPhotoViaTenor:
            return "editor_photo_added"
        // Editor    
        case .editorPostPublishTap:
            return "editor_post_publish_tapped"
        case .editorPostScheduledChanged:
            return "editor_post_scheduled_changed"
        case .editorPostVisibilityChanged:
            return "editor_post_visibility_changed"
        case .editorPostTagsChanged:
            return "editor_post_tags_changed"
        case .editorPostPublishNowTapped:
            return "editor_post_publish_now_tapped"
        case .editorPostCategoryChanged:
            return "editor_post_category_changed"
        case .editorPostStatusChanged:
            return "editor_post_status_changed"
        case .editorPostFormatChanged:
            return "editor_post_format_changed"
        case .editorPostFeaturedImageChanged:
            return "editor_post_featured_image_changed"
        case .editorPostStickyChanged:
            return "editor_post_sticky_changed"
        case .editorPostLocationChanged:
            return "editor_post_location_changed"
        case .editorPostSlugChanged:
            return "editor_post_slug_changed"
        case .editorPostExcerptChanged:
            return "editor_post_excerpt_changed"
        case .editorPostSiteChanged:
            return "editor_post_site_changed"
        case .appSettingsAppearanceChanged:
            return "app_settings_appearance_changed"
        case .gutenbergUnsupportedBlockWebViewShown:
            return "gutenberg_unsupported_block_webview_shown"
        case .gutenbergUnsupportedBlockWebViewClosed:
            return "gutenberg_unsupported_block_webview_closed"
        case .gutenbergSuggestionSessionFinished:
            return "suggestion_session_finished"
        // Notifications permissions
        case .pushNotificationsPrimerSeen:
            return "notifications_primer_seen"
        case .pushNotificationsPrimerAllowTapped:
            return "notifications_primer_allow_tapped"
        case .pushNotificationsPrimerNoTapped:
            return "notifications_primer_no_tapped"
        case .secondNotificationsAlertSeen:
            return "notifications_second_alert_seen"
        case .secondNotificationsAlertAllowTapped:
            return "notifications_second_alert_allow_tapped"
        case .secondNotificationsAlertNoTapped:
            return "notifications_second_alert_no_tapped"
        // Reader
        case .selectInterestsShown:
            return "select_interests_shown"
        case .selectInterestsPicked:
            return "select_interests_picked"
        case .readerDiscoverShown:
            return "reader_discover_shown"
        case .readerFollowingShown:
            return "reader_following_shown"
        case .readerLikedShown:
            return "reader_liked_shown"
        case .readerA8CShown:
            return "reader_a8c_shown"
        case .readerP2Shown:
            return "reader_p2_shown"
        case .readerSavedListShown:
            return "reader_saved_list_shown"
        case .readerBlogPreviewed:
            return "reader_blog_previewed"
        case .readerDiscoverPaginated:
            return "reader_discover_paginated"
        case .readerPostCardTapped:
            return "reader_post_card_tapped"
        case .readerPullToRefresh:
            return "reader_pull_to_refresh"
        case .readerDiscoverTopicTapped:
            return "reader_discover_topic_tapped"
        case .postCardMoreTapped:
            return "post_card_more_tapped"
        case .followedBlogNotificationsReaderMenuOff:
            return "followed_blog_notifications_reader_menu_off"
        case .followedBlogNotificationsReaderMenuOn:
            return "followed_blog_notifications_reader_menu_on"
        case .readerArticleVisited:
            return "reader_article_visited"
        case .itemSharedReader:
            return "item_shared_reader"
        case .readerBlogBlocked:
            return "reader_blog_blocked"
        case .readerChipsMoreToggled:
            return "reader_chips_more_toggled"
        case .readerToggleFollowConversation:
            return "reader_toggle_follow_conversation"
        case .readerPostReported:
            return "reader_post_reported"
        case .readerArticleDetailMoreTapped:
            return "reader_article_detail_more_tapped"
        case .readerSharedItem:
            return "reader_shared_item"
        case .readerSuggestedSiteVisited:
            return "reader_suggested_site_visited"
        case .readerSuggestedSiteToggleFollow:
            return "reader_suggested_site_toggle_follow"
        case .readerDiscoverContentPresented:
            return "reader_discover_content_presented"
        case .readerPostMarkSeen:
            return "reader_mark_as_seen"
        case .readerPostMarkUnseen:
            return "reader_mark_as_unseen"

        // What's New - Feature announcements
        case .featureAnnouncementShown:
            return "feature_announcement_shown"
        case .featureAnnouncementButtonTapped:
            return "feature_announcement_button_tapped"

        // Stories
        case .storyIntroShown:
            return "story_intro_shown"
        case .storyIntroDismissed:
            return "story_intro_dismissed"
        case .storyIntroCreateStoryButtonTapped:
            return "story_intro_create_story_button_tapped"

        // Jetpack
        case .jetpackSettingsViewed:
            return "jetpack_settings_viewed"
        case .jetpackManageConnectionViewed:
            return "jetpack_manage_connection_viewed"
        case .jetpackDisconnectTapped:
            return "jetpack_disconnect_tapped"
        case .jetpackDisconnectRequested:
            return "jetpack_disconnect_requested"
        case .jetpackWhitelistedIpsViewed:
            return "jetpack_whitelisted_ips_viewed"
        case .jetpackWhitelistedIpsChanged:
            return "jetpack_whitelisted_ips_changed"
        case .activitylogFilterbarSelectType:
            return "activitylog_filterbar_select_type"
        case .activitylogFilterbarResetType:
            return "activitylog_filterbar_reset_type"
        case .activitylogFilterbarTypeButtonTapped:
            return "activitylog_filterbar_type_button_tapped"
        case .activitylogFilterbarRangeButtonTapped:
            return "activitylog_filterbar_range_button_tapped"
        case .activitylogFilterbarSelectRange:
            return "activitylog_filterbar_select_range"
        case .activitylogFilterbarResetRange:
            return "activitylog_filterbar_reset_range"
        case .backupListOpened:
            return "jetpack_backup_list_opened"
        case .backupFilterbarRangeButtonTapped:
            return "jetpack_backup_filterbar_range_button_tapped"
        case .backupFilterbarSelectRange:
            return "jetpack_backup_filterbar_select_range"
        case .backupFilterbarResetRange:
            return "jetpack_backup_filterbar_reset_range"
        case .restoreOpened:
            return "jetpack_restore_opened"
        case .restoreConfirmed:
            return "jetpack_restore_confirmed"
        case .restoreError:
            return "jetpack_restore_error"
        case .restoreNotifiyMeButtonTapped:
            return "jetpack_restore_notify_me_button_tapped"
        case .backupDownloadOpened:
            return "jetpack_backup_download_opened"
        case .backupDownloadConfirmed:
            return "jetpack_backup_download_confirmed"
        case .backupFileDownloadError:
            return "jetpack_backup_file_download_error"
        case .backupNotifiyMeButtonTapped:
            return "jetpack_backup_notify_me_button_tapped"
        case .backupFileDownloadTapped:
            return "jetpack_backup_file_download_tapped"
        case .backupDownloadShareLinkTapped:
            return "jetpack_backup_download_share_link_tapped"

        // Jetpack Scan
        case .jetpackScanAccessed:
            return "jetpack_scan_accessed"
        case .jetpackScanHistoryAccessed:
            return "jetpack_scan_history_accessed"
        case .jetpackScanHistoryFilter:
            return "jetpack_scan_history_filter"
        case .jetpackScanThreatListItemTapped:
            return "jetpack_scan_threat_list_item_tapped"
        case .jetpackScanRunTapped:
            return "jetpack_scan_run_tapped"
        case .jetpackScanIgnoreThreatDialogOpen:
            return "jetpack_scan_ignorethreat_dialogopen"
        case .jetpackScanThreatIgnoreTapped:
            return "jetpack_scan_threat_ignore_tapped"
        case .jetpackScanFixThreatDialogOpen:
            return "jetpack_scan_fixthreat_dialogopen"
        case .jetpackScanThreatFixTapped:
            return "jetpack_scan_threat_fix_tapped"
        case .jetpackScanAllThreatsOpen:
            return "jetpack_scan_allthreats_open"
        case .jetpackScanAllthreatsFixTapped:
            return "jetpack_scan_allthreats_fix_tapped"
        case .jetpackScanError:
            return "jetpack_scan_error"

        // Comments
        case .commentViewed:
            return "comment_viewed"
        case .commentApproved:
            return "comment_approved"
        case .commentUnApproved:
            return "comment_unapproved"
        case .commentLiked:
            return "comment_liked"
        case .commentUnliked:
            return "comment_unliked"
        case .commentTrashed:
            return "comment_trashed"
        case .commentSpammed:
            return "comment_spammed"
        case .commentEditorOpened:
            return "comment_editor_opened"
        case .commentEdited:
            return "comment_edited"
        case .commentRepliedTo:
            return "comment_replied_to"
        }
    }

    /**
     The default properties of the event

     # Example
     ```
     case .mediaEditorShown:
        return ["from": "ios"]
     ```
    */
    var defaultProperties: [AnyHashable: Any]? {
        switch self {
        case .mediaLibraryAddedPhotoViaTenor:
            return ["via": "tenor"]
        case .editorAddedPhotoViaTenor:
            return ["via": "tenor"]
        default:
            return nil
        }
    }
}

extension WPAnalytics {

    @objc static var subscriptionCount: Int = 0

    private static let WPAppAnalyticsKeySubscriptionCount: String = "subscription_count"

    /// Track a event
    ///
    /// This will call each registered tracker and fire the given event.
    /// - Parameter event: a `String` that represents the event name
    /// - Note: If an event has its default properties, it will be passed through
    static func track(_ event: WPAnalyticsEvent) {
        WPAnalytics.trackString(event.value, withProperties: event.defaultProperties ?? [:])
    }

    /// Track a event
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    static func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        var mergedProperties: [AnyHashable: Any] = event.defaultProperties ?? [:]
        mergedProperties.merge(properties) { (_, new) in new }

        WPAnalytics.trackString(event.value, withProperties: mergedProperties)
    }

    /// This will call each registered tracker and fire the given event.
    /// - Parameters:
    ///   - event: a `String` that represents the event name
    ///   - properties: a `Hash` that represents the properties
    ///   - blog: a `Blog` asssociated with the event
    static func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any], blog: Blog) {
        var props = properties
        props[WPAppAnalyticsKeyBlogID] = blog.dotComID
        props[WPAppAnalyticsKeySiteType] = blog.isWPForTeams() ? WPAppAnalyticsValueSiteTypeP2 : WPAppAnalyticsValueSiteTypeBlog
        WPAnalytics.track(event, properties: props)
    }

    /// Track a Reader event
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the Reader event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    static func trackReader(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any] = [:]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(event, properties: props)
    }

    /// Track a Reader stat
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the Reader event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    static func trackReader(_ stat: WPAnalyticsStat, properties: [AnyHashable: Any] = [:]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(stat, withProperties: props)
    }

    /// Track a event in Obj-C
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the event name
    ///
    @objc static func trackEvent(_ event: WPAnalyticsEvent) {
        WPAnalytics.trackString(event.value)
    }

    /// Track a event in Obj-C
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    @objc static func trackEvent(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        var mergedProperties: [AnyHashable: Any] = event.defaultProperties ?? [:]
        mergedProperties.merge(properties) { (_, new) in new }


        WPAnalytics.trackString(event.value, withProperties: mergedProperties)
    }

    /// Track a Reader event in Obj-C
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the Reader event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    @objc static func trackReaderEvent(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(event, properties: props)
    }

    /// Track a Reader stat in Obj-C
    ///
    /// This will call each registered tracker and fire the given stat
    /// - Parameter stat: a `String` that represents the Reader stat name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    @objc static func trackReaderStat(_ stat: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(stat, withProperties: props)
    }

}
