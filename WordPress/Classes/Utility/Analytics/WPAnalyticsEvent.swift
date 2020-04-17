import Foundation

// WPiOS-only events
@objc enum WPAnalyticsEvent: Int {
    // Media Editor
    case mediaEditorShown
    case mediaEditorUsed
    case editorCreatedPage
    case createSheetShown
    // Tenor
    case tenorAccessed
    case tenorSearched
    case tenorUploaded
    case mediaLibraryAddedPhotoViaTenor
    case editorAddedPhotoViaTenor

    /// A String that represents the event
    var value: String {
        switch self {
        // Media Editor
        case .mediaEditorShown:
            return "media_editor_shown"
        case .mediaEditorUsed:
            return "media_editor_used"
        case .editorCreatedPage:
            return "editor_page_created"
        case .createSheetShown:
            return "create_sheet_shown"
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
