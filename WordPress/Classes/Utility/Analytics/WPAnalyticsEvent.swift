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
