import Foundation
import WordPressShared

/// Utility extension to track specific data for passing to on to WPAppAnalytics.
extension WPAppAnalytics {
    private enum Constants {
        static let sessionCountKey = "session_count"
        static let lastVisibleScreenKey = "last_visible_screen"
        static let timeInAppKey = "time_in_app"
    }

    func trackApplicationDidBecomeActive() {
        incrementSessionCount()
        trackApplicationOpened()
        WidgetAnalytics.trackLoadedWidgetsOnApplicationOpened()
    }

    func trackApplicationDidEnterBackground(screenName: String) {
        trackApplicationClosed(screenName: screenName)
    }

    private func trackApplicationOpened() {
        // UIApplicationDidBecomeActiveNotification will be dispatched if the user
        // returns from a system overlay (like notification center) or when multi
        // tasking on the iPad and adjusting the split screen divider. This happens
        // without previously dispatching UIApplicationDidEnterBackgroundNotification.
        // We don't want to track application opened in thise cases so check for a
        // nil applicationOpenedTime first.
        guard applicationOpenedTime == nil else {
            return
        }
        self.applicationOpenedTime = Date()

        // This stat is part of a funnel that provides critical information.  Before
        // making ANY modification to this stat please refer to: p4qSXL-35X-p2
        WPAnalytics.track(.applicationOpened)
    }

    private func trackApplicationClosed(screenName: String) {
        var properties: [String: Any] = [:]
        properties[Constants.lastVisibleScreenKey] = screenName

        if let applicationOpenedTime {
            let applicationClosedTime = Date()
            let timeInApp = applicationClosedTime.timeIntervalSince(applicationOpenedTime).rounded()
            properties[Constants.timeInAppKey] = NSNumber(value: timeInApp)
            self.applicationOpenedTime = nil
        }

        WPAnalytics.track(.applicationClosed, withProperties: properties)
        WPAnalytics.endSession()
    }

    // MARK: Session

    public static var sessionCount: Int {
        UserDefaults.standard.integer(forKey: Constants.sessionCountKey)
    }

    private func incrementSessionCount() {
        var sessionCount = WPAppAnalytics.sessionCount
        sessionCount += 1
        if sessionCount == 1 {
            WPAnalytics.track(.appInstalled)
        }
        UserDefaults.standard.set(sessionCount, forKey: Constants.sessionCountKey)
    }

    // MARK: Misc

    /// Get a dictionary of tracking properties for a Media object with the media selection method.
    ///
    /// - Parameters:
    ///     - media: The Media object.
    ///     - selectionMethod: The Media's method of selection.
    /// - Returns: Dictionary
    ///
    class func properties(for media: Media, selectionMethod: MediaSelectionMethod) -> [String: Any] {
        var properties = WPAppAnalytics.properties(for: media)
        properties[MediaOriginKey] = String(describing: selectionMethod)
        return properties
    }

    /**
     Get a dictionary of tracking properties for a Media object.
     - parameter media: the Media object
     - returns: Dictionary
     */
    @objc class func properties(for media: Media) -> Dictionary<String, Any> {
        var properties = [String: Any]()
        properties[MediaProperties.mime] = media.mimeType
        if let fileExtension = media.fileExtension(), !fileExtension.isEmpty {
            properties[MediaProperties.fileExtension] = fileExtension
        }
        if media.mediaType == .image {
            if let width = media.width, let height = media.height {
                let megaPixels = round((width.floatValue * height.floatValue) / 1000000)
                properties[MediaProperties.megapixels] = Int(megaPixels)
            }
        } else if media.mediaType == .video {
            properties[MediaProperties.durationSeconds] = media.length
        }
        if let filesize = media.filesize {
            properties[MediaProperties.bytes] = filesize.int64Value * 1024
        }
        return properties
    }

    fileprivate struct MediaProperties {
        static let mime = "mime"
        static let fileExtension = "ext"
        static let megapixels = "megapixels"
        static let durationSeconds = "duration_secs"
        static let bytes = "bytes"
    }

    fileprivate static let MediaOriginKey = "media_origin"
}

public struct MediaAnalyticsInfo {
    let origin: MediaUploadOrigin
    let selectionMethod: MediaSelectionMethod?

    init(origin: MediaUploadOrigin, selectionMethod: MediaSelectionMethod? = nil) {
        self.origin = origin
        self.selectionMethod = selectionMethod
    }

