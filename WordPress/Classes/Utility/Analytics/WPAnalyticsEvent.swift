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

}
