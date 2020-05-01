import Foundation

// WPiOS-only events
@objc enum WPAnalyticsEvent: Int {
    case mediaEditorShown
    case mediaEditorUsed
    case editorCreatedPage
    case createSheetShown
    case announcementModalShown

    // Settings and Prepublishing Nudges
    case editorPostPublishTap
    case editorPostScheduled
    case editorPostVisibilityChanged
    case editorPostTagsAdded
    case editorPostPublishNowTapped
    case editorPostCategoryChanged
    case editorPostStatusChanged
    case editorPostFormatChanged
    case editorPostFeaturedImageChanged
    case editorPostStickyChanged
    case editorPostLocationChanged
    case editorPostSlugChanged
    case editorPostExcerptChanged

    /// A String that represents the event
    var value: String {
        switch self {
        case .mediaEditorShown:
            return "media_editor_shown"
        case .mediaEditorUsed:
            return "media_editor_used"
        case .editorCreatedPage:
            return "editor_page_created"
        case .createSheetShown:
            return "create_sheet_shown"
        case .announcementModalShown:
            return "announcement_modal_shown"
        case .editorPostPublishTap:
            return "editor_post_publish_tapped"
        case .editorPostScheduled:
            return "editor_post_scheduled"
        case .editorPostVisibilityChanged:
            return "editor_post_visibility_changed"
        case .editorPostTagsAdded:
            return "editor_post_tags_added"
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
        default:
            return nil
        }
    }
}

extension WPAnalytics {

    /// Track a event
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the event name
    ///
    static func track(_ event: WPAnalyticsEvent) {
        WPAnalytics.trackString(event.value)
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