    func eventForMediaType(_ mediaType: MediaType) -> WPAnalyticsEvent? {
        return origin.eventForMediaType(mediaType)
    }

    // Old tracking events via WPShared
    func wpsharedEventForMediaType(_ mediaType: MediaType) -> WPAnalyticsStat? {
        return origin.wpsharedEventForMediaType(mediaType)
    }

    var retryEvent: WPAnalyticsStat? {
        switch origin {
        case .mediaLibrary:
            return .mediaLibraryUploadMediaRetried
        case .editor:
            return .editorUploadMediaRetried
        }
    }

    var pausedEvent: WPAnalyticsStat = .editorUploadMediaPaused

    func properties(for media: Media) -> [String: Any] {
        guard let selectionMethod else {
            return WPAppAnalytics.properties(for: media)
        }

        return WPAppAnalytics.properties(for: media, selectionMethod: selectionMethod)
    }
}

/// Used for analytics to identify how the media was selected by the user.
///
public enum MediaSelectionMethod: CustomStringConvertible {
    case inlinePicker
    case fullScreenPicker
    case documentPicker
    case mediaUploadWritePost
    case none

    public var description: String {
        switch self {
        case .inlinePicker: return "inline_picker"
        case .fullScreenPicker: return "full_screen_picker"
        case .documentPicker: return "document_picker"
        case .mediaUploadWritePost: return "media_write_post"
        case .none: return "not_identified"
        }
    }
}

/// Used for analytics to track where an upload was started within the app.
///
enum MediaUploadOrigin {
    case mediaLibrary(MediaSource)
    case editor(MediaSource)

    // All new media tracking events will be added into WPAnalyticsEvent
    func eventForMediaType(_ mediaType: MediaType) -> WPAnalyticsEvent? {
        switch (self, mediaType) {
        // Media Library
        case (.mediaLibrary(let source), .image) where source == .tenor:
            return .mediaLibraryAddedPhotoViaTenor

        // Editor
        case (.editor(let source), .image) where source == .tenor:
            return .editorAddedPhotoViaTenor

        default:
            return nil
        }
    }

    // This is for the previous events created within WordPressShared
    func wpsharedEventForMediaType(_ mediaType: MediaType) -> WPAnalyticsStat? {
        switch (self, mediaType) {
        // Media Library
        case (.mediaLibrary(let source), .image) where source == .deviceLibrary:
            return .mediaLibraryAddedPhotoViaDeviceLibrary
        case (.mediaLibrary(let source), .image) where source == .otherApps:
            return .mediaLibraryAddedPhotoViaOtherApps
        case (.mediaLibrary(let source), .image) where source == .stockPhotos:
            return .mediaLibraryAddedPhotoViaStockPhotos
        case (.mediaLibrary(let source), .image) where source == .camera:
            return .mediaLibraryAddedPhotoViaCamera
        case (.mediaLibrary(let source), .video) where source == .deviceLibrary:
            return .mediaLibraryAddedVideoViaDeviceLibrary
        case (.mediaLibrary(let source), .video) where source == .otherApps:
            return .mediaLibraryAddedVideoViaOtherApps
        case (.mediaLibrary(let source), .video) where source == .camera:
            return .mediaLibraryAddedVideoViaCamera
        // Editor
        case (.editor(let source), .image) where source == .deviceLibrary:
            return .editorAddedPhotoViaLocalLibrary
        case (.editor(let source), .image) where source == .wpMediaLibrary:
            return .editorAddedPhotoViaWPMediaLibrary
        case (.editor(let source), .image) where source == .otherApps:
            return .editorAddedPhotoViaOtherApps
        case (.editor(let source), .image) where source == .stockPhotos:
            return .editorAddedPhotoViaStockPhotos
        case (.editor(let source), .image) where source == .mediaEditor:
            return .editorAddedPhotoViaMediaEditor
        case (.editor(let source), .video) where source == .deviceLibrary:
            return .editorAddedVideoViaLocalLibrary
        case (.editor(let source), .video) where source == .wpMediaLibrary:
            return .editorAddedVideoViaWPMediaLibrary
        case (.editor(let source), .video) where source == .otherApps:
            return .editorAddedVideoViaOtherApps
        default: return nil
        }
    }
}

/// Used for analytics to track the source of a media item
///
enum MediaSource {
    case none
    case deviceLibrary
    case otherApps
    case wpMediaLibrary
    case stockPhotos
    case camera
    case mediaEditor
    case tenor
    case imagePlayground
}
